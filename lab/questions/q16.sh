Q_TITLE="Istio: namespace sidecar injection + workload-level STRICT mTLS"
Q_TAGS="cluster istio"
Q16_NS=my-namespace; Q16_PA=workload-mtls; Q16_APP=my-app; Q16_PLAIN=plain

ensure_istio() {
  if k -n istio-system get deploy istiod >/dev/null 2>&1; then
    step "istio already installed"
  else
    need_bin istioctl "Install with: brew install istioctl"
    info "installing Istio (minimal profile, one-off, ~1-2 min)"
    istioctl install --set profile=minimal -y >/dev/null 2>&1 \
      || die "istioctl install failed"
  fi
  k -n istio-system wait --for=condition=Available deploy/istiod --timeout=300s >/dev/null 2>&1 \
    || warn "istiod not Available yet"
}

q_setup() {
  local d; d=$(labdir q16)
  ensure_istio
  kq create ns "$Q16_NS"; kq create ns "$Q16_PLAIN"
  # start WITHOUT the injection label -- that is part of the task
  k label ns "$Q16_NS" istio-injection- >/dev/null 2>&1
  kq -n "$Q16_NS" delete peerauthentication --all
  kq -n "$Q16_NS" delete deploy my-app mesh-client
  kq -n "$Q16_PLAIN" delete deploy plain-client

  k -n "$Q16_NS" create deployment my-app --image=nginx:1.27 >/dev/null 2>&1
  k -n "$Q16_NS" patch deploy my-app -p \
    '{"spec":{"template":{"metadata":{"labels":{"app":"my-app"}}}}}' >/dev/null 2>&1
  kq -n "$Q16_NS" expose deploy my-app --name=my-app --port=80
  k -n "$Q16_NS" create deployment mesh-client --image=nicolaka/netshoot -- sleep 86400 >/dev/null 2>&1
  k -n "$Q16_PLAIN" create deployment plain-client --image=nicolaka/netshoot -- sleep 86400 >/dev/null 2>&1

  step "waiting for workloads ..."
  wait_ready "$Q16_NS" my-app 300s
  wait_ready "$Q16_NS" mesh-client 300s
  wait_ready "$Q16_PLAIN" plain-client 300s

  cat > "$d/TASK.md" <<EOF
Istio is installed. Namespace "$Q16_NS" contains:
    deployment/my-app        (pods labelled app=my-app, Service my-app:80)
    deployment/mesh-client   (a client that should end up IN the mesh)
Namespace "$Q16_PLAIN" contains:
    deployment/plain-client  (stays OUT of the mesh -- do not change it)

1. Enable Istio sidecar injection for namespace "$Q16_NS".
   Then make sure the existing pods actually GET a sidecar (2/2), e.g.:
       kubectl --context $KCTX -n $Q16_NS rollout restart deploy
   Injection only applies to pods created AFTER the label.

2. Create a PeerAuthentication named "$Q16_PA" in namespace "$Q16_NS"
   that enforces STRICT mTLS for pods with label app=my-app
   (workload level -- use a selector, not namespace-wide).

End state the grader checks with real traffic:
    $Q16_PLAIN/plain-client  -> my-app  must FAIL  (plaintext, no sidecar)
    $Q16_NS/mesh-client      -> my-app  must WORK  (mTLS via sidecar)

Grade with:  ./cks verify 16
EOF
  step "task in $d/TASK.md"
}

q_verify() {
  start_checks
  # 1. namespace label
  local lbl; lbl=$(k get ns "$Q16_NS" -o jsonpath='{.metadata.labels.istio-injection}')
  if [ "$lbl" = "enabled" ]; then
    ok "namespace $Q16_NS labelled istio-injection=enabled"
  else
    no "namespace $Q16_NS labelled istio-injection=enabled" \
       "got '${lbl:-<unset>}' -- kubectl label ns $Q16_NS istio-injection=enabled"
  fi

  # 2. sidecars actually present -- inspect the CURRENT pod, not items[0],
  # whose ordering is arbitrary and may still be a pre-injection pod.
  local nc mypod
  mypod=$(ready_pod "$Q16_NS" app=my-app my-app 240s)
  # Modern Istio injects the proxy as a NATIVE sidecar: an initContainer with
  # restartPolicy: Always. Older versions add a normal container. Accept either.
  nc=$(k -n "$Q16_NS" get "${mypod:-pod/none}" \
        -o jsonpath='{range .spec.initContainers[*]}{.name} {end}{range .spec.containers[*]}{.name} {end}' 2>/dev/null)
  if printf '%s' "$nc" | grep -q 'istio-proxy'; then
    ok "my-app pods actually have the istio-proxy sidecar"
  else
    no "my-app pods actually have the istio-proxy sidecar" \
       "containers: '${nc:-none}' -- label the namespace THEN restart the deployment"
  fi

  # 3. PeerAuthentication object
  if ! k -n "$Q16_NS" get peerauthentication "$Q16_PA" >/dev/null 2>&1; then
    no "PeerAuthentication '$Q16_PA' exists in $Q16_NS" "create it"
  else
    ok "PeerAuthentication '$Q16_PA' exists in $Q16_NS"
    local mode sel
    mode=$(k -n "$Q16_NS" get peerauthentication "$Q16_PA" -o jsonpath='{.spec.mtls.mode}')
    sel=$(k -n "$Q16_NS"  get peerauthentication "$Q16_PA" -o jsonpath='{.spec.selector.matchLabels.app}')
    [ "$mode" = "STRICT" ] && ok "mtls.mode=STRICT" || no "mtls.mode=STRICT" "got '${mode:-<unset>}'"
    [ "$sel" = "$Q16_APP" ] && ok "selector.matchLabels.app=$Q16_APP (workload level)" \
      || no "selector.matchLabels.app=$Q16_APP (workload level)" \
            "got '${sel:-<unset>}' -- without a selector it applies namespace-wide"
  fi

  # 4. real traffic
  step "testing traffic (allow ~15s for the policy to propagate) ..."
  sleep 15
  local pc mc code
  pc=$(k -n "$Q16_PLAIN" get po -l app=plain-client -o name 2>/dev/null | head -1)
  mc=$(k -n "$Q16_NS"    get po -l app=mesh-client  -o name 2>/dev/null | head -1)

  if [ -n "$pc" ]; then
    code=$(curl_from "$Q16_PLAIN" "${pc#pod/}" "http://my-app.$Q16_NS.svc.cluster.local")
    if [ "$code" = "000" ]; then
      ok "plaintext client (no sidecar) is BLOCKED by STRICT mTLS"
    else
      no "plaintext client (no sidecar) is BLOCKED by STRICT mTLS" \
         "got HTTP $code -- PeerAuthentication is missing, PERMISSIVE, or its selector doesn't match"
    fi
  else
    warn "plain-client pod missing, skipping"
  fi

  if [ -n "$mc" ]; then
    code=$(curl_from "$Q16_NS" "${mc#pod/}" "http://my-app" netshoot)
    if [ "$code" = "200" ]; then
      ok "in-mesh client (mTLS) can still reach my-app"
    else
      no "in-mesh client (mTLS) can still reach my-app" \
         "got HTTP $code -- mesh-client has no sidecar, or my-app is down (did you restart the deployments?)"
    fi
  else
    warn "mesh-client pod missing, skipping"
  fi
  report
}

q_solve() {
  k label ns "$Q16_NS" istio-injection=enabled --overwrite >/dev/null
  k -n "$Q16_NS" rollout restart deploy >/dev/null 2>&1
  k -n "$Q16_NS" rollout status deploy/my-app --timeout=300s >/dev/null 2>&1
  k -n "$Q16_NS" rollout status deploy/mesh-client --timeout=300s >/dev/null 2>&1
  k apply -f - >/dev/null <<EOF
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: $Q16_PA
  namespace: $Q16_NS
spec:
  selector:
    matchLabels:
      app: $Q16_APP
  mtls:
    mode: STRICT
EOF
}

q_reset() {
  kq -n "$Q16_NS" delete peerauthentication --all
  k label ns "$Q16_NS" istio-injection- >/dev/null 2>&1
  q_setup
}
