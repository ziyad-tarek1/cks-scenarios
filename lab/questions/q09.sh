Q_TITLE="Enable audit logging with a 4-rule audit policy"
Q_TAGS="cluster"
Q9_POLICY=/etc/kubernetes/audit/audit.yaml
Q9_LOG=/var/log/kubernetes/audit.log
Q9_MAXAGE=5; Q9_MAXBACKUP=10; Q9_MAXSIZE=100

q_setup() {
  local d; d=$(labdir q09)
  backup_controlplane
  step "removing any existing audit configuration"
  mark_apiserver
  apiserver_edit_multi \
    "rmflag --audit-policy-file --audit-log-path --audit-log-maxage --audit-log-maxbackup --audit-log-maxsize" \
    "rmvol audit-policy audit-log"
  node_sh "rm -f /etc/kubernetes/audit/audit.yaml /var/log/kubernetes/audit.log*" >/dev/null 2>&1
  settle_apiserver 60 || true

  cat > "$d/TASK.md" <<EOF
Enable API server audit logging.

    ssh $NODE            # like the exam  (./cks ssh  also works)

1. Create the audit policy at $Q9_POLICY with FOUR rules:
     a) delete on configmaps AND secrets, in all namespaces -> RequestResponse
     b) deployments (apps group) in namespace web-apps      -> Metadata
     c) the 'namespaces' resource                           -> Request
     d) everything else                                     -> Metadata
   Order matters: rules are first-match-wins, so the catch-all goes LAST.

2. Configure kube-apiserver ($APISERVER_MANIFEST):
     --audit-policy-file=$Q9_POLICY
     --audit-log-path=$Q9_LOG
     --audit-log-maxage=$Q9_MAXAGE
     --audit-log-maxbackup=$Q9_MAXBACKUP
     --audit-log-maxsize=$Q9_MAXSIZE

3. THE FLAGS ALONE ARE NOT ENOUGH.
   kube-apiserver is a static pod and kubeadm mounts only /etc/kubernetes/pki.
   You must add hostPath volumes + volumeMounts for BOTH
   /etc/kubernetes/audit (readOnly) and /var/log/kubernetes (writable),
   and mkdir both directories first -- or the API server will crash-loop.

If kubectl dies:  ./cks doctor      To start over:  ./cks reset 9

Grade with:  ./cks verify 9
EOF
  step "audit config cleared; task in $d/TASK.md"
}

q_verify() {
  start_checks
  # --- flags ---
  local pf lp ma mb ms
  pf=$(apiserver_flag --audit-policy-file); lp=$(apiserver_flag --audit-log-path)
  ma=$(apiserver_flag --audit-log-maxage);  mb=$(apiserver_flag --audit-log-maxbackup)
  ms=$(apiserver_flag --audit-log-maxsize)
  [ "$pf" = "$Q9_POLICY" ] && ok "flag --audit-policy-file=$Q9_POLICY" || no "flag --audit-policy-file=$Q9_POLICY" "got '${pf:-<unset>}'"
  [ "$lp" = "$Q9_LOG" ]    && ok "flag --audit-log-path=$Q9_LOG"       || no "flag --audit-log-path=$Q9_LOG" "got '${lp:-<unset>}'"
  [ "$ma" = "$Q9_MAXAGE" ] && ok "flag --audit-log-maxage=$Q9_MAXAGE"  || no "flag --audit-log-maxage=$Q9_MAXAGE" "got '${ma:-<unset>}'"
  [ "$mb" = "$Q9_MAXBACKUP" ] && ok "flag --audit-log-maxbackup=$Q9_MAXBACKUP" || no "flag --audit-log-maxbackup=$Q9_MAXBACKUP" "got '${mb:-<unset>}'"
  [ "$ms" = "$Q9_MAXSIZE" ] && ok "flag --audit-log-maxsize=$Q9_MAXSIZE" || no "flag --audit-log-maxsize=$Q9_MAXSIZE" "got '${ms:-<unset>}'"

  # --- mounts (the step everyone misses) ---
  apiserver_mounts /etc/kubernetes/audit && ok "volumeMount for /etc/kubernetes/audit present" \
    || no "volumeMount for /etc/kubernetes/audit present" "static pods only see what is mounted in"
  apiserver_mounts /var/log/kubernetes && ok "volumeMount for /var/log/kubernetes present" \
    || no "volumeMount for /var/log/kubernetes present" "needs a writable hostPath mount"

  # --- API server survived ---
  if k get --raw /healthz >/dev/null 2>&1; then
    ok "kube-apiserver is healthy after the change"
  else
    no "kube-apiserver is healthy after the change" "./cks doctor  (most likely the hostPath mounts are missing)"
    report; return
  fi

  # --- policy file is valid and has the right shape ---
  local pol; pol=$(node_read "$Q9_POLICY")
  if [ -z "$pol" ]; then
    no "audit policy exists at $Q9_POLICY" "create it on the node"; report; return
  fi
  ok "audit policy exists at $Q9_POLICY"
  printf '%s' "$pol" | grep -q 'kind: Policy' && ok "policy kind: Policy" || no "policy kind: Policy"
  printf '%s' "$pol" | grep -q 'audit.k8s.io/v1' && ok "policy apiVersion: audit.k8s.io/v1" || no "policy apiVersion: audit.k8s.io/v1"

  # --- behavioural test: generate traffic, then read the levels back ---
  step "generating audit traffic ..."
  kq create ns web-apps
  kq -n web-apps create deployment audit-probe --image=busybox:1.36 -- sleep 3600
  kq -n default create configmap audit-probe-cm --from-literal=k=v
  kq -n default delete configmap audit-probe-cm
  kq -n default create secret generic audit-probe-sec --from-literal=k=v
  kq -n default delete secret audit-probe-sec
  kq get pods -A
  sleep 5

  local lv
  lv=$(node_sh "grep '\"verb\":\"delete\"' $Q9_LOG 2>/dev/null | grep -E '\"resource\":\"(configmaps|secrets)\"' | grep -o '\"level\":\"[^\"]*\"' | sort -u | tr '\n' ' '")
  if printf '%s' "$lv" | grep -q 'RequestResponse'; then
    ok "RULE a: delete configmaps/secrets logged at RequestResponse"
  else
    no "RULE a: delete configmaps/secrets logged at RequestResponse" "observed level(s): ${lv:-none}"
  fi
  lv=$(node_sh "grep '\"resource\":\"deployments\"' $Q9_LOG 2>/dev/null | grep '\"namespace\":\"web-apps\"' | grep -o '\"level\":\"[^\"]*\"' | sort -u | tr '\n' ' '")
  if printf '%s' "$lv" | grep -q 'Metadata'; then
    ok "RULE b: deployments in web-apps logged at Metadata"
  else
    no "RULE b: deployments in web-apps logged at Metadata" "observed level(s): ${lv:-none}"
  fi
  lv=$(node_sh "grep '\"resource\":\"namespaces\"' $Q9_LOG 2>/dev/null | grep -o '\"level\":\"[^\"]*\"' | sort -u | tr '\n' ' '")
  if printf '%s' "$lv" | grep -q 'Request"'; then
    ok "RULE c: namespaces resource logged at Request"
  else
    no "RULE c: namespaces resource logged at Request" "observed level(s): ${lv:-none}"
  fi
  lv=$(node_sh "grep '\"resource\":\"pods\"' $Q9_LOG 2>/dev/null | grep -o '\"level\":\"[^\"]*\"' | sort -u | tr '\n' ' '")
  if printf '%s' "$lv" | grep -q 'Metadata'; then
    ok "RULE d: catch-all logs other resources at Metadata"
  else
    no "RULE d: catch-all logs other resources at Metadata" "observed level(s): ${lv:-none}; is '- level: Metadata' last?"
  fi
  if node_sh "test -s $Q9_LOG"; then ok "audit log is being written at $Q9_LOG"
  else no "audit log is being written at $Q9_LOG" "empty or missing -- check the writable mount"; fi
  report
}

q_solve() {
  node_sh "mkdir -p /etc/kubernetes/audit /var/log/kubernetes" >/dev/null
  node_write "$Q9_POLICY" <<'EOF'
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:
  - RequestReceived
rules:
  - level: RequestResponse
    verbs: ["delete"]
    resources:
    - group: ""
      resources: ["configmaps", "secrets"]
  - level: Metadata
    resources:
    - group: "apps"
      resources: ["deployments"]
    namespaces: ["web-apps"]
  - level: Request
    resources:
    - group: ""
      resources: ["namespaces"]
  - level: Metadata
EOF
  mark_apiserver
  mark_apiserver
  apiserver_edit_multi \
    "setflag --audit-log-maxsize $Q9_MAXSIZE" \
    "setflag --audit-log-maxbackup $Q9_MAXBACKUP" \
    "setflag --audit-log-maxage $Q9_MAXAGE" \
    "setflag --audit-log-path $Q9_LOG" \
    "setflag --audit-policy-file $Q9_POLICY" \
    "addvol audit-policy /etc/kubernetes/audit /etc/kubernetes/audit true" \
    "addvol audit-log /var/log/kubernetes /var/log/kubernetes false"
  settle_apiserver 60 || true
}

# Surgical: only undoes THIS question, so q13's work survives.
q_reset() { q_setup; }
