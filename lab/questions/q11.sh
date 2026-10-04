Q_TITLE="kubeadm node upgrade (command-plan drill)"
Q_TAGS="files"
Q11_VER="1.34.1"
# kind nodes do not install kubelet/kubeadm via apt, so a real in-place upgrade
# is not reproducible here. This is a written drill: you produce the exact
# command sequence, and the grader lints it for the mistakes that cost marks.

q_setup() {
  local d; d=$(labdir q11)
  cat > "$d/plan.sh" <<EOF
#!/usr/bin/env bash
# TASK: upgrade worker node 'compute-0' to Kubernetes v$Q11_VER
#
# Write the full command sequence below, in the order you would run it.
# Use the version v$Q11_VER consistently throughout.
# Assume you start from a machine with kubectl, and can 'ssh compute-0'.
#
# The grader checks for: cordon/drain, apt-mark unhold/hold, installing kubeadm
# first, 'kubeadm upgrade node' (NOT 'apply') for a worker, kubelet restart,
# uncordon, and a consistent version string.

EOF
  cat > "$d/TASK.md" <<EOF
Write your upgrade command plan into:

    $d/plan.sh

Target version: v$Q11_VER   (use it consistently -- a version mismatch between
the question and your commands is the most common error in this task)

Worker node name: compute-0

Why this is a written drill: kind nodes ship their kubelet/kubeadm binaries
directly rather than through apt, so 'apt-get install kubeadm=...' cannot be
exercised here. Everything else about the task is gradeable, and the grader
checks the ordering and the two things people forget.

Grade with:  ./cks verify 11
EOF
  step "write your plan in $d/plan.sh"
}

q_verify() {
  start_checks
  local f="$LAB/q11/plan.sh"
  [ -f "$f" ] || { no "plan.sh exists" "./cks reset 11"; report; return; }
  local body; body=$(grep -vE '^\s*#' "$f")
  if [ -z "$(printf '%s' "$body" | tr -d '[:space:]')" ]; then
    no "plan.sh contains commands" "write your command sequence in $f"; report; return
  fi
  ok "plan.sh contains commands"

  has() { printf '%s' "$body" | grep -qiE "$1"; }

  has 'kubectl +(drain|.*drain)' && ok "drains the node before upgrading" \
    || no "drains the node before upgrading" "kubectl drain compute-0 --ignore-daemonsets"
  has 'ignore-daemonsets' && ok "drain uses --ignore-daemonsets" \
    || no "drain uses --ignore-daemonsets" "drain fails on DaemonSet pods without it"
  has 'apt-mark +unhold' && ok "unholds packages before installing" \
    || no "apt-mark unhold" "sudo apt-mark unhold kubeadm"
  has 'apt-mark +hold' && ok "re-holds packages after installing" \
    || no "re-holds packages after installing (apt-mark hold)" \
         "without this the next 'apt upgrade' silently moves you off the pinned version"
  has 'install.*kubeadm' && ok "installs the new kubeadm" || no "installs the new kubeadm"
  has 'kubeadm +upgrade +node' && ok "uses 'kubeadm upgrade node' (correct for a worker)" \
    || no "uses 'kubeadm upgrade node'" "'kubeadm upgrade apply' is for the FIRST control-plane node only"
  if has 'kubeadm +upgrade +apply'; then
    no "does not use 'kubeadm upgrade apply' on a worker" "that subcommand is for the first control-plane node"
  else
    ok "does not use 'kubeadm upgrade apply' on a worker"
  fi
  has 'install.*kubelet' && ok "installs the new kubelet" || no "installs the new kubelet"
  has 'daemon-reload' && ok "runs systemctl daemon-reload" || no "runs systemctl daemon-reload"
  has 'restart +kubelet' && ok "restarts the kubelet" || no "restarts the kubelet"
  has 'uncordon' && ok "uncordons the node at the end" || no "uncordons the node at the end" "kubectl uncordon compute-0"

  # ordering: kubeadm installed before 'kubeadm upgrade node'
  local l_install l_upgrade
  l_install=$(printf '%s\n' "$body" | grep -niE 'install.*kubeadm' | head -1 | cut -d: -f1)
  l_upgrade=$(printf '%s\n' "$body" | grep -niE 'kubeadm +upgrade +node' | head -1 | cut -d: -f1)
  if [ -n "$l_install" ] && [ -n "$l_upgrade" ] && [ "$l_install" -lt "$l_upgrade" ]; then
    ok "installs kubeadm BEFORE running 'kubeadm upgrade node'"
  else
    no "installs kubeadm BEFORE running 'kubeadm upgrade node'" "order matters"
  fi
  # version consistency
  local vers
  vers=$(printf '%s' "$body" | grep -oE '1\.[0-9]+\.[0-9]+' | sort -u)
  local nvers; nvers=$(printf '%s' "$vers" | grep -c . || true)
  if [ "$nvers" -le 1 ] && printf '%s' "$vers" | grep -qx "$Q11_VER"; then
    ok "uses the target version v$Q11_VER consistently"
  elif [ "$nvers" -gt 1 ]; then
    no "uses ONE version consistently" "found: $(printf '%s' "$vers" | tr '\n' ' ')"
  else
    no "uses the target version v$Q11_VER" "found: $(printf '%s' "$vers" | tr '\n' ' ')"
  fi
  report
}

q_solve() {
  local d; d=$(labdir q11)
  cat > "$d/plan.sh" <<EOF
#!/usr/bin/env bash
# Reference plan: upgrade worker 'compute-0' to v$Q11_VER
V=$Q11_VER

# --- from a machine with kubectl ---
kubectl drain compute-0 --ignore-daemonsets --delete-emptydir-data

# --- on compute-0 (ssh compute-0) ---
# If crossing a MINOR version, repoint the apt repo first:
#   sudo sed -i 's|v1\.33|v1.34|' /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update

sudo apt-mark unhold kubeadm
sudo apt-get install -y kubeadm="\$V-*"
sudo apt-mark hold kubeadm
kubeadm version -o short

sudo kubeadm upgrade node          # worker / secondary CP node
# first control-plane node would instead be:
#   sudo kubeadm upgrade plan && sudo kubeadm upgrade apply v\$V

sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet="\$V-*" kubectl="\$V-*"
sudo apt-mark hold kubelet kubectl

sudo systemctl daemon-reload
sudo systemctl restart kubelet

# --- back on the machine with kubectl ---
kubectl uncordon compute-0
kubectl get nodes
EOF
}
