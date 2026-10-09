Q_TITLE="Enable ImagePolicyWebhook admission control (defaultAllow: false)"
Q_TAGS="cluster"
Q13_DIR=/etc/kubernetes/imagepolicy
Q13_CFG="$Q13_DIR/imagepolicyfile.yaml"
Q13_KUBECONF="$Q13_DIR/kube.conf"
Q13_SERVER="https://image-bouncer-webhook.default.svc:1323/image_policy"

q_setup() {
  local d; d=$(labdir q13)
  backup_controlplane
  step "clearing any existing ImagePolicyWebhook configuration"
  mark_apiserver
  # Remove ONLY ImagePolicyWebhook from the plugin list and keep whatever else is
  # there. Previously this reset the list to "NodeRestriction", which silently
  # undid q01's un-hardening (q01 removes the flag entirely) -- so after a full
  # `./cks setup`, q01 looked partly solved before you had touched anything.
  local cur rest
  cur=$(apiserver_flag --enable-admission-plugins)
  rest=$(printf '%s' "$cur" | tr ',' '\n' | grep -v '^ImagePolicyWebhook$' | grep -v '^$' | paste -sd, -)
  if [ -n "$rest" ]; then
    apiserver_edit_multi \
      "rmflag --admission-control-config-file" \
      "setflag --enable-admission-plugins $rest" \
      "rmvol imagepolicy"
  else
    apiserver_edit_multi \
      "rmflag --admission-control-config-file --enable-admission-plugins" \
      "rmvol imagepolicy"
  fi
  printf '%s' "$rest" > "$d/.baseline_plugins"
  node_sh "mkdir -p $Q13_DIR" >/dev/null 2>&1
  settle_apiserver 60 || true

  # seed kube.conf with a PLACEHOLDER server the candidate must correct
  node_write "$Q13_KUBECONF" <<'EOF'
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://CHANGE-ME.example.com:443
    insecure-skip-tls-verify: true
  name: image-policy-cluster
contexts:
- context:
    cluster: image-policy-cluster
    user: image-bot
  name: image-policy-context
current-context: image-policy-context
users:
- name: image-bot
  user:
    token: dummy-token
EOF
  cat > "$d/test-rc.yaml" <<'EOF'
apiVersion: v1
kind: ReplicationController
metadata:
  name: test-rc
  namespace: default
spec:
  replicas: 1
  selector:
    app: test-rc
  template:
    metadata:
      labels:
        app: test-rc
    spec:
      containers:
      - name: c
        image: nginx:1.27
EOF
  kq delete rc test-rc
  cat > "$d/TASK.md" <<EOF
Enable the ImagePolicyWebhook admission controller.

    ssh $NODE            # like the exam  (./cks ssh  also works)

1. Create the admission config at:
       $Q13_CFG
   It must reference the kubeconfig at $Q13_KUBECONF
   and set defaultAllow to FALSE.

   CAREFUL: this file is NOT 'kind: ImagePolicyWebhook'. That is rejected and the
   API server will not start. It must be an AdmissionConfiguration
   (apiVersion: apiserver.config.k8s.io/v1) with a plugins: list.

2. In $Q13_KUBECONF , set the webhook server URL to exactly:
       $Q13_SERVER

3. Enable the plugin in $APISERVER_MANIFEST :
       --enable-admission-plugins=NodeRestriction,ImagePolicyWebhook
       --admission-control-config-file=$Q13_CFG
   ...plus a hostPath volume + volumeMount for $Q13_DIR
   (same trap as the audit task -- kubeadm only mounts /etc/kubernetes/pki).

4. Test with the provided ReplicationController:
       kubectl --context $KCTX apply -f $d/test-rc.yaml
   The RC WILL be created. The POD will be rejected. Check 'describe rc'.

If kubectl dies:  ./cks doctor      To start over:  ./cks reset 13

Grade with:  ./cks verify 13
EOF
  step "kube.conf seeded with a placeholder; task in $d/TASK.md"
}

q_verify() {
  start_checks
  # --- flags ---
  local plugins acf
  plugins=$(apiserver_flag --enable-admission-plugins)
  acf=$(apiserver_flag --admission-control-config-file)
  csv_has "$plugins" ImagePolicyWebhook && ok "--enable-admission-plugins includes ImagePolicyWebhook" \
    || no "--enable-admission-plugins includes ImagePolicyWebhook" "got '${plugins:-<unset>}'"
  # Enforce "append, don't replace" against whatever the flag held when this
  # question was seeded -- which depends on whether q01 is also set up.
  local base missing pl
  base=$(cat "$LAB/q13/.baseline_plugins" 2>/dev/null)
  if [ -z "$base" ]; then
    ok "no pre-existing admission plugins to preserve"
  else
    missing=""
    for pl in $(printf '%s' "$base" | tr ',' ' '); do
      csv_has "$plugins" "$pl" || missing="$missing $pl"
    done
    if [ -z "$missing" ]; then
      ok "pre-existing admission plugins preserved ($base)"
    else
      no "pre-existing admission plugins preserved ($base)" \
         "lost:$missing -- append to the existing flag, don't replace it"
    fi
  fi
  [ "$acf" = "$Q13_CFG" ] && ok "--admission-control-config-file=$Q13_CFG" \
    || no "--admission-control-config-file=$Q13_CFG" "got '${acf:-<unset>}'"
  apiserver_mounts "$Q13_DIR" && ok "volumeMount for $Q13_DIR present" \
    || no "volumeMount for $Q13_DIR present" "static pods only see what is mounted in"

  # --- config file shape ---
  local cfg; cfg=$(node_read "$Q13_CFG")
  if [ -z "$cfg" ]; then
    no "admission config exists at $Q13_CFG" "create it on the node"
  else
    ok "admission config exists at $Q13_CFG"
    if printf '%s' "$cfg" | grep -q 'kind: AdmissionConfiguration'; then
      ok "config kind is AdmissionConfiguration"
    else
      no "config kind is AdmissionConfiguration" \
         "'kind: ImagePolicyWebhook' is NOT accepted: 'no kind \"ImagePolicyWebhook\" is registered'"
    fi
    printf '%s' "$cfg" | grep -q 'apiserver.config.k8s.io/v1' \
      && ok "config apiVersion is apiserver.config.k8s.io/v1" \
      || no "config apiVersion is apiserver.config.k8s.io/v1" "not imagepolicy.k8s.io/v1alpha1"
    printf '%s' "$cfg" | grep -q 'name: ImagePolicyWebhook' \
      && ok "plugins list names ImagePolicyWebhook" || no "plugins list names ImagePolicyWebhook"
    printf '%s' "$cfg" | grep -qE 'defaultAllow: *false' \
      && ok "defaultAllow: false" || no "defaultAllow: false" "requirement 3"
    printf '%s' "$cfg" | grep -q "$Q13_KUBECONF" \
      && ok "config references $Q13_KUBECONF" || no "config references $Q13_KUBECONF" "kubeConfigFile: must be the full path"
  fi

  # --- webhook URL ---
  local kc; kc=$(node_read "$Q13_KUBECONF")
  if printf '%s' "$kc" | grep -qF "$Q13_SERVER"; then
    ok "kube.conf server URL is exactly the required one"
  else
    local got; got=$(printf '%s' "$kc" | sed -n 's|.*server: *\(.*\)|\1|p' | head -1)
    no "kube.conf server URL is exactly the required one" "got '${got:-<none>}', want '$Q13_SERVER'"
  fi

  # --- API server survived ---
  if k get --raw /healthz >/dev/null 2>&1; then
    ok "kube-apiserver is healthy after the change"
  else
    no "kube-apiserver is healthy after the change" "./cks doctor -- usually a bad config kind or a missing mount"
    report; return
  fi

  # --- behaviour: pods must be denied by the (unreachable) webhook ---
  local out
  out=$(k run ipw-probe --image=nginx:1.27 --dry-run=server 2>&1)
  if printf '%s' "$out" | grep -qi 'forbidden'; then
    ok "pod creation is denied by the webhook (defaultAllow: false working)"
    printf '%s' "$out" | grep -qi 'image-bouncer-webhook' \
      && ok "denial message references the configured webhook URL" \
      || no "denial message references the configured webhook URL" "the plugin may be reading a different kubeconfig"
  else
    no "pod creation is denied by the webhook" \
       "server-side dry-run was admitted -- plugin not active or defaultAllow is true"
  fi
  kq delete po ipw-probe
  report
}

q_solve() {
  node_sh "mkdir -p $Q13_DIR" >/dev/null
  node_write "$Q13_CFG" <<EOF
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  configuration:
    imagePolicy:
      kubeConfigFile: $Q13_KUBECONF
      allowTTL: 50
      denyTTL: 50
      retryBackoff: 500
      defaultAllow: false
EOF
  mark_apiserver
  node_sh "sed -i 's|server: .*|server: $Q13_SERVER|' $Q13_KUBECONF" >/dev/null 2>&1
  mark_apiserver
  local cur want
  cur=$(apiserver_flag --enable-admission-plugins)
  if [ -n "$cur" ]; then
    printf '%s' "$cur" | tr ',' '\n' | grep -qx ImagePolicyWebhook \
      && want="$cur" || want="$cur,ImagePolicyWebhook"
  else
    want="ImagePolicyWebhook"
  fi
  apiserver_edit_multi \
    "setflag --enable-admission-plugins $want" \
    "setflag --admission-control-config-file $Q13_CFG" \
    "addvol imagepolicy $Q13_DIR $Q13_DIR true"
  settle_apiserver 60 || true
}

# Surgical: only undoes THIS question, so q9's audit setup survives.
q_reset() { kq delete rc test-rc; q_setup; }
