# CKS Practice Lab — How to Use It

A local lab that turns the 16 scenarios in `../q1.md` … `../q16.md` into hands-on
exercises with an exam-style grader. You get a task, you do the work, and `./cks
verify` tells you whether you'd have scored the point.

It runs on **kind**, which is a real kubeadm cluster — so `/etc/kubernetes/manifests`,
etcd, and the kubelet config are genuine, and the control-plane questions are solved
the same way as in the real exam (including breaking the API server when you get it
wrong).

---

## 1. One-time setup

### Install the tools

Required for everything:

```bash
brew install kind kubectl
```

Docker must be installed **and running** (Docker Desktop). Check:

```bash
docker info >/dev/null && echo "docker ok"
```

Required only for specific questions — install now or when you reach them:

| Tool | Needed by | Install |
|---|---|---|
| `bom`, `trivy` | q15 (SBOM reports) | `brew install bom trivy` |
| `istioctl` | q16 (mTLS) | `brew install istioctl` |
| `openssl` | q07, q12 (certs) | already on macOS |

Nothing to install for Falco (q14) — it runs from a container image on demand.
`ingress-nginx` (q12) and Istio (q16) are installed **into the cluster** for you the
first time you set those questions up.

Works with the stock macOS bash 3.2. No `sudo` needed anywhere.

### Build the lab

```bash
cd lab
./cks setup
```

That creates the kind cluster and seeds all 16 questions. **The first run takes
roughly 10–15 minutes** — it pulls the node image, nginx/httpd/redis/busybox/netshoot/
alpine images, and installs ingress-nginx and Istio. Later runs reuse all of it.

In a hurry? Seed only what you want:

```bash
./cks setup 8          # one question
./cks setup 1 2 9 13   # just the control-plane ones (fast, no add-ons)
```

---

## 2. The core loop

Four commands, repeated per question:

```bash
./cks task 8       # 1. read the task
                   # 2. do the work (kubectl, vi, docker exec ...)
./cks verify 8     # 3. get graded
./cks reset 8      # 4. wipe it and try again
```

### Step 1 — read the task

```bash
$ ./cks task 8

q08 — Make a Deployment comply with restricted Pod Security Admission
Namespace "confidential" enforces the 'restricted' Pod Security Standard:

    kubectl --context kind-cks get ns confidential --show-labels

Deployment "psa-app" has TWO containers and currently creates no pods at all,
because every pod it tries to create is rejected. Fix it so the pods run.
...
Grade with:  ./cks verify 8
```

The same text is saved at `~/cks-lab/q08/TASK.md` if you'd rather read it in an editor.

### Step 2 — do the work

Everything in the lab lives in the `kind-cks` kubectl context. Easiest is to select
it once for your shell:

```bash
kubectl config use-context kind-cks
kubectl -n confidential edit deployment psa-app
```

Or pass it explicitly each time (what the task text shows, so it's unambiguous):

```bash
kubectl --context kind-cks -n confidential edit deployment psa-app
```

For the control-plane questions (q01, q02, q09, q13) you work **on the node**, exactly
like the exam:

```bash
docker exec -it cks-control-plane bash

# inside:
vi /etc/kubernetes/manifests/kube-apiserver.yaml
vi /var/lib/kubelet/config.yaml
systemctl restart kubelet
crictl ps -a --name kube-apiserver        # when kubectl is dead
```

### Step 3 — get graded

```bash
$ ./cks verify 8

q08 — Make a Deployment comply with restricted Pod Security Admission
  PASS namespace confidential still enforces 'restricted' (you didn't cheat by relabelling)
  PASS both containers still present
  FAIL container 'c1': allowPrivilegeEscalation=false
       hint: container-level only; got '<unset>'
  FAIL container 'c1': seccompProfile.type is RuntimeDefault or Localhost
       hint: THIS is the one everyone forgets -- got '<unset>'
  ...
  RESULT: FAIL  (2/12 criteria met)
  Re-run a single question:  ./cks verify 08
```

Every failure carries a hint pointing at the actual mistake. Fix, re-run, repeat
until `RESULT: PASS`.

### Step 4 — try again, or move on

```bash
./cks reset 8      # back to the unsolved starting state
./cks setup 9      # next question
```

---

## 3. Command reference

| Command | What it does |
|---|---|
| `./cks setup [N...]` | Create the cluster if needed, then seed the question(s). No args = all 16. Running it on an already-seeded question **re-seeds** it (same as `reset`). |
| `./cks task N [N...]` | Print the task statement(s). |
| `./cks verify [N...]` | Grade. No args = all 16, with a combined total at the end. Exit code is 0 only if everything passed, so it's scriptable. |
| `./cks reset N...` | Re-seed the question, discarding your work. Requires an explicit number — there's no "reset everything" by accident. |
| `./cks solve N...` | Apply the reference solution. For studying or comparing against your own answer. |
| `./cks list` | Every question, its title, and whether it's seeded. |
| `./cks doctor` | Diagnose a broken cluster: node status, control-plane pods, API health, and the real error from the container or kubelet. |
| `./cks restore` | Put the control-plane manifests and kubelet config back to known-good. Your rescue hatch. |
| `./cks clean` | Delete the kind cluster **and** `~/cks-lab`. |
| `./cks clean --keep-files` | Delete the cluster, keep your working files. |
| `./cks --help` | The above, briefly. |

Question numbers accept `8`, `08` or `q8`. Aliases: `check` and `grade` = `verify`,
`ls` = `list`, `destroy` = `clean`.

### Environment variables

```bash
CKS_LAB_DIR=~/somewhere                 # working files   (default ~/cks-lab)
CKS_CLUSTER=cks                         # kind cluster    (default cks)
CKS_NODE_IMAGE=kindest/node:v1.34.0     # pin the Kubernetes version
```

---

## 4. Recipes for every use case

### "I've never run this before"

```bash
cd lab
./cks setup            # ~10-15 min the first time
./cks list             # see what you've got
./cks task 4           # start with an easy one
```

### "I want to practise one question"

```bash
./cks setup 6 && ./cks task 6
#   ... work ...
./cks verify 6
```

### "I want a full timed mock exam"

The real CKS is **2 hours**. Seed everything, then time yourself:

```bash
./cks setup                       # do this the day before; it's slow
./cks reset 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16    # fresh start
date                              # note the time, give yourself 2h
#   ... work through them; ./cks task N for each ...
./cks verify                      # one grade for all 16 at the end
```

Finish with the per-question breakdown:

```bash
./cks verify 2>&1 | grep -E '^q[0-9]|RESULT'
```

### "I only want the control-plane questions"

The ones where you edit static pod manifests on the node, and where a mistake
takes the API server down. No add-ons, so this is a quick setup:

```bash
./cks setup 1 2 9 13
```

### "I only want the quick YAML questions"

```bash
./cks setup 3 4 5 7 8
```

### "I'm stuck — show me the answer"

```bash
./cks solve 9          # applies the reference solution
./cks verify 9         # confirm it passes
```

To study the diff instead of just the result, look at what `solve` did:

```bash
# for a cluster object
kubectl --context kind-cks -n confidential get deploy psa-app -o yaml

# for a node file
docker exec cks-control-plane cat /etc/kubernetes/audit/audit.yaml
```

Then `./cks reset 9` and do it yourself from memory.

### "I solved it — let me try again from scratch"

```bash
./cks reset 9
```

### "I broke the API server"

Expected on q01, q02, q09 and q13 — it's how the exam punishes a bad manifest.
`kubectl` will say `Unable to connect to the server: EOF`.

```bash
./cks doctor           # shows the real error from the container / kubelet
./cks restore          # back to known-good control-plane manifests
```

`doctor` reads the error from inside the node, which is the only place it exists
when the API server is down. `restore` also restarts the kubelet, which is what
reliably recovers a static pod the kubelet has given up on.

If `restore` can't fix it, rebuild — it's a lab, nothing is precious:

```bash
./cks clean && ./cks setup
```

### "I want to start completely over"

```bash
./cks clean            # deletes the cluster AND ~/cks-lab
./cks setup
```

Keep your edited files (your Dockerfile, your falco rules, your plan.sh):

```bash
./cks clean --keep-files
./cks setup
```

### "I'm coming back tomorrow"

Nothing to do — the kind cluster survives reboots as a Docker container. If Docker
was restarted:

```bash
docker start cks-control-plane cks-worker     # if they're stopped
./cks doctor                                   # confirm it's healthy
./cks list                                     # see what's still seeded
```

Picking up mid-question? `./cks task N` reprints the task; `./cks verify N` shows
exactly which criteria you've already met.

### "Match the Kubernetes version of my exam"

The lab defaults to whatever kind ships (validated on v1.37.0). To pin it:

```bash
./cks clean
CKS_NODE_IMAGE=kindest/node:v1.34.0 ./cks setup
```

None of the findings in `../VALIDATION.md` are version-specific, but matching the
exam is closer practice.

### "Run a second lab without touching the first"

```bash
CKS_CLUSTER=cks2 CKS_LAB_DIR=~/cks-lab2 ./cks setup 8
```

### "Check I haven't left anything running"

```bash
kind get clusters
docker ps --filter name=cks
```

### "Use this in CI / check the scripts still work"

`verify` exits non-zero if any criterion fails:

```bash
./cks setup 4 && ./cks solve 4 && ./cks verify 4 && echo "harness healthy"
```

---

## 5. What each question gives you

| Q | You work on | Seeded for you | Needs |
|---|---|---|---|
| 01 | node: kubelet config, apiserver + etcd manifests | cluster deliberately un-hardened | — |
| 02 | node: apiserver manifest, then `kubectl` | ClusterRole `system:user`, a candidate kubeconfig | — |
| 03 | `~/cks-lab/q03/{Dockerfile,deployment.yaml}` | a root-running Dockerfile + bare Deployment | — |
| 04 | `deploy/two-containers` (default ns) | 2-container Deployment, no securityContext | — |
| 05 | ns `monitoring` | `deploy/token-app`, no ServiceAccount yet | — |
| 06 | ns `prod`, `data` | 5 test pods, namespaces pre-labelled | — |
| 07 | default ns + `~/cks-lab/q07/certs/` | cert+key, `deploy/tls-app` | — |
| 08 | ns `confidential` | `restricted` PSA label + non-compliant 2-container Deployment | — |
| 09 | node: apiserver manifest + `/etc/kubernetes/audit/` | audit config cleared | — |
| 10 | `~/cks-lab/q10/{daemon.json,docker.service,group}` | faithful copies of the three real files | — |
| 11 | `~/cks-lab/q11/plan.sh` | an empty command plan to fill in | — |
| 12 | default ns + `~/cks-lab/q12/certs/` | cert+key, `svc/myapp-svc`, ingress-nginx installed | — |
| 13 | node: apiserver manifest + `/etc/kubernetes/imagepolicy/` | `kube.conf` with a placeholder URL, `test-rc.yaml` | — |
| 14 | ns `falco-lab` + `~/cks-lab/q14/` | 3 Deployments, base+custom rule files, a recorded alert log | — |
| 15 | ns `sbom-lab` + `~/cks-lab/q15/out/` | a 3-container Pod; target package version discovered from the real images | `bom`, `trivy` |
| 16 | ns `my-namespace` | `my-app` + 2 clients, Istio installed, namespace **not** labelled yet | `istioctl` |

---

## 6. How grading works

The grader checks **end state**, not the commands you typed — same as the exam. Where
the real outcome is observable it checks that in preference to the YAML:

- **q01** — `curl` to the kubelet on `:10250` must actually return 401
- **q06** — real pod-to-pod traffic, in both the allowed *and* the denied directions
- **q09** — generates API traffic, then reads the audit log back to confirm each of
  your four rules produced the level it promised
- **q12** — HTTPS through the ingress controller, and that the cert served is *yours*
  (not the controller's fake fallback)
- **q13** — a Pod create must genuinely come back `Forbidden` from the webhook
- **q14** — your rule file is validated by a real `falco` binary, and your collected
  log is checked for actual nanosecond timestamps
- **q15** — the SBOMs must be valid SPDX/CycloneDX *and* describe the correct image
- **q16** — plaintext traffic blocked while in-mesh mTLS traffic still works

It also checks you didn't cheat around the task: q08 fails if you relabel the
namespace instead of fixing the workload, q14 fails if you scale down the innocent
third Deployment.

---

## 7. Traps the lab deliberately preserves

All reproduced against a live cluster — these are the mistakes that cost marks:

| Q | Trap |
|---|---|
| 01 | `NodeRestriction` in `--authorization-mode` stops the API server booting. It's an *admission plugin*, not an authorization mode. |
| 02 | Disabling anonymous-auth does **not** break kubectl. It does leave the API server pod at `0/1` forever — expected, don't "fix" it. |
| 03 | `nobody` is UID 65534, not whatever UID the task names. |
| 07 | A wrong `secretName` doesn't fail `apply` — the pod just hangs in `ContainerCreating`. |
| 08 | `restricted` needs `seccompProfile: RuntimeDefault`. `apply` only warns; the rejection lands on the ReplicaSet. |
| 09 | The flags alone crash the API server — kubeadm mounts `/etc/kubernetes/pki`, not `/etc/kubernetes`. You must add hostPath volumes. |
| 10 | `hosts` in daemon.json **and** `-H` in ExecStart = dockerd refuses to start. And `ss -ltnp` can never show a unix socket. |
| 12 | `.status.loadBalancer.ingress[0].ip` is empty on non-cloud clusters. |
| 13 | The config is an `AdmissionConfiguration`, not `kind: ImagePolicyWebhook`. Wrong kind = API server won't start. |
| 14 | `%evt.time.s` is the *no-nanoseconds* field. `falco -r <file>` replaces the ruleset and breaks macros. |
| 15 | `bom --format spdx-json` does not exist. |

---

## 8. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Unable to connect to the server: EOF` | You broke the apiserver manifest (normal for q01/02/09/13) | `./cks doctor` then `./cks restore` |
| `Cluster 'cks' is not responding` | API server mid-restart, or genuinely down | wait 30s and retry; else `./cks doctor` |
| `Lab cluster 'cks' not found` | Never set up, or `clean`ed | `./cks setup` |
| `kube-apiserver` pod shows `0/1 Running` | **Expected** once q02 is solved — probes are anonymous and get 401 | nothing to fix |
| `kube-controller-manager` `CrashLoopBackOff` | Stale leader-election lease after many apiserver restarts | cleared automatically on every command |
| Pods stuck `Pending`, nothing will start | q13 is solved — `defaultAllow: false` with an unreachable webhook blocks **all** pod creation | `./cks reset 13` |
| q12 verify fails on curl | Ingress controller wasn't ready yet | `./cks setup 12` again |
| q15 verify fails immediately | `bom` / `trivy` missing | `brew install bom trivy` |
| q16 setup fails | `istioctl` missing | `brew install istioctl` |
| `docker info` fails | Docker Desktop not running | start it |
| Image pulls time out | network | re-run the same `./cks setup N`; it's idempotent |

Still stuck? Rebuilding costs you nothing but time:

```bash
./cks clean && ./cks setup
```

---

## 9. Things to know before you rely on it

**Solving q13 blocks Pod creation cluster-wide.** That's the correct end state for
the task, but nothing else can start while it holds. Run `./cks reset 13` before
working on other questions.

**q10 and q11 don't touch the cluster.** macOS has no Docker daemon unit file, and
kind nodes don't install the kubelet via apt, so an in-place `apt-get install
kubeadm=...` isn't reproducible here. Instead q10 gives you faithful copies of the
three real files and grades them with a real `dockerd --validate`; q11 is a written
command-plan drill, linted for the mistakes that matter. The other 14 are fully live.

**Falco detection is pre-recorded (q14).** Falco's kernel driver can't run in kind,
so the alert stream is supplied as a log file. Everything else about the question is
real: your rule file is validated by an actual falco binary, and the Deployment
scaling is checked in the cluster.

**Nothing touches your other clusters.** Every `kubectl` call in the lab is pinned to
the `kind-cks` context, and `clean` only ever deletes the kind cluster named `cks`.

**Your work lives in two places** — cluster objects (gone when you `clean`) and files
under `~/cks-lab/` (gone unless you use `clean --keep-files`).

---

## 10. Layout

```
lab/
  cks                      the only thing you run
  kind.yaml                cluster definition (1 control-plane + 1 worker)
  lib/
    common.sh              helpers: grading, cluster/node access, manifest safety
    apiserver_edit.py      surgical kube-apiserver manifest editing
    falco_rule_output.py   reads a rule's output: field for grading
  questions/
    q01.sh … q16.sh        one file per question: setup / verify / reset / solve
```

Each question file is self-contained — read `questions/q08.sh` to see exactly what
is seeded and precisely what is graded. Nothing is hidden from you.
