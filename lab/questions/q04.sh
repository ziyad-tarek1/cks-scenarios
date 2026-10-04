Q_TITLE="securityContext on BOTH containers of a Deployment"
Q_TAGS="cluster"
Q4_UID=63356

q_setup() {
  local d; d=$(labdir q04)
  k apply -f - >/dev/null <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: two-containers
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: two-containers
  template:
    metadata:
      labels:
        app: two-containers
    spec:
      containers:
      - name: app1
        image: busybox:1.36
        command: ["sh","-c","sleep 3600"]
      - name: app2
        image: busybox:1.36
        command: ["sh","-c","sleep 3600"]
EOF
  cat > "$d/TASK.md" <<EOF
Deployment "two-containers" in namespace default has two containers.
Add a securityContext to BOTH containers with:

    runAsUser: $Q4_UID
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true

    kubectl --context $KCTX edit deployment two-containers

Grade with:  ./cks verify 4
EOF
  step "deployment 'two-containers' created; task in $d/TASK.md"
}

q_verify() {
  start_checks
  if ! k get deploy two-containers >/dev/null 2>&1; then
    no "Deployment 'two-containers' exists" "./cks reset 4"; report; return
  fi
  local n i name ru ape ro
  n=$(k get deploy two-containers -o jsonpath='{.spec.template.spec.containers}' | grep -o '"name"' | wc -l | tr -d ' ')
  if [ "$n" -lt 2 ]; then
    no "Deployment still has both containers" "found $n; do not delete a container"
  else
    ok "Deployment still has both containers"
  fi
  for i in 0 1; do
    name=$(k get deploy two-containers -o jsonpath="{.spec.template.spec.containers[$i].name}")
    [ -z "$name" ] && continue
    ru=$(k get deploy two-containers  -o jsonpath="{.spec.template.spec.containers[$i].securityContext.runAsUser}")
    ape=$(k get deploy two-containers -o jsonpath="{.spec.template.spec.containers[$i].securityContext.allowPrivilegeEscalation}")
    ro=$(k get deploy two-containers  -o jsonpath="{.spec.template.spec.containers[$i].securityContext.readOnlyRootFilesystem}")
    [ "$ru"  = "$Q4_UID" ] && ok "container '$name': runAsUser=$Q4_UID" \
      || no "container '$name': runAsUser=$Q4_UID" "got '${ru:-<unset>}' (must be on the CONTAINER, not the pod)"
    [ "$ape" = "false" ]   && ok "container '$name': allowPrivilegeEscalation=false" \
      || no "container '$name': allowPrivilegeEscalation=false" "got '${ape:-<unset>}'"
    [ "$ro"  = "true" ]    && ok "container '$name': readOnlyRootFilesystem=true" \
      || no "container '$name': readOnlyRootFilesystem=true" "got '${ro:-<unset>}'"
  done

  local po
  po=$(ready_pod default app=two-containers two-containers 240s)
  if [ -n "$po" ] && k wait --for=condition=Ready "$po" --timeout=120s >/dev/null 2>&1; then
    local u1 u2
    u1=$(k exec "$po" -c app1 -- id -u 2>/dev/null)
    u2=$(k exec "$po" -c app2 -- id -u 2>/dev/null)
    { [ "$u1" = "$Q4_UID" ] && [ "$u2" = "$Q4_UID" ]; } \
      && ok "both running containers report uid=$Q4_UID" \
      || no "both running containers report uid=$Q4_UID" "app1='$u1' app2='$u2'"
  else
    warn "pod not Ready, skipping runtime check"
  fi
  report
}

q_solve() {
  k patch deploy two-containers --type=json -p "[
    {\"op\":\"add\",\"path\":\"/spec/template/spec/containers/0/securityContext\",
     \"value\":{\"runAsUser\":$Q4_UID,\"allowPrivilegeEscalation\":false,\"readOnlyRootFilesystem\":true}},
    {\"op\":\"add\",\"path\":\"/spec/template/spec/containers/1/securityContext\",
     \"value\":{\"runAsUser\":$Q4_UID,\"allowPrivilegeEscalation\":false,\"readOnlyRootFilesystem\":true}}]" >/dev/null
}

q_reset() { kq delete deploy two-containers; q_setup; }
