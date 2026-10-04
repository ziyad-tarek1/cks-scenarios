#!/usr/bin/env bash
# Shared helpers for the CKS practice lab.

CLUSTER="${CKS_CLUSTER:-cks}"
KCTX="kind-${CLUSTER}"
NODE="${CLUSTER}-control-plane"
WORKER="${CLUSTER}-worker"
LAB="${CKS_LAB_DIR:-$HOME/cks-lab}"
NODE_IMAGE="${CKS_NODE_IMAGE:-}"          # empty => kind's default
LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ---------- output ----------
if [ -t 1 ]; then
  C_R=$'\033[31m'; C_G=$'\033[32m'; C_Y=$'\033[33m'; C_B=$'\033[34m'
  C_D=$'\033[2m';  C_BD=$'\033[1m'; C_0=$'\033[0m'
else
  C_R=; C_G=; C_Y=; C_B=; C_D=; C_BD=; C_0=
fi
info()  { printf '%s\n' "${C_B}==>${C_0} $*"; }
step()  { printf '%s\n' "${C_D}  -${C_0} $*"; }
warn()  { printf '%s\n' "${C_Y}  ! ${C_0} $*" >&2; }
die()   { printf '%s\n' "${C_R}ERROR:${C_0} $*" >&2; exit 1; }
hdr()   { printf '\n%s\n' "${C_BD}$*${C_0}"; }

# ---------- kubectl, pinned to the lab context ----------
# Never touches any other cluster the user has configured.
k() { kubectl --context "$KCTX" "$@"; }
kq() { kubectl --context "$KCTX" "$@" >/dev/null 2>&1; }

node_exec() { docker exec "$NODE" "$@"; }
node_sh()   { docker exec "$NODE" bash -c "$1"; }
node_read() { docker exec "$NODE" cat "$1" 2>/dev/null; }
# Atomic write: a static-pod manifest MUST never be observed half-written.
# `cat > file` truncates in place, and if the kubelet reads it in that window it
# treats the manifest as empty and DELETES the static pod -- which takes the API
# server down with no easy way back. Write to a temp file, then rename.
node_write(){
  local dst="$1" tmp="$1.cks-tmp"
  docker exec -i "$NODE" sh -c "cat > '$tmp' && chmod 600 '$tmp' && mv -f '$tmp' '$dst'"
}

APISERVER_MANIFEST=/etc/kubernetes/manifests/kube-apiserver.yaml
ETCD_MANIFEST=/etc/kubernetes/manifests/etcd.yaml
KUBELET_CONFIG=/var/lib/kubelet/config.yaml

# ---------- environment guards ----------
need_bin() { command -v "$1" >/dev/null 2>&1 || die "'$1' not found. $2"; }

require_docker() {
  docker info >/dev/null 2>&1 || die "Docker is not running. Start Docker Desktop and retry."
}

require_cluster() {
  kind get clusters 2>/dev/null | grep -qx "$CLUSTER" \
    || die "Lab cluster '$CLUSTER' not found. Run: ./cks setup"
  # /healthz with retries, NOT `cluster-info`: the API server is routinely mid-restart
  # after a manifest edit, and once q02 is solved its pod sits at 0/1 forever by
  # design (anonymous probes get 401), which must not read as "cluster down".
  wait_apiserver 12 || die "Cluster '$CLUSTER' is not responding. Try: ./cks doctor"
}

# Wait until the API server answers /healthz. Returns 1 on timeout.
wait_apiserver() {
  local tries="${1:-60}" i
  for ((i=0;i<tries;i++)); do
    k get --raw /healthz >/dev/null 2>&1 && return 0
    sleep 5
  done
  return 1
}

apiserver_container_id() {
  node_sh 'crictl ps --name kube-apiserver -q 2>/dev/null | head -1' 2>/dev/null | tr -d '\r\n'
}

# Wait for the kubelet to actually REPLACE the kube-apiserver container after a
# manifest edit, then for the API to come back.
#
# Checking /healthz alone is not enough: the old container keeps serving happily,
# so a healthy endpoint can still mean the edit has not been applied. (The kubelet
# also ignores mtime-only changes -- the file content must differ.)
settle_apiserver() {
  local tries="${1:-60}" before="${2:-}" i now
  [ -n "$before" ] || before="$SETTLE_BEFORE_ID"
  step "waiting for kube-apiserver to be replaced ..."
  for ((i=0;i<tries;i++)); do
    now=$(apiserver_container_id)
    if [ -n "$now" ] && [ "$now" != "$before" ]; then
      if wait_apiserver "$tries"; then step "API server restarted and healthy"; return 0; fi
      warn "new kube-apiserver container did not become healthy"
      return 1
    fi
    sleep 2
  done
  # No replacement seen. Either nothing changed, or the kubelet has not noticed.
  if wait_apiserver 5; then
    warn "kube-apiserver was NOT restarted (container unchanged) -- the manifest edit may not have been picked up yet"
    return 0
  fi
  warn "API server did not come back. Diagnose with:  ./cks doctor"
  return 1
}

# Record the current container id before editing the manifest.
SETTLE_BEFORE_ID=""
mark_apiserver() { SETTLE_BEFORE_ID=$(apiserver_container_id); }

backup_controlplane() {
  node_sh 'mkdir -p /backup && for f in /etc/kubernetes/manifests/*.yaml; do
             [ -f "/backup/$(basename "$f")" ] || cp "$f" /backup/; done
           [ -f /backup/kubelet-config.yaml ] || cp /var/lib/kubelet/config.yaml /backup/kubelet-config.yaml' \
    >/dev/null 2>&1
}

restore_controlplane() {
  step "restoring control-plane manifests + kubelet config from /backup"
  mark_apiserver
  node_sh 'cp /backup/etcd.yaml /backup/kube-apiserver.yaml /backup/kube-controller-manager.yaml \
              /backup/kube-scheduler.yaml /etc/kubernetes/manifests/ 2>/dev/null
           cp /backup/kubelet-config.yaml /var/lib/kubelet/config.yaml 2>/dev/null
           systemctl restart kubelet' >/dev/null 2>&1
  settle_apiserver 40 || true
  # If the running container still predates the restore, the kubelet is not
  # resyncing static pods (it happens when a previous edit locked it out of the
  # API). Deleting the container forces the kubelet to recreate it from the
  # on-disk manifest, which needs no API access.
  if wait_apiserver 5; then return 0; fi
  # A kubelet that rejected a bad manifest keeps a stale pod worker and will not
  # recreate the container even once the file is valid again. Restarting the
  # kubelet makes it re-read the static pod directory from scratch, which is the
  # one step that reliably brings the API server back.
  warn "API server still down; restarting the kubelet to force a static-pod resync"
  node_sh 'crictl rm -f $(crictl ps -a --name kube-apiserver -q | head -1) >/dev/null 2>&1; systemctl restart kubelet' >/dev/null 2>&1
  if wait_apiserver 60; then
    step "API server recovered"
  else
    warn "still down. Last resort:  ./cks clean && ./cks setup"
  fi
}

# kube-controller-manager can wedge on a stale leader-election lease after
# repeated API server restarts. Harmless lab artifact; clear it.
unwedge_controlplane() {
  local st
  st=$(k -n kube-system get po -l component=kube-controller-manager \
         -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null || true)
  if [ "$st" != "true" ]; then
    step "clearing stale kube-controller-manager lease"
    kq -n kube-system delete lease kube-controller-manager || true
    sleep 5
  fi
}

# ---------- grading ----------
PASS=0; FAIL=0; FAILED_MSGS=()
start_checks() { PASS=0; FAIL=0; FAILED_MSGS=(); }
ok() { PASS=$((PASS+1)); printf '  %s %s\n' "${C_G}PASS${C_0}" "$1"; }
no() {
  FAIL=$((FAIL+1)); printf '  %s %s\n' "${C_R}FAIL${C_0}" "$1"
  [ -n "${2:-}" ] && printf '       %s\n' "${C_D}hint: $2${C_0}"
  FAILED_MSGS+=("$1")
  return 0
}
# check "description" <command...>   -- command's exit status decides
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$d"; else no "$d"; fi; }
# checkh "description" "hint" <command...>
checkh() { local d="$1" h="$2"; shift 2; if "$@" >/dev/null 2>&1; then ok "$d"; else no "$d" "$h"; fi; }

report() {
  local total=$((PASS+FAIL))
  printf '\n'
  if [ "$FAIL" -eq 0 ] && [ "$total" -gt 0 ]; then
    printf '%s\n' "${C_G}${C_BD}  RESULT: PASS  (${PASS}/${total})${C_0}"
    return 0
  fi
  printf '%s\n' "${C_R}${C_BD}  RESULT: FAIL  (${PASS}/${total} criteria met)${C_0}"
  printf '%s\n' "${C_D}  Re-run a single question:  ./cks verify ${CURRENT_Q:-NN}${C_0}"
  return 1
}

# ---------- small assertion helpers used by question scripts ----------
# apiserver flag value, e.g. apiserver_flag --authorization-mode
apiserver_flag() {
  node_read "$APISERVER_MANIFEST" | sed -n "s|^[[:space:]]*-[[:space:]]*$1=\(.*\)$|\1|p" | head -1
}
apiserver_has_flag() { node_read "$APISERVER_MANIFEST" | grep -qE "^[[:space:]]*-[[:space:]]*$1(=|$)"; }
etcd_flag() {
  node_read "$ETCD_MANIFEST" | sed -n "s|^[[:space:]]*-[[:space:]]*$1=\(.*\)$|\1|p" | head -1
}
# does the apiserver pod mount this container path?
apiserver_mounts() { node_read "$APISERVER_MANIFEST" | grep -q "mountPath: $1"; }

csv_has() { printf '%s' "$1" | tr ',' '\n' | grep -qx "$2"; }

labdir() { mkdir -p "$LAB/$1"; printf '%s' "$LAB/$1"; }

# Wait for a deployment to have N ready replicas (default 1).
wait_ready() { k -n "$1" rollout status "deploy/$2" --timeout="${3:-180s}" >/dev/null 2>&1; }

# HTTP status from inside a pod. Prints a code, or 000 on failure/timeout.
curl_from() { # ns pod url [container]
  local ns="$1" po="$2" url="$3" c="${4:-}" out
  if [ -n "$c" ]; then
    out=$(k -n "$ns" exec "$po" -c "$c" -- curl -s -o /dev/null -m 6 -w '%{http_code}' "$url" 2>/dev/null)
  else
    out=$(k -n "$ns" exec "$po" -- curl -s -o /dev/null -m 6 -w '%{http_code}' "$url" 2>/dev/null)
  fi
  printf '%s' "${out:-000}"
}

# Newest Running pod for a selector, after letting any rollout finish.
# Avoids exec'ing into a pod from the previous ReplicaSet.
ready_pod() { # ns selector [deployment] [timeout]
  local ns="$1" sel="$2" dep="${3:-}" to="${4:-180s}" i gen obs
  if [ -n "$dep" ]; then
    # Wait for the controller to OBSERVE the edit before trusting rollout status --
    # otherwise it reports the previous, already-complete rollout and we would
    # exec into a pod from the old ReplicaSet.
    for i in $(seq 1 40); do
      gen=$(k -n "$ns" get deploy "$dep" -o jsonpath='{.metadata.generation}' 2>/dev/null)
      obs=$(k -n "$ns" get deploy "$dep" -o jsonpath='{.status.observedGeneration}' 2>/dev/null)
      [ -n "$gen" ] && [ -n "$obs" ] && [ "$obs" -ge "$gen" ] 2>/dev/null && break
      sleep 1
    done
    k -n "$ns" rollout status "deploy/$dep" --timeout="$to" >/dev/null 2>&1
    # and make sure only the current generation's pods remain
    for i in $(seq 1 20); do
      [ "$(k -n "$ns" get po -l "$sel" --no-headers 2>/dev/null | wc -l | tr -d ' ')" = \
        "$(k -n "$ns" get deploy "$dep" -o jsonpath='{.status.replicas}' 2>/dev/null)" ] && break
      sleep 2
    done
  fi
  k -n "$ns" get po -l "$sel" --field-selector=status.phase=Running \
    --sort-by=.metadata.creationTimestamp -o name 2>/dev/null | tail -1
}

# --- kubelet config editing (block-aware; the node has no python3) ---------
# Sets authentication.<block>.enabled to a value, e.g. kubelet_set_authn anonymous false
kubelet_set_authn() { # block value
  node_sh "awk -v blk='  $1:' -v val='$2' '
    /^authentication:/ {ina=1}
    /^authorization:/  {ina=0}
    ina && \$0==blk     {inb=1; print; next}
    inb && /^    enabled:/ {print \"    enabled: \" val; inb=0; next}
    inb && /^  [a-zA-Z]/ {inb=0}
    {print}
  ' $KUBELET_CONFIG > /tmp/kc && mv /tmp/kc $KUBELET_CONFIG" >/dev/null 2>&1
}
kubelet_set_authz_mode() { # mode
  node_sh "awk -v m='$1' '
    /^authorization:/ {inz=1; print; next}
    inz && /^  mode:/ {print \"  mode: \" m; inz=0; next}
    inz && /^[a-zA-Z]/ {inz=0}
    {print}
  ' $KUBELET_CONFIG > /tmp/kc && mv /tmp/kc $KUBELET_CONFIG" >/dev/null 2>&1
}
kubelet_restart() { node_sh 'systemctl restart kubelet' >/dev/null 2>&1; sleep 5; }

# --- surgical kube-apiserver manifest editing --------------------------------
# The node image has no python3, so copy the manifest here, edit, copy back.
# Keeps one question's reset from clobbering another's work.
apiserver_edit() { # op [args...]   -- single op, one read + one write
  apiserver_edit_multi "$*"
}

# Apply SEVERAL ops in ONE read/write cycle. Each argument is one op line,
# e.g. apiserver_edit_multi "rmflag --audit-log-path" "rmvol audit-log".
# Batching matters: every write to the manifest restarts the API server, so
# doing five writes in a row restarts it five times and widens the window for
# the kubelet to catch a bad intermediate state.
apiserver_edit_multi() {
  local tmp rc
  tmp=$(mktemp -t cksapi) || return 1
  node_read "$APISERVER_MANIFEST" > "$tmp" || { rm -f "$tmp"; return 1; }
  if [ ! -s "$tmp" ]; then
    rm -f "$tmp"; warn "could not read $APISERVER_MANIFEST"; return 1
  fi
  python3 "$LAB_ROOT/lib/apiserver_edit.py" "$tmp" multi "$@"; rc=$?
  # Never push back something that lost the container spec.
  if [ "$rc" -eq 0 ] && grep -q 'kube-apiserver' "$tmp" && grep -q 'volumes:' "$tmp"; then
    node_write "$APISERVER_MANIFEST" < "$tmp"
  else
    warn "refusing to write a manifest that failed a sanity check"
    rc=1
  fi
  rm -f "$tmp"
  return $rc
}
