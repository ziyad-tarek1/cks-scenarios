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

NOTE 1: contrary to what most write-ups claim, kubectl keeps working after this
change -- your kubeconfig uses a client certificate, which is NOT anonymous.

NOTE 2 (important for this lab): kubeadm's liveness/readiness probes hit /livez
and /readyz ANONYMOUSLY, so they now get 401. The pod first shows 0/1 NotReady,
and then -- after failureThreshold x period, about 90s -- the kubelet KILLS the
container as unhealthy and restarts it, forever. The API server becomes
intermittently unreachable, which breaks the other questions.

That is genuinely what this flag does on a kubeadm cluster, so the task is left
faithful. But when you are done here, run:

    ./cks reset 2

to take the flag back off and make the cluster stable again.

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

  # Passing this question leaves the control plane crash-looping, because the
  # kubelet's probes are anonymous and now get 401. Say so loudly -- otherwise
  # every other question starts failing for no visible reason.
  if [ "$(apiserver_flag --anonymous-auth)" = "false" ]; then
    printf '\n'
    warn "the API server is now being killed by its own liveness probe (anonymous -> 401)"
    warn "it will restart every ~90s for as long as this flag is set"
    warn "when you are finished with q02, run:   ./cks reset 2"
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
