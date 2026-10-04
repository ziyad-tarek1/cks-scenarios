Q_TITLE="Disable anonymous-auth in kube-apiserver + delete a ClusterRole"
Q_TAGS="cluster"
Q2_CR="system:user"

q_setup() {
  local d; d=$(labdir q02)
  backup_controlplane
  step "seeding ClusterRole $Q2_CR"
  k create clusterrole "$Q2_CR" --verb=get,list --resource=pods \
    --dry-run=client -o yaml | k apply -f - >/dev/null
  step "ensuring --anonymous-auth is not already set"
  mark_apiserver
  node_sh "sed -i '\|--anonymous-auth=|d' $APISERVER_MANIFEST" >/dev/null 2>&1
  settle_apiserver 60 || true

  # a candidate kubeconfig, like the exam hands you
  k config view --raw --minify --context "$KCTX" > "$d/kubeconfig" 2>/dev/null
  node_sh 'mkdir -p /root/candidate && cp /etc/kubernetes/admin.conf /root/candidate/kubeconfig' >/dev/null 2>&1

  cat > "$d/TASK.md" <<EOF
1. Configure kube-apiserver to reject anonymous requests.
       docker exec -it $NODE bash
       vi $APISERVER_MANIFEST

2. Delete the ClusterRole "$Q2_CR" using the provided kubeconfig:
       on the node : /root/candidate/kubeconfig
       on your host: $d/kubeconfig

NOTE: contrary to what most write-ups claim, kubectl keeps working after this
change (your kubeconfig uses a client certificate, which is NOT anonymous).
What DOES change: the kube-apiserver static pod goes 0/1 NotReady, because
kubeadm's liveness/readiness probes are anonymous and now get 401. That is the
expected end state -- do not "fix" it.

Grade with:  ./cks verify 2
EOF
  step "task written to $d/TASK.md"
}

q_verify() {
  start_checks
  local v; v=$(apiserver_flag --anonymous-auth)
  if [ "$v" = "false" ]; then
    ok "kube-apiserver: --anonymous-auth=false present in the manifest"
  else
    no "kube-apiserver: --anonymous-auth=false present in the manifest" "got '${v:-<unset>}'"
  fi

  # end-state test: an unauthenticated request must be refused
  local code
  code=$(node_sh 'curl -sk -o /dev/null -w "%{http_code}" https://localhost:6443/version' 2>/dev/null)
  if [ "$code" = "401" ]; then
    ok "anonymous request to :6443/version rejected (HTTP 401)"
  else
    no "anonymous request to :6443/version rejected" "got HTTP '$code' (200 means anonymous access still works)"
  fi

  # authenticated access must still work -- proves they didn't break RBAC/certs
  if k get nodes >/dev/null 2>&1; then
    ok "authenticated kubectl still works (as it should)"
  else
    no "authenticated kubectl still works" "you broke more than anonymous-auth; ./cks doctor"
  fi

  if k get clusterrole "$Q2_CR" >/dev/null 2>&1; then
    no "ClusterRole '$Q2_CR' deleted" "kubectl delete clusterrole $Q2_CR"
  else
    ok "ClusterRole '$Q2_CR' deleted"
  fi
  report
}

q_solve() {
  mark_apiserver
  node_sh "grep -q -- '--anonymous-auth=false' $APISERVER_MANIFEST || \
           sed -i '/- --authorization-mode=/a\\    - --anonymous-auth=false' $APISERVER_MANIFEST" >/dev/null 2>&1
  settle_apiserver 60 || true
  kq delete clusterrole "$Q2_CR" || true
}

q_reset() {
  mark_apiserver
  node_sh "sed -i '\|--anonymous-auth=|d' $APISERVER_MANIFEST" >/dev/null 2>&1
  settle_apiserver 60 || true
  q_setup
}
