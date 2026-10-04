Q_TITLE="ServiceAccount with automount disabled + projected token volume"
Q_TAGS="cluster"
Q5_NS=monitoring; Q5_SA=monitor-sa; Q5_DEPLOY=token-app
Q5_AUD=api; Q5_EXP=3600; Q5_PATH=token; Q5_MOUNT=/var/run/secrets/tokens

q_setup() {
  local d; d=$(labdir q05)
  kq create ns "$Q5_NS"
  kq delete sa "$Q5_SA" -n "$Q5_NS"
  k apply -f - >/dev/null <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $Q5_DEPLOY
  namespace: $Q5_NS
spec:
  replicas: 1
  selector:
    matchLabels: {app: $Q5_DEPLOY}
  template:
    metadata:
      labels: {app: $Q5_DEPLOY}
    spec:
      containers:
      - name: app
        image: busybox:1.36
        command: ["sh","-c","sleep 3600"]
EOF
  cat > "$d/TASK.md" <<EOF
In namespace "$Q5_NS":

1. Create a ServiceAccount "$Q5_SA" with automountServiceAccountToken: false

2. Edit Deployment "$Q5_DEPLOY" so that it:
   - uses ServiceAccount $Q5_SA
   - mounts that SA's token as a PROJECTED volume, readOnly, with:
         audience:          $Q5_AUD
         expirationSeconds: $Q5_EXP
         path:              $Q5_PATH
         mountPath:         $Q5_MOUNT
     => the token must end up at $Q5_MOUNT/$Q5_PATH

    kubectl --context $KCTX -n $Q5_NS edit deployment $Q5_DEPLOY

Reminder: 'path' is the FILE name inside mountPath, not a directory.

Grade with:  ./cks verify 5
EOF
  step "namespace/$Q5_NS + deployment/$Q5_DEPLOY ready; task in $d/TASK.md"
}

q_verify() {
  start_checks
  if ! k -n "$Q5_NS" get sa "$Q5_SA" >/dev/null 2>&1; then
    no "ServiceAccount $Q5_NS/$Q5_SA exists" "kubectl -n $Q5_NS create sa $Q5_SA"
  else
    ok "ServiceAccount $Q5_NS/$Q5_SA exists"
    local am; am=$(k -n "$Q5_NS" get sa "$Q5_SA" -o jsonpath='{.automountServiceAccountToken}')
    [ "$am" = "false" ] && ok "SA: automountServiceAccountToken=false" \
      || no "SA: automountServiceAccountToken=false" "got '${am:-<unset>}' (top-level field on the SA, not under spec)"
  fi

  if ! k -n "$Q5_NS" get deploy "$Q5_DEPLOY" >/dev/null 2>&1; then
    no "Deployment $Q5_DEPLOY exists" "./cks reset 5"; report; return
  fi
  local B='{.spec.template.spec}'
  local san; san=$(k -n "$Q5_NS" get deploy "$Q5_DEPLOY" -o jsonpath='{.spec.template.spec.serviceAccountName}')
  [ "$san" = "$Q5_SA" ] && ok "Deployment: serviceAccountName=$Q5_SA" \
    || no "Deployment: serviceAccountName=$Q5_SA" "got '${san:-<unset>}'"

  # find the projected serviceAccountToken source
  local proj aud exp pth
  proj=$(k -n "$Q5_NS" get deploy "$Q5_DEPLOY" -o json \
          | python3 -c '
import json,sys
d=json.load(sys.stdin)
for v in d["spec"]["template"]["spec"].get("volumes",[]):
    for s in (v.get("projected") or {}).get("sources",[]) or []:
        t=s.get("serviceAccountToken")
        if t:
            print(json.dumps({"vol":v["name"],"aud":t.get("audience"),
                              "exp":t.get("expirationSeconds"),"path":t.get("path")}));break' 2>/dev/null)
  if [ -z "$proj" ]; then
    no "Deployment: has a projected serviceAccountToken volume" \
       "volumes[].projected.sources[].serviceAccountToken"
    report; return
  fi
  ok "Deployment: has a projected serviceAccountToken volume"
  aud=$(printf '%s' "$proj" | python3 -c 'import json,sys;print(json.load(sys.stdin)["aud"] or "")')
  exp=$(printf '%s' "$proj" | python3 -c 'import json,sys;print(json.load(sys.stdin)["exp"] or "")')
  pth=$(printf '%s' "$proj" | python3 -c 'import json,sys;print(json.load(sys.stdin)["path"] or "")')
  local vol; vol=$(printf '%s' "$proj" | python3 -c 'import json,sys;print(json.load(sys.stdin)["vol"])')

  [ "$aud" = "$Q5_AUD" ] && ok "projection: audience=$Q5_AUD" || no "projection: audience=$Q5_AUD" "got '${aud}'"
  [ "$exp" = "$Q5_EXP" ] && ok "projection: expirationSeconds=$Q5_EXP" || no "projection: expirationSeconds=$Q5_EXP" "got '${exp}'"
  [ "$pth" = "$Q5_PATH" ] && ok "projection: path=$Q5_PATH" || no "projection: path=$Q5_PATH" "got '${pth}'"

  local mp ro
  mp=$(k -n "$Q5_NS" get deploy "$Q5_DEPLOY" -o jsonpath="{.spec.template.spec.containers[0].volumeMounts[?(@.name=='$vol')].mountPath}")
  ro=$(k -n "$Q5_NS" get deploy "$Q5_DEPLOY" -o jsonpath="{.spec.template.spec.containers[0].volumeMounts[?(@.name=='$vol')].readOnly}")
  [ "$mp" = "$Q5_MOUNT" ] && ok "volumeMount: mountPath=$Q5_MOUNT" || no "volumeMount: mountPath=$Q5_MOUNT" "got '${mp:-<unset>}'"
  [ "$ro" = "true" ] && ok "volumeMount: readOnly=true" || no "volumeMount: readOnly=true" "got '${ro:-<unset>}'"

  # runtime proof: the token file exists and its JWT carries aud + 3600s lifetime
  local po; po=$(ready_pod "$Q5_NS" "app=$Q5_DEPLOY" "$Q5_DEPLOY" 240s)
  if [ -n "$po" ] && k -n "$Q5_NS" wait --for=condition=Ready "$po" --timeout=120s >/dev/null 2>&1; then
    if k -n "$Q5_NS" exec "$po" -- cat "$Q5_MOUNT/$Q5_PATH" >/dev/null 2>&1; then
      ok "token file present at $Q5_MOUNT/$Q5_PATH in the running pod"
      local claims
      claims=$(k -n "$Q5_NS" exec "$po" -- cat "$Q5_MOUNT/$Q5_PATH" 2>/dev/null \
               | cut -d. -f2 | python3 -c '
import sys,base64,json
s=sys.stdin.read().strip(); s+="="*(-len(s)%4)
print(json.dumps(json.loads(base64.urlsafe_b64decode(s))))' 2>/dev/null)
      if printf '%s' "$claims" | grep -q "\"$Q5_AUD\""; then
        ok "token audience really is '$Q5_AUD'"
      else
        no "token audience really is '$Q5_AUD'" "claims: $claims"
      fi
      local life
      life=$(printf '%s' "$claims" | python3 -c 'import json,sys;d=json.load(sys.stdin);print(d["exp"]-d["iat"])' 2>/dev/null)
      [ "$life" = "$Q5_EXP" ] && ok "token lifetime really is ${Q5_EXP}s (exp-iat)" \
        || no "token lifetime really is ${Q5_EXP}s" "got '${life}'"
    else
      no "token file present at $Q5_MOUNT/$Q5_PATH in the running pod" \
         "mountPath + path must combine to this exact file"
    fi
    if k -n "$Q5_NS" exec "$po" -- ls /var/run/secrets/kubernetes.io/serviceaccount/ >/dev/null 2>&1; then
      no "default SA token is NOT auto-mounted" "automountServiceAccountToken: false is not taking effect"
    else
      ok "default SA token is NOT auto-mounted"
    fi
  else
    warn "pod not Ready, skipping runtime checks"
  fi
  report
}

q_solve() {
  k -n "$Q5_NS" apply -f - >/dev/null <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $Q5_SA
  namespace: $Q5_NS
automountServiceAccountToken: false
EOF
  k apply -f - >/dev/null <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $Q5_DEPLOY
  namespace: $Q5_NS
spec:
  replicas: 1
  selector:
    matchLabels: {app: $Q5_DEPLOY}
  template:
    metadata:
      labels: {app: $Q5_DEPLOY}
    spec:
      serviceAccountName: $Q5_SA
      volumes:
      - name: token-vol
        projected:
          sources:
          - serviceAccountToken:
              path: $Q5_PATH
              audience: $Q5_AUD
              expirationSeconds: $Q5_EXP
      containers:
      - name: app
        image: busybox:1.36
        command: ["sh","-c","sleep 3600"]
        volumeMounts:
        - name: token-vol
          mountPath: $Q5_MOUNT
          readOnly: true
EOF
}

q_reset() { kq delete deploy "$Q5_DEPLOY" -n "$Q5_NS"; kq delete sa "$Q5_SA" -n "$Q5_NS"; q_setup; }
