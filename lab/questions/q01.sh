Q_TITLE="Kubelet/apiserver/etcd hardening (webhook auth, NodeRestriction, client-cert-auth)"
Q_TAGS="cluster"

q_setup() {
  local d; d=$(labdir q01)
  backup_controlplane
  step "un-hardening the control plane so there is something to fix"

  # kubelet: enable anonymous, drop webhook authn, authorization -> AlwaysAllow
  kubelet_set_authn anonymous true
  kubelet_set_authn webhook false
  kubelet_set_authz_mode AlwaysAllow
  kubelet_restart

  # apiserver: remove the admission-plugins flag only.
  #
  # Deliberately NOT touching --authorization-mode. Every "insecure" value breaks
  # the cluster in a way that has nothing to teach:
  #   RBAC alone  -> the Node authorizer is gone, so the kubelet is denied
  #                  (system:node:... cannot list/get), static pods stop being
  #                  resynced and the lab deadlocks with no way back in.
  #   AlwaysAllow -> "AnonymousAuth is not allowed with the AlwaysAllow authorizer.
  #                  Resetting AnonymousAuth to false." The kubelet's liveness probe
  #                  is anonymous, so it gets 401 and the kubelet kills the API
  #                  server every ~90s, forever.
  #   ABAC/Webhook-> need a policy/config file; the API server will not start.
  # Only combinations of Node and RBAC are safe, i.e. the correct answer.
  #
  # That is fine, because the real trap in this task is not "set it from scratch",
  # it is "do not put NodeRestriction in there". The question presents the flag
  # correct and the grader checks you did not break it.
  mark_apiserver
  apiserver_edit rmflag --enable-admission-plugins
  # etcd: turn client cert auth off
  node_sh "sed -i 's|^\( *\)- --client-cert-auth=true|\1- --client-cert-auth=false|' $ETCD_MANIFEST" >/dev/null 2>&1

  settle_apiserver 60 || true

  cat > "$d/TASK.md" <<EOF
Harden this cluster. Work on the control-plane node:

    docker exec -it $NODE bash

1. Kubelet ($KUBELET_CONFIG)
   - disable anonymous authentication
   - enable webhook authentication
   - set the authorization mode to Webhook
   Then: systemctl restart kubelet

2. kube-apiserver ($APISERVER_MANIFEST)
   - enable the NodeRestriction admission plugin  (the flag has been removed)
   - ensure the authorization modes are Node and RBAC

   CAREFUL: --authorization-mode is already Node,RBAC and must STAY that way.
   The exam phrases this as \"RBAC + NodeRestriction authorization modes\", and if
   you take that literally and write --authorization-mode=RBAC,NodeRestriction the
   API server will not start: NodeRestriction is an ADMISSION PLUGIN, not an
   authorization mode. The grader checks both that Node and RBAC are present and
   that you did not put NodeRestriction among them.

3. etcd ($ETCD_MANIFEST)
   - require client certificate authentication

Grade with:  ./cks verify 1
EOF
  step "task written to $d/TASK.md"
}

q_verify() {
  start_checks
  local kc; kc=$(node_read "$KUBELET_CONFIG")

  # 1. kubelet
  if printf '%s' "$kc" | awk '/^authentication:/{f=1} /^authorization:/{f=0} f' | grep -A2 'anonymous:' | grep -q 'enabled: false'; then
    ok "kubelet: anonymous authentication disabled"
  else
    no "kubelet: anonymous authentication disabled" "authentication.anonymous.enabled: false in $KUBELET_CONFIG"
  fi

  if printf '%s' "$kc" | awk '/^authentication:/{f=1} /^authorization:/{f=0} f' | grep -A3 'webhook:' | grep -q 'enabled: true'; then
    ok "kubelet: webhook authentication enabled"
  else
    no "kubelet: webhook authentication enabled" "authentication.webhook.enabled: true"
  fi

  if printf '%s' "$kc" | awk '/^authorization:/{f=1} f' | grep -qE '^  mode: Webhook'; then
    ok "kubelet: authorization mode is Webhook"
  else
    no "kubelet: authorization mode is Webhook" "authorization.mode: Webhook"
  fi

  # the real end-state test: unauthenticated kubelet API must be rejected
  local code
  code=$(node_sh 'curl -sk -o /dev/null -w "%{http_code}" https://localhost:10250/pods' 2>/dev/null)
  if [ "$code" = "401" ] || [ "$code" = "403" ]; then
    ok "kubelet: anonymous request to :10250 rejected (HTTP $code)"
  else
    no "kubelet: anonymous request to :10250 rejected" "got HTTP '$code'; did you restart the kubelet?"
  fi

  # 2. apiserver
  local modes plugins
  modes=$(apiserver_flag --authorization-mode)
  plugins=$(apiserver_flag --enable-admission-plugins)

  if csv_has "$modes" Node && csv_has "$modes" RBAC; then
    ok "kube-apiserver: --authorization-mode contains Node and RBAC ($modes)"
  else
    no "kube-apiserver: --authorization-mode contains Node and RBAC" "got '$modes'; want e.g. Node,RBAC"
  fi
  if printf '%s' "$modes" | tr ',' '\n' | grep -qx NodeRestriction; then
    no "kube-apiserver: NodeRestriction NOT used as an authorization mode" \
       "NodeRestriction is an admission plugin; the API server refuses to start with it in --authorization-mode"
  else
    ok "kube-apiserver: NodeRestriction not misused as an authorization mode"
  fi
  if csv_has "$plugins" NodeRestriction; then
    ok "kube-apiserver: NodeRestriction admission plugin enabled ($plugins)"
  else
    no "kube-apiserver: NodeRestriction admission plugin enabled" "--enable-admission-plugins=NodeRestriction"
  fi
  if k get --raw /healthz >/dev/null 2>&1; then
    ok "kube-apiserver: up and healthy"
  else
    no "kube-apiserver: up and healthy" "run ./cks doctor"
  fi

  # 3. etcd
  if [ "$(etcd_flag --client-cert-auth)" = "true" ]; then
    ok "etcd: --client-cert-auth=true"
  else
    no "etcd: --client-cert-auth=true" "got '$(etcd_flag --client-cert-auth)' in $ETCD_MANIFEST"
  fi
  report
}

q_solve() {
  kubelet_set_authn anonymous false
  kubelet_set_authn webhook true
  kubelet_set_authz_mode Webhook
  kubelet_restart
  mark_apiserver
  apiserver_edit_multi "setflag --enable-admission-plugins NodeRestriction"
  node_sh "sed -i 's|^\\( *\\)- --client-cert-auth=false|\\1- --client-cert-auth=true|' $ETCD_MANIFEST" >/dev/null 2>&1
  settle_apiserver 60 || true
}
