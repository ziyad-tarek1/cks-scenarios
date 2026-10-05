Q_TITLE="TLS Secret + Ingress with a host, verified with curl"
Q_TAGS="cluster ingress"
Q12_HOST=app.example.com; Q12_SECRET=tls-secret; Q12_ING=myapp-ingress; Q12_SVC=myapp-svc

ensure_ingress() {
  if k -n ingress-nginx get deploy ingress-nginx-controller >/dev/null 2>&1; then
    step "ingress-nginx already installed"
  else
    info "installing ingress-nginx (one-off, ~1-2 min)"
    k label node "$NODE" ingress-ready=true --overwrite >/dev/null
    k apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml >/dev/null 2>&1 \
      || die "could not install ingress-nginx (network?)"
  fi
  step "waiting for the ingress controller ..."
  unwedge_controlplane
  # The admission Jobs must finish before the controller can go Ready, and on a
  # brand-new cluster that races with every other image pull. Give it a real
  # budget and re-check, rather than warning after one short wait.
  local i
  for i in 1 2 3; do
    k -n ingress-nginx wait --for=condition=Ready pod \
      -l app.kubernetes.io/component=controller --timeout=240s >/dev/null 2>&1 && break
    unwedge_controlplane
  done
  # Final confirmation, polled: the Deployment can report Ready a few seconds after
  # the wait returns, and a premature warning here is just misleading.
  local ready=no
  for i in $(seq 1 24); do
    if k -n ingress-nginx get po -l app.kubernetes.io/component=controller \
         -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null | grep -q true; then
      ready=yes; break
    fi
    sleep 5
  done
  if [ "$ready" = yes ]; then
    step "ingress controller ready"
  else
    warn "ingress controller still not Ready; re-run ./cks setup 12 before verifying"
  fi
}

q_setup() {
  local d; d=$(labdir q12)
  mkdir -p "$d/certs"
  if [ ! -f "$d/certs/cert.crt" ]; then
    step "generating cert for $Q12_HOST"
    openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
      -keyout "$d/certs/cert.key" -out "$d/certs/cert.crt" \
      -subj "/CN=$Q12_HOST" -addext "subjectAltName=DNS:$Q12_HOST" >/dev/null 2>&1
  fi
  ensure_ingress
  kq delete ing "$Q12_ING"; kq delete secret "$Q12_SECRET"
  kq delete deploy myapp; kq delete svc "$Q12_SVC"
  k create deployment myapp --image=nginx:1.27 >/dev/null
  k expose deployment myapp --name="$Q12_SVC" --port=80 >/dev/null
  wait_ready default myapp 240s

  cat > "$d/TASK.md" <<EOF
A Service "$Q12_SVC" (port 80) already exists in namespace default.
Cert and key are provided:
    $d/certs/cert.crt
    $d/certs/cert.key

1. Create a TLS Secret named "$Q12_SECRET" in namespace default from them.

2. Create an Ingress named "$Q12_ING" in namespace default that:
     - serves host $Q12_HOST
     - terminates TLS using secret $Q12_SECRET
     - routes path / (pathType: Prefix) to service $Q12_SVC port 80
     - uses ingressClassName: nginx

3. Test it:
     curl -k --resolve $Q12_HOST:443:127.0.0.1 https://$Q12_HOST/

   Do NOT use the \$(kubectl get ing -o jsonpath={.status.loadBalancer.ingress[0].ip})
   /etc/hosts trick -- on this cluster (and most non-cloud clusters) that field is
   empty and you would append a broken /etc/hosts line.

Grade with:  ./cks verify 12
EOF
  step "backend ready; task in $d/TASK.md"
}

q_verify() {
  start_checks
  if ! k get secret "$Q12_SECRET" >/dev/null 2>&1; then
    no "Secret '$Q12_SECRET' exists" "kubectl create secret tls $Q12_SECRET --cert=$LAB/q12/certs/cert.crt --key=$LAB/q12/certs/cert.key"
  else
    ok "Secret '$Q12_SECRET' exists"
    [ "$(k get secret "$Q12_SECRET" -o jsonpath='{.type}')" = "kubernetes.io/tls" ] \
      && ok "Secret type is kubernetes.io/tls" || no "Secret type is kubernetes.io/tls"
  fi

  if ! k get ing "$Q12_ING" >/dev/null 2>&1; then
    no "Ingress '$Q12_ING' exists" "create it in namespace default"; report; return
  fi
  ok "Ingress '$Q12_ING' exists"

  local host tlshost tlssec svc port pt cls
  host=$(k get ing "$Q12_ING" -o jsonpath='{.spec.rules[0].host}')
  tlshost=$(k get ing "$Q12_ING" -o jsonpath='{.spec.tls[0].hosts[0]}')
  tlssec=$(k get ing "$Q12_ING" -o jsonpath='{.spec.tls[0].secretName}')
  svc=$(k get ing "$Q12_ING" -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}')
  port=$(k get ing "$Q12_ING" -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.port.number}')
  pt=$(k get ing "$Q12_ING" -o jsonpath='{.spec.rules[0].http.paths[0].pathType}')
  cls=$(k get ing "$Q12_ING" -o jsonpath='{.spec.ingressClassName}')

  [ "$host" = "$Q12_HOST" ] && ok "rule host is $Q12_HOST" || no "rule host is $Q12_HOST" "got '${host:-<unset>}'"
  [ "$tlshost" = "$Q12_HOST" ] && ok "spec.tls hosts includes $Q12_HOST" || no "spec.tls hosts includes $Q12_HOST" "got '${tlshost:-<unset>}' -- must match the rule host"
  [ "$tlssec" = "$Q12_SECRET" ] && ok "spec.tls secretName is $Q12_SECRET" || no "spec.tls secretName is $Q12_SECRET" "got '${tlssec:-<unset>}'"
  [ "$svc" = "$Q12_SVC" ] && ok "backend service is $Q12_SVC" || no "backend service is $Q12_SVC" "got '${svc:-<unset>}'"
  [ "$port" = "80" ] && ok "backend port is 80" || no "backend port is 80" "got '${port:-<unset>}'"
  [ "$pt" = "Prefix" ] && ok "pathType is Prefix" || no "pathType is Prefix" "got '${pt:-<unset>}'"
  [ -n "$cls" ] && ok "ingressClassName is set ($cls)" \
    || no "ingressClassName is set" "set it explicitly; no IngressClass is marked default here"

  # --- the real test: HTTPS through the controller, with the right cert ---
  step "curling https://$Q12_HOST through the controller ..."
  sleep 5
  local code
  code=$(node_sh "curl -sk --resolve $Q12_HOST:443:127.0.0.1 -o /dev/null -w '%{http_code}' https://$Q12_HOST/" 2>/dev/null)
  if [ "$code" = "200" ]; then
    ok "curl https://$Q12_HOST/ returns 200"
  else
    no "curl https://$Q12_HOST/ returns 200" "got '$code' -- check ingressClassName, service name/port, and controller readiness"
  fi
  local subj want
  subj=$(node_sh "echo | openssl s_client -connect 127.0.0.1:443 -servername $Q12_HOST 2>/dev/null | openssl x509 -noout -subject 2>/dev/null")
  if printf '%s' "$subj" | grep -q "CN *= *$Q12_HOST"; then
    ok "the served certificate is yours (subject CN=$Q12_HOST)"
  else
    no "the served certificate is yours (CN=$Q12_HOST)" \
       "got '${subj:-nothing}' -- 'Fake Certificate' means TLS didn't bind: check secretName/namespace/host match"
  fi
  report
}

q_solve() {
  local d="$LAB/q12"
  k create secret tls "$Q12_SECRET" --cert="$d/certs/cert.crt" --key="$d/certs/cert.key" >/dev/null 2>&1
  k apply -f - >/dev/null <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $Q12_ING
  namespace: default
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - $Q12_HOST
    secretName: $Q12_SECRET
  rules:
  - host: $Q12_HOST
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: $Q12_SVC
            port:
              number: 80
EOF
}

q_reset() { kq delete ing "$Q12_ING"; kq delete secret "$Q12_SECRET"; q_setup; }
