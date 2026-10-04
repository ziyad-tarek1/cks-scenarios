# CKS Practice Lab

A reproducible lab for the 16 scenarios in `../q1.md` … `../q16.md`, with an
exam-style grader. Three commands:

```bash
./cks setup          # build the cluster and seed every question
./cks verify         # grade your work the way the exam would
./cks clean          # destroy everything, start over whenever you like
```

Everything runs on a local **kind** cluster, which is a real kubeadm cluster — so
`/etc/kubernetes/manifests`, etcd, and the kubelet config are all genuine, and the
control-plane questions are solved exactly as they are in the exam.

## Requirements

| Tool | Needed for | Install |
|---|---|---|
| Docker | everything | Docker Desktop, running |
| kind | the cluster | `brew install kind` |
| kubectl | everything | `brew install kubectl` |
| openssl | q07, q12 | preinstalled on macOS |
| bom, trivy | q15 | `brew install bom trivy` |
| istioctl | q16 | `brew install istioctl` |

`ingress-nginx` (q12) and Istio (q16) are installed into the cluster automatically
the first time you set those questions up. Falco (q14) runs from a container image
on demand — nothing to install.

Works with macOS's stock bash 3.2.

## Commands

```bash
./cks setup [N...]     # build cluster + seed; no args = all 16
./cks verify [N...]    # grade; no args = all 16
./cks reset  N...      # re-seed a question, discarding your work on it
./cks solve  N...      # apply the reference solution (to study, or to compare)
./cks task   N         # re-print a question's task statement
./cks list             # all questions + which are seeded
./cks doctor           # diagnose a broken cluster
./cks restore          # put the control plane back to known-good
./cks clean            # delete the cluster and the work dir
./cks clean --keep-files   # delete the cluster, keep your files
```

`1`, `01` and `q1` all mean question 1.

## How to practise

```bash
./cks setup 8          # seed one question
./cks task 8           # read the task
#   ... do the work ...
./cks verify 8         # graded, with a hint on every failure
./cks solve 8          # only if you want to see the answer
./cks reset 8          # wipe it and try again from scratch
```

Your working files live in `~/cks-lab/qNN/` (override with `CKS_LAB_DIR`).
Each question's `TASK.md` is written there at setup.

## What the grader checks

It grades **end state**, not the commands you typed — like the exam. Where the
real outcome is observable, it checks that rather than the YAML:

* q01 — `curl` to the kubelet on :10250 must return 401
* q06 — real pod-to-pod traffic across namespaces, allowed *and* denied directions
* q09 — generates API traffic, then reads the audit log back to confirm each rule
  produced the level it promised
* q12 — HTTPS through the ingress controller, and that the cert served is yours
* q13 — a Pod create is actually `Forbidden` by the webhook
* q14 — your rule file is validated by a real `falco` binary
* q15 — the SBOMs are valid SPDX/CycloneDX and describe the *correct* image
* q16 — plaintext traffic is blocked while in-mesh mTLS traffic still works

## Traps the lab deliberately preserves

These are the mistakes that actually cost marks, verified against a live cluster:

| Q | Trap |
|---|---|
| 01 | `NodeRestriction` in `--authorization-mode` stops the API server booting. It is an *admission plugin*. |
| 02 | Disabling anonymous-auth does **not** break kubectl. It does leave the API server pod at `0/1` forever — expected, don't "fix" it. |
| 03 | `nobody` is UID 65534, not whatever UID the task names. |
| 07 | A wrong `secretName` doesn't fail `apply` — the pod just hangs in `ContainerCreating`. |
| 08 | `restricted` PSA needs `seccompProfile: RuntimeDefault`. `apply` only warns; the rejection is on the ReplicaSet. |
| 09 | Flags alone crash the API server — kubeadm mounts `/etc/kubernetes/pki`, not `/etc/kubernetes`. You must add hostPath volumes. |
| 10 | `hosts` in daemon.json **and** `-H` in ExecStart = dockerd refuses to start. And `ss -ltnp` can never show a unix socket. |
| 12 | `.status.loadBalancer.ingress[0].ip` is empty on non-cloud clusters. |
| 13 | The admission config is an `AdmissionConfiguration`, not `kind: ImagePolicyWebhook`. Wrong kind = API server won't start. |
| 14 | `%evt.time.s` is the *no-nanoseconds* field. `falco -r <file>` replaces the ruleset and breaks macros. |
| 15 | `bom --format spdx-json` does not exist. |

## Notes and gotchas

**Solving q13 blocks all Pod creation cluster-wide.** That is the correct end state
(`defaultAllow: false` with an unreachable webhook), but nothing else can start
while it holds. Run `./cks reset 13` before working on other questions.

**q10 and q11 don't touch the cluster.** macOS has no Docker daemon unit file and
kind nodes don't install kubelet via apt, so q10 gives you a faithful copy of the
three real files (graded with a real `dockerd --validate`) and q11 is a written
command-plan drill, linted for the mistakes that matter. Everything else is live.

**If the API server dies,** that's normal practice for q01/q02/q09/q13 — it is how
the exam punishes a bad manifest. `kubectl` will print `Unable to connect to the
server: EOF`. Then:

```bash
./cks doctor      # shows the real error from the container / kubelet
./cks restore     # back to known-good control-plane manifests
```

`restore` falls back to restarting the kubelet, which is what reliably recovers a
static pod the kubelet has given up on.

**`kube-controller-manager` crash-looping** after lots of API server restarts is a
lab artifact (a stale leader-election lease). Every command clears it automatically.

**Nothing touches your other clusters.** Every `kubectl` call in the lab is pinned
to the `kind-cks` context, and `clean` only ever deletes the kind cluster named
`cks`.

## Environment overrides

```bash
CKS_LAB_DIR=~/somewhere   # where your working files go     (default ~/cks-lab)
CKS_CLUSTER=cks           # kind cluster name               (default cks)
CKS_NODE_IMAGE=kindest/node:v1.34.0   # pin the Kubernetes version
```

Pin `CKS_NODE_IMAGE` to whatever version your exam targets. The lab was validated
on v1.37.0; none of the findings are version-specific, but matching the exam is
closer practice.
