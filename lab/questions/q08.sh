Q_TITLE="Make a Deployment comply with restricted Pod Security Admission"
Q_TAGS="cluster"
Q8_NS=confidential; Q8_DEPLOY=psa-app

q_setup() {
  local d; d=$(labdir q08)
  kq create ns "$Q8_NS"
  k label ns "$Q8_NS" \
    pod-security.kubernetes.io/enforce=restricted \
    pod-security.kubernetes.io/enforce-version=latest --overwrite >/dev/null
  kq delete deploy "$Q8_DEPLOY" -n "$Q8_NS"
  # non-compliant on purpose: no securityContext at all
  k apply -f - >/dev/null 2>&1 <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $Q8_DEPLOY
  namespace: $Q8_NS
spec:
  replicas: 1
  selector:
    matchLabels: {app: $Q8_DEPLOY}
  template:
    metadata:
      labels: {app: $Q8_DEPLOY}
    spec:
      containers:
      - name: c1
        image: busybox:1.36
        command: ["sh","-c","sleep 3600"]
      - name: c2
        image: busybox:1.36
        command: ["sh","-c","sleep 3600"]
EOF
  cat > "$d/TASK.md" <<EOF
Namespace "$Q8_NS" enforces the 'restricted' Pod Security Standard:

    kubectl --context $KCTX get ns $Q8_NS --show-labels

Deployment "$Q8_DEPLOY" has TWO containers and currently creates no pods at all,
because every pod it tries to create is rejected. Fix it so the pods run.

    kubectl --context $KCTX -n $Q8_NS edit deployment $Q8_DEPLOY
    kubectl --context $KCTX -n $Q8_NS get pods            # must become Running
    kubectl --context $KCTX -n $Q8_NS describe rs         # where the rejection shows up

Watch out: 'kubectl apply' only prints a Warning -- the real rejection happens on
the ReplicaSet. And 'restricted' needs FOUR things, one of which almost everyone
forgets.

Grade with:  ./cks verify 8
EOF
  step "namespace labelled restricted; non-compliant deployment created"
  step "task in $d/TASK.md"
}

q_verify() {
  start_checks
  local enf; enf=$(k get ns "$Q8_NS" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}')
  if [ "$enf" = "restricted" ]; then
    ok "namespace $Q8_NS still enforces 'restricted' (you didn't cheat by relabelling)"
  else
    no "namespace $Q8_NS still enforces 'restricted'" \
       "enforce label is '${enf:-<unset>}' -- the task is to fix the workload, not weaken the namespace"
  fi
  if ! k -n "$Q8_NS" get deploy "$Q8_DEPLOY" >/dev/null 2>&1; then
    no "Deployment '$Q8_DEPLOY' exists" "./cks reset 8"; report; return
  fi

  # per-container requirements of 'restricted'
  local n i name ape drop rnr seccomp p_rnr p_seccomp
  p_rnr=$(k -n "$Q8_NS"     get deploy "$Q8_DEPLOY" -o jsonpath='{.spec.template.spec.securityContext.runAsNonRoot}')
  p_seccomp=$(k -n "$Q8_NS" get deploy "$Q8_DEPLOY" -o jsonpath='{.spec.template.spec.securityContext.seccompProfile.type}')
  n=$(k -n "$Q8_NS" get deploy "$Q8_DEPLOY" -o json | python3 -c 'import json,sys;print(len(json.load(sys.stdin)["spec"]["template"]["spec"]["containers"]))')
  [ "$n" -eq 2 ] && ok "both containers still present" || no "both containers still present" "found $n -- don't delete one"

  for ((i=0;i<n;i++)); do
    name=$(k -n "$Q8_NS" get deploy "$Q8_DEPLOY" -o jsonpath="{.spec.template.spec.containers[$i].name}")
    ape=$(k -n "$Q8_NS"  get deploy "$Q8_DEPLOY" -o jsonpath="{.spec.template.spec.containers[$i].securityContext.allowPrivilegeEscalation}")
    drop=$(k -n "$Q8_NS" get deploy "$Q8_DEPLOY" -o jsonpath="{.spec.template.spec.containers[$i].securityContext.capabilities.drop}")
    rnr=$(k -n "$Q8_NS"  get deploy "$Q8_DEPLOY" -o jsonpath="{.spec.template.spec.containers[$i].securityContext.runAsNonRoot}")
    seccomp=$(k -n "$Q8_NS" get deploy "$Q8_DEPLOY" -o jsonpath="{.spec.template.spec.containers[$i].securityContext.seccompProfile.type}")
    [ "$ape" = "false" ] && ok "container '$name': allowPrivilegeEscalation=false" \
      || no "container '$name': allowPrivilegeEscalation=false" "container-level only; got '${ape:-<unset>}'"
    printf '%s' "$drop" | grep -q 'ALL' && ok "container '$name': capabilities.drop=[ALL]" \
      || no "container '$name': capabilities.drop=[ALL]" "container-level only; got '${drop:-<unset>}'"
    [ "${rnr:-$p_rnr}" = "true" ] && ok "container '$name': runAsNonRoot=true (pod or container)" \
      || no "container '$name': runAsNonRoot=true (pod or container)" "got '${rnr:-}' / pod '${p_rnr:-}'"
    local sc="${seccomp:-$p_seccomp}"
    if [ "$sc" = "RuntimeDefault" ] || [ "$sc" = "Localhost" ]; then
      ok "container '$name': seccompProfile.type=$sc"
    else
      no "container '$name': seccompProfile.type is RuntimeDefault or Localhost" \
         "THIS is the one everyone forgets -- got '${sc:-<unset>}'"
    fi
  done

  # the decisive test: PSA actually admits it, and pods run
  local ready
  ready=$(k -n "$Q8_NS" get deploy "$Q8_DEPLOY" -o jsonpath='{.status.readyReplicas}')
  if [ "${ready:-0}" -ge 1 ]; then
    ok "pods are actually Running (PSA admitted them)"
  else
    local ev
    ev=$(k -n "$Q8_NS" describe rs -l "app=$Q8_DEPLOY" 2>/dev/null | grep -m1 'violates PodSecurity' | sed 's/^[[:space:]]*//')
    no "pods are actually Running (PSA admitted them)" "${ev:-no pods yet; kubectl -n $Q8_NS describe rs}"
  fi

  # server-side dry-run as an independent confirmation
  if k -n "$Q8_NS" get deploy "$Q8_DEPLOY" -o yaml 2>/dev/null \
     | k -n "$Q8_NS" apply --dry-run=server -f - 2>&1 | grep -q 'violate PodSecurity'; then
    no "server-side dry-run reports no PodSecurity violation" "still violating; see the warning above"
  else
    ok "server-side dry-run reports no PodSecurity violation"
  fi
  report
}

q_solve() {
  k apply -f - >/dev/null <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $Q8_DEPLOY
  namespace: $Q8_NS
spec:
  replicas: 1
  selector:
    matchLabels: {app: $Q8_DEPLOY}
  template:
    metadata:
      labels: {app: $Q8_DEPLOY}
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: c1
        image: busybox:1.36
        command: ["sh","-c","sleep 3600"]
        securityContext:
          allowPrivilegeEscalation: false
          capabilities: {drop: ["ALL"]}
      - name: c2
        image: busybox:1.36
        command: ["sh","-c","sleep 3600"]
        securityContext:
          allowPrivilegeEscalation: false
          capabilities: {drop: ["ALL"]}
EOF
}

q_reset() { kq delete deploy "$Q8_DEPLOY" -n "$Q8_NS"; q_setup; }
