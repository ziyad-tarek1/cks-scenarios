Q_TITLE="NetworkPolicy: default-deny ingress in prod + allow prod pods -> data pods"
Q_TAGS="cluster"

q_setup() {
  local d; d=$(labdir q06)
  kq create ns prod; kq create ns data
  k label ns prod name=prod --overwrite >/dev/null
  k label ns data name=data --overwrite >/dev/null
  kq -n prod delete netpol --all; kq -n data delete netpol --all

  # targets + clients
  kq -n data run backend --image=nginx:1.27 -l role=backend --port=80
  kq -n data run inside  --image=nicolaka/netshoot --command -- sleep 86400
  kq -n prod run allowed --image=nicolaka/netshoot -l app=myapp --command -- sleep 86400
  kq -n prod run denied  --image=nicolaka/netshoot -l app=other --command -- sleep 86400
  # something listening inside prod, so part 1 is testable
  kq -n prod run prodweb --image=nginx:1.27 -l app=prodweb --port=80

  step "waiting for test pods ..."
  k -n data wait --for=condition=Ready pod/backend pod/inside --timeout=300s >/dev/null 2>&1
  k -n prod wait --for=condition=Ready pod/allowed pod/denied pod/prodweb --timeout=300s >/dev/null 2>&1

  cat > "$d/TASK.md" <<EOF
Two NetworkPolicies:

1. In namespace "prod": DENY ALL INGRESS traffic to every pod.

2. In namespace "data": allow ingress to pods labelled role=backend
   ONLY from pods labelled app=myapp that live in namespace prod.
   Use a namespaceSelector AND a podSelector together.

Test pods already exist:
   prod/allowed  (app=myapp)   -> should reach data/backend
   prod/denied   (app=other)   -> should NOT reach data/backend
   data/inside   (same ns)     -> should NOT reach data/backend
   prod/prodweb  (nginx :80)   -> must NOT be reachable from data/inside

Namespaces are already labelled name=prod and name=data.

Remember: one list item under 'from:' = AND. Two list items = OR.

Grade with:  ./cks verify 6
EOF
  step "test pods ready; task in $d/TASK.md"
}

q_verify() {
  start_checks
  local bip pip
  bip=$(k -n data get po backend  -o jsonpath='{.status.podIP}' 2>/dev/null)
  pip=$(k -n prod get po prodweb  -o jsonpath='{.status.podIP}' 2>/dev/null)
  if [ -z "$bip" ] || [ -z "$pip" ]; then
    no "test pods are running" "./cks reset 6"; report; return
  fi

  # --- policy objects exist ---
  local np_prod np_data
  np_prod=$(k -n prod get netpol -o name 2>/dev/null | wc -l | tr -d ' ')
  np_data=$(k -n data get netpol -o name 2>/dev/null | wc -l | tr -d ' ')
  [ "$np_prod" -ge 1 ] && ok "a NetworkPolicy exists in namespace prod" \
    || no "a NetworkPolicy exists in namespace prod" "create the deny-all-ingress policy"
  [ "$np_data" -ge 1 ] && ok "a NetworkPolicy exists in namespace data" \
    || no "a NetworkPolicy exists in namespace data" "create the allow-prod-to-data policy"

  # --- Part 1: default-deny ingress in prod, proven with traffic ---
  local c
  c=$(curl_from data inside "http://$pip" )
  if [ "$c" = "000" ]; then
    ok "PART 1: ingress to prod/prodweb is blocked (data/inside -> prod, timed out)"
  else
    no "PART 1: ingress to prod/prodweb is blocked" "got HTTP $c; prod needs podSelector:{} + policyTypes:[Ingress] + ingress:[]"
  fi
  # the deny-all must select ALL pods, so prod->prod is blocked too
  c=$(curl_from prod denied "http://$pip")
  if [ "$c" = "000" ]; then
    ok "PART 1: deny-all applies to same-namespace traffic too (podSelector: {})"
  else
    no "PART 1: deny-all applies to same-namespace traffic too" "got HTTP $c; podSelector must be {} (all pods)"
  fi

  # --- Part 2: selective allow into data/backend ---
  c=$(curl_from prod allowed "http://$bip")
  if [ "$c" = "200" ]; then
    ok "PART 2: prod/allowed (app=myapp) CAN reach data/backend"
  else
    no "PART 2: prod/allowed (app=myapp) CAN reach data/backend" "got HTTP $c; the allow policy is too strict or mislabelled"
  fi
  c=$(curl_from prod denied "http://$bip")
  if [ "$c" = "000" ]; then
    ok "PART 2: prod/denied (app=other) CANNOT reach data/backend"
  else
    no "PART 2: prod/denied (app=other) CANNOT reach data/backend" \
       "got HTTP $c -- you used two '-' items under from: (OR) instead of one (AND)"
  fi
  c=$(curl_from data inside "http://$bip")
  if [ "$c" = "000" ]; then
    ok "PART 2: data/inside (wrong namespace) CANNOT reach data/backend"
  else
    no "PART 2: data/inside CANNOT reach data/backend" \
       "got HTTP $c -- your podSelector/namespaceSelector combination is too loose"
  fi
  report
}

q_solve() {
  k apply -f - >/dev/null <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: prod
spec:
  podSelector: {}
  policyTypes: [Ingress]
  ingress: []
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-prod-to-data
  namespace: data
spec:
  podSelector:
    matchLabels:
      role: backend
  policyTypes: [Ingress]
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: prod
      podSelector:
        matchLabels:
          app: myapp
EOF
}

q_reset() { kq -n prod delete netpol --all; kq -n data delete netpol --all; info "policies cleared (test pods kept)"; }
