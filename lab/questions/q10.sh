Q_TITLE="Docker daemon hardening (remove user from docker group, unix socket only)"
Q_TAGS="files host"
# The host here is macOS, so we practise on a faithful copy of the three files a
# real Docker host has, and validate the config with a real dockerd --validate.

q_setup() {
  local d; d=$(labdir q10)
  cat > "$d/daemon.json" <<'EOF'
{
  "hosts": [
    "tcp://0.0.0.0:2375",
    "unix:///var/run/docker.sock"
  ],
  "log-level": "info"
}
EOF
  cat > "$d/docker.service" <<'EOF'
[Unit]
Description=Docker Application Container Engine
After=network-online.target docker.socket
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock
ExecReload=/bin/kill -s HUP $MAINPID
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  cat > "$d/group" <<'EOF'
root:x:0:
sudo:x:27:developer
docker:x:999:developer,ci-bot
users:x:100:developer
EOF
  cat > "$d/TASK.md" <<EOF
Harden the Docker daemon. Edit these files in $d :

    daemon.json      (stands in for /etc/docker/daemon.json)
    docker.service   (stands in for /lib/systemd/system/docker.service)
    group            (stands in for /etc/group)

1. Remove user "developer" from the "docker" group  (edit group)
   Leave the other members and the other groups alone.

2. Docker must NOT listen on TCP anywhere. Remove TCP from wherever it is set.

3. Docker must listen ONLY on the unix socket /var/run/docker.sock

TRAP: if 'hosts' stays in daemon.json AND '-H' stays in ExecStart, dockerd
refuses to start -- even when both values are identical. Configure the socket in
exactly ONE of the two places. The grader runs a real 'dockerd --validate'
against your files.

Verification note: 'ss -ltnp | grep dockerd' must print NOTHING (-t is TCP only;
a unix socket can never appear there). Use 'ss -lxp | grep docker.sock' instead.

Grade with:  ./cks verify 10
EOF
  step "sandbox files written to $d"
}

q_verify() {
  start_checks
  local d="$LAB/q10" dj="$LAB/q10/daemon.json" svc="$LAB/q10/docker.service" grp="$LAB/q10/group"
  for f in "$dj" "$svc" "$grp"; do
    [ -f "$f" ] || { no "$(basename "$f") exists" "./cks reset 10"; report; return; }
  done

  # 1. group membership
  local line
  line=$(grep '^docker:' "$grp" 2>/dev/null)
  if [ -z "$line" ]; then
    no "'docker' group still exists in group file" "don't delete the group, just the member"
  elif printf '%s' "$line" | awk -F: '{print $4}' | tr ',' '\n' | grep -qx 'developer'; then
    no "user 'developer' removed from the 'docker' group" "gpasswd -d developer docker  ->  $line"
  else
    ok "user 'developer' removed from the 'docker' group"
    printf '%s' "$line" | awk -F: '{print $4}' | tr ',' '\n' | grep -qx 'ci-bot' \
      && ok "other docker group members left intact (ci-bot)" \
      || no "other docker group members left intact (ci-bot)" "you removed more than asked"
  fi
  grep -q '^sudo:x:27:developer$' "$grp" \
    && ok "developer's other group memberships untouched" \
    || no "developer's other group memberships untouched" "only the docker group should change"

  # 2/3. no TCP anywhere
  if grep -qE 'tcp://' "$dj"; then
    no "daemon.json has no tcp:// listener" "remove the tcp entry from hosts"
  else
    ok "daemon.json has no tcp:// listener"
  fi
  if grep -E '^ExecStart=' "$svc" | grep -qE 'tcp://'; then
    no "docker.service ExecStart has no tcp:// listener" "strip '-H tcp://...' from ExecStart"
  else
    ok "docker.service ExecStart has no tcp:// listener"
  fi
  # the unix socket must be configured exactly once, somewhere
  local in_json=0 in_svc=0
  grep -q '"hosts"' "$dj" && in_json=1
  grep -E '^ExecStart=' "$svc" | grep -q -- '-H' && in_svc=1
  if [ "$in_json" -eq 1 ] && [ "$in_svc" -eq 1 ]; then
    no "socket configured in exactly ONE place (daemon.json XOR ExecStart -H)" \
       "both set => dockerd exits: 'the following directives are specified both as a flag and in the configuration file: hosts'"
  elif [ "$in_json" -eq 0 ] && [ "$in_svc" -eq 0 ]; then
    no "the unix socket is configured somewhere" "set hosts in daemon.json OR -H in ExecStart"
  else
    ok "socket configured in exactly ONE place (daemon.json XOR ExecStart -H)"
  fi
  if grep -q 'unix:///var/run/docker.sock' "$dj" || grep -E '^ExecStart=' "$svc" | grep -q 'unix:///var/run/docker.sock'; then
    ok "unix:///var/run/docker.sock is the configured listener"
  else
    no "unix:///var/run/docker.sock is the configured listener" "that exact path is required"
  fi
  grep -qE '^\s*\{' "$dj" && python3 -c "import json,sys;json.load(open('$dj'))" >/dev/null 2>&1 \
    && ok "daemon.json is valid JSON" \
    || no "daemon.json is valid JSON" "a trailing comma after removing the tcp entry is the usual cause"

  # real dockerd --validate against the candidate's own files
  if docker info >/dev/null 2>&1; then
    local args out
    args=$(grep -E '^ExecStart=' "$svc" | head -1 | sed 's|^ExecStart=[^ ]*||')
    out=$(docker run --rm -v "$dj:/etc/docker/daemon.json:ro" --entrypoint sh docker:dind \
            -c "dockerd --validate $args 2>&1" 2>/dev/null | tail -3)
    if printf '%s' "$out" | grep -qi 'specified both as a flag and in the configuration file'; then
      no "real 'dockerd --validate' accepts your config" "$(printf '%s' "$out" | tail -1)"
    elif printf '%s' "$out" | grep -qiE 'configuration OK|^$'; then
      ok "real 'dockerd --validate' accepts your config"
    else
      # dockerd prints nothing on success in some versions
      if printf '%s' "$out" | grep -qiE 'error|fatal|unable'; then
        no "real 'dockerd --validate' accepts your config" "$(printf '%s' "$out" | tail -1)"
      else
        ok "real 'dockerd --validate' accepts your config"
      fi
    fi
  else
    warn "Docker not available, skipping the live dockerd --validate check"
  fi
  report
}

q_solve() {
  local d; d=$(labdir q10)
  cat > "$d/daemon.json" <<'EOF'
{
  "log-level": "info"
}
EOF
  sed -i.bak 's|^ExecStart=.*|ExecStart=/usr/bin/dockerd -H unix:///var/run/docker.sock|' "$d/docker.service"
  sed -i.bak 's|^docker:x:999:developer,ci-bot$|docker:x:999:ci-bot|' "$d/group"
  rm -f "$d"/*.bak
}
