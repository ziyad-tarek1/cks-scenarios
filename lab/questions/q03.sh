Q_TITLE="Dockerfile + Pod hardening (non-root user, readOnlyRootFilesystem)"
Q_TAGS="files"
Q3_UID=63356

q_setup() {
  local d; d=$(labdir q03)
  cat > "$d/Dockerfile" <<'EOF'
FROM ubuntu:20.04
RUN apt-get update && apt-get install -y python3 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY . /app
USER root
CMD ["python3", "app.py"]
EOF
  cat > "$d/deployment.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hardened-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hardened-app
  template:
    metadata:
      labels:
        app: hardened-app
    spec:
      containers:
      - name: app
        image: busybox:1.36
        command: ["sh","-c","sleep 3600"]
EOF
  cat > "$d/TASK.md" <<EOF
Apply security best practices to BOTH files in $d :

  Dockerfile       -> must not run as root; run as UID $Q3_UID
  deployment.yaml  -> container must have:
                        runAsUser: $Q3_UID
                        runAsNonRoot: true
                        readOnlyRootFilesystem: true
                        allowPrivilegeEscalation: false
                        capabilities.drop: ["ALL"]

(runAsUser / runAsNonRoot may be set at pod level and inherited.)

Then apply it:   kubectl --context $KCTX apply -f $d/deployment.yaml

CAREFUL: "nobody" is UID 65534, NOT $Q3_UID. The task gives you a UID -- use it.

Grade with:  ./cks verify 3
EOF
  kq delete deploy hardened-app || true
  step "files written to $d"
}

q_verify() {
  start_checks
  local d="$LAB/q03" df="$LAB/q03/Dockerfile"

  # ---- Dockerfile ----
  if [ -f "$df" ]; then
    local u
    u=$(grep -iE '^[[:space:]]*USER[[:space:]]+' "$df" | tail -1 | awk '{print $2}')
    if [ -z "$u" ]; then
      no "Dockerfile: has a USER instruction" "add: USER $Q3_UID"
    elif [ "$u" = "root" ] || [ "$u" = "0" ]; then
      no "Dockerfile: does not run as root" "USER is '$u'"
    elif [ "$u" = "$Q3_UID" ]; then
      ok "Dockerfile: USER $Q3_UID"
    elif [ "$u" = "nobody" ] || [ "$u" = "65534" ]; then
      no "Dockerfile: USER is the required UID $Q3_UID" \
         "'$u' resolves to UID 65534, not $Q3_UID - the grader checks the UID"
    else
      no "Dockerfile: USER is the required UID $Q3_UID" "USER is '$u'"
    fi
    # prove it by building, if docker is available
    if docker info >/dev/null 2>&1 && [ "$u" = "$Q3_UID" ]; then
      if docker build -q -t cks-q03-check "$d" >/dev/null 2>&1; then
        local realuid
        realuid=$(docker run --rm --entrypoint sh cks-q03-check -c 'id -u' 2>/dev/null)
        if [ "$realuid" = "$Q3_UID" ]; then
          ok "Dockerfile: image actually runs as UID $Q3_UID (verified by building it)"
        else
          no "Dockerfile: image actually runs as UID $Q3_UID" "built image runs as '$realuid'"
        fi
        docker rmi -f cks-q03-check >/dev/null 2>&1
      else
        warn "could not build the Dockerfile to verify (skipping that check)"
      fi
    fi
  else
    no "Dockerfile exists at $df" "run ./cks reset 3"
  fi

  # ---- live Deployment ----
  if ! k get deploy hardened-app >/dev/null 2>&1; then
    no "Deployment 'hardened-app' applied to the cluster" \
       "kubectl --context $KCTX apply -f $d/deployment.yaml"
    report; return
  fi
  ok "Deployment 'hardened-app' applied to the cluster"

  local J='{.spec.template.spec}'
  local pod_ru pod_rnr c_ru c_rnr c_ro c_ape c_drop
  pod_ru=$(k get deploy hardened-app  -o jsonpath='{.spec.template.spec.securityContext.runAsUser}')
  pod_rnr=$(k get deploy hardened-app -o jsonpath='{.spec.template.spec.securityContext.runAsNonRoot}')
  c_ru=$(k get deploy hardened-app    -o jsonpath='{.spec.template.spec.containers[0].securityContext.runAsUser}')
  c_rnr=$(k get deploy hardened-app   -o jsonpath='{.spec.template.spec.containers[0].securityContext.runAsNonRoot}')
  c_ro=$(k get deploy hardened-app    -o jsonpath='{.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem}')
  c_ape=$(k get deploy hardened-app   -o jsonpath='{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}')
  c_drop=$(k get deploy hardened-app  -o jsonpath='{.spec.template.spec.containers[0].securityContext.capabilities.drop}')

  if [ "${c_ru:-$pod_ru}" = "$Q3_UID" ]; then
    ok "Deployment: runAsUser=$Q3_UID"
  else
    no "Deployment: runAsUser=$Q3_UID" "got container='${c_ru:-}' pod='${pod_ru:-}'"
  fi
  if [ "${c_rnr:-$pod_rnr}" = "true" ]; then
    ok "Deployment: runAsNonRoot=true"
  else
    no "Deployment: runAsNonRoot=true" "got container='${c_rnr:-}' pod='${pod_rnr:-}'"
  fi
  if [ "$c_ro" = "true" ]; then
    ok "Deployment: readOnlyRootFilesystem=true (container level)"
  else
    no "Deployment: readOnlyRootFilesystem=true (container level)" "this setting only exists per-container"
  fi
  if [ "$c_ape" = "false" ]; then
    ok "Deployment: allowPrivilegeEscalation=false"
  else
    no "Deployment: allowPrivilegeEscalation=false" "got '${c_ape:-<unset>}'"
  fi
  if printf '%s' "$c_drop" | grep -q 'ALL'; then
    ok "Deployment: capabilities.drop includes ALL"
  else
    no "Deployment: capabilities.drop includes ALL" "capabilities: {drop: [\"ALL\"]}"
  fi

  # runtime proof
  local po
  po=$(ready_pod default app=hardened-app hardened-app 240s)
  if [ -n "$po" ] && k wait --for=condition=Ready "$po" --timeout=120s >/dev/null 2>&1; then
    local uid rofs
    uid=$(k exec "$po" -- id -u 2>/dev/null)
    [ "$uid" = "$Q3_UID" ] && ok "running pod really has uid=$Q3_UID" \
      || no "running pod really has uid=$Q3_UID" "got '$uid'"
    if k exec "$po" -- touch /rocheck 2>&1 | grep -qi 'read-only'; then
      ok "running pod's root filesystem is read-only"
    else
      no "running pod's root filesystem is read-only" "touch / succeeded"
    fi
  else
    warn "pod not Ready, skipping runtime checks (manifest checks above still count)"
  fi
  report
}

q_solve() {
  local d; d=$(labdir q03)
  cat > "$d/Dockerfile" <<EOF
FROM ubuntu:20.04
RUN apt-get update && apt-get install -y python3 && rm -rf /var/lib/apt/lists/*
RUN useradd -u $Q3_UID -s /sbin/nologin appuser
WORKDIR /app
COPY . /app
USER $Q3_UID
CMD ["python3", "app.py"]
EOF
  cat > "$d/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hardened-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hardened-app
  template:
    metadata:
      labels:
        app: hardened-app
    spec:
      securityContext:
        runAsUser: $Q3_UID
        runAsNonRoot: true
      containers:
      - name: app
        image: busybox:1.36
        command: ["sh","-c","sleep 3600"]
        securityContext:
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
          capabilities:
            drop: ["ALL"]
EOF
  k apply -f "$d/deployment.yaml" >/dev/null
}
