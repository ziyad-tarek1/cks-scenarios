Q_TITLE="Create a TLS Secret and mount it into a Deployment"
Q_TAGS="cluster files"
Q7_SECRET=my-tls-secret; Q7_DEPLOY=tls-app; Q7_MOUNT=/etc/tls

q_setup() {
  local d; d=$(labdir q07)
  mkdir -p "$d/certs"
  if [ ! -f "$d/certs/tls.crt" ]; then
    step "generating a self-signed cert at $d/certs"
    openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
      -keyout "$d/certs/tls.key" -out "$d/certs/tls.crt" \
      -subj "/CN=app.example.com" -addext "subjectAltName=DNS:app.example.com" >/dev/null 2>&1
  fi
  kq delete secret "$Q7_SECRET"
  k apply -f - >/dev/null <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $Q7_DEPLOY
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels: {app: $Q7_DEPLOY}
  template:
    metadata:
      labels: {app: $Q7_DEPLOY}
    spec:
      containers:
      - name: app
        image: busybox:1.36
        command: ["sh","-c","sleep 3600"]
EOF
  cat > "$d/TASK.md" <<EOF
A certificate and key are provided:
    $d/certs/tls.crt
    $d/certs/tls.key

1. Create a TLS Secret named "$Q7_SECRET" in namespace default from those files.
   (type must be kubernetes.io/tls)

2. Edit Deployment "$Q7_DEPLOY" to mount that Secret as a volume at
   $Q7_MOUNT , read-only.

    kubectl --context $KCTX edit deployment $Q7_DEPLOY

Grade with:  ./cks verify 7
EOF
  step "cert + deployment ready; task in $d/TASK.md"
}

q_verify() {
  start_checks
  if ! k get secret "$Q7_SECRET" >/dev/null 2>&1; then
    no "Secret '$Q7_SECRET' exists in default" \
       "kubectl create secret tls $Q7_SECRET --cert=$LAB/q07/certs/tls.crt --key=$LAB/q07/certs/tls.key"
  else
    ok "Secret '$Q7_SECRET' exists in default"
    local t; t=$(k get secret "$Q7_SECRET" -o jsonpath='{.type}')
    [ "$t" = "kubernetes.io/tls" ] && ok "Secret type is kubernetes.io/tls" \
      || no "Secret type is kubernetes.io/tls" "got '$t' -- use 'kubectl create secret tls', not 'generic'"
    local keys; keys=$(k get secret "$Q7_SECRET" -o jsonpath='{.data}')
    printf '%s' "$keys" | grep -q 'tls.crt' && ok "Secret has key tls.crt" || no "Secret has key tls.crt"
    printf '%s' "$keys" | grep -q 'tls.key' && ok "Secret has key tls.key" || no "Secret has key tls.key"
    # content must match the provided files
    local want got
    want=$(openssl x509 -in "$LAB/q07/certs/tls.crt" -noout -fingerprint -sha256 2>/dev/null | cut -d= -f2)
    got=$(k get secret "$Q7_SECRET" -o jsonpath='{.data.tls\.crt}' | base64 -d 2>/dev/null \
          | openssl x509 -noout -fingerprint -sha256 2>/dev/null | cut -d= -f2)
    [ -n "$want" ] && [ "$want" = "$got" ] && ok "Secret contains the PROVIDED certificate" \
      || no "Secret contains the PROVIDED certificate" "you created it from a different cert"
  fi

  if ! k get deploy "$Q7_DEPLOY" >/dev/null 2>&1; then
    no "Deployment '$Q7_DEPLOY' exists" "./cks reset 7"; report; return
  fi
  local vol
  vol=$(k get deploy "$Q7_DEPLOY" -o jsonpath="{.spec.template.spec.volumes[?(@.secret.secretName=='$Q7_SECRET')].name}")
  if [ -z "$vol" ]; then
    no "Deployment has a volume backed by Secret '$Q7_SECRET'" \
       "volumes[].secret.secretName must be exactly '$Q7_SECRET' -- a typo here leaves the pod in ContainerCreating"
    report; return
  fi
  ok "Deployment has a volume backed by Secret '$Q7_SECRET'"
  local mp ro
  mp=$(k get deploy "$Q7_DEPLOY" -o jsonpath="{.spec.template.spec.containers[0].volumeMounts[?(@.name=='$vol')].mountPath}")
  ro=$(k get deploy "$Q7_DEPLOY" -o jsonpath="{.spec.template.spec.containers[0].volumeMounts[?(@.name=='$vol')].readOnly}")
  [ "$mp" = "$Q7_MOUNT" ] && ok "volumeMount mountPath=$Q7_MOUNT" || no "volumeMount mountPath=$Q7_MOUNT" "got '${mp:-<unset>}'"
  [ "$ro" = "true" ] && ok "volumeMount readOnly=true" || no "volumeMount readOnly=true" "got '${ro:-<unset>}'"

  local po; po=$(ready_pod default "app=$Q7_DEPLOY" "$Q7_DEPLOY" 240s)
  if [ -n "$po" ] && k wait --for=condition=Ready "$po" --timeout=120s >/dev/null 2>&1; then
    if k exec "$po" -- cat "$Q7_MOUNT/tls.crt" >/dev/null 2>&1; then
      ok "running pod can read $Q7_MOUNT/tls.crt"
    else
      no "running pod can read $Q7_MOUNT/tls.crt" "check the mountPath"
    fi
  else
    local reason
    reason=$(k describe po -l "app=$Q7_DEPLOY" 2>/dev/null | grep -m1 'FailedMount')
    no "pod reaches Ready with the secret mounted" "${reason:-pod not Ready; kubectl describe po -l app=$Q7_DEPLOY}"
  fi
  report
}

q_solve() {
  local d="$LAB/q07"
  k create secret tls "$Q7_SECRET" --cert="$d/certs/tls.crt" --key="$d/certs/tls.key" >/dev/null 2>&1
  k patch deploy "$Q7_DEPLOY" --type=strategic -p "$(cat <<EOF
spec:
  template:
    spec:
      volumes:
      - name: tls-vol
        secret:
          secretName: $Q7_SECRET
      containers:
      - name: app
        volumeMounts:
        - name: tls-vol
          mountPath: $Q7_MOUNT
          readOnly: true
EOF
)" >/dev/null
}

q_reset() { kq delete secret "$Q7_SECRET"; kq delete deploy "$Q7_DEPLOY"; q_setup; }
