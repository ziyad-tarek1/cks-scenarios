# CKS Scenarios

Practice scenarios for the **Certified Kubernetes Security Specialist (CKS)** exam —
16 tasks with worked solutions, plus a local lab that sets each one up and grades
your answer the way the exam would.

Every solution in here was run against a real kubeadm cluster and corrected where it
broke. See [VALIDATION.md](VALIDATION.md) for what was wrong and the evidence.

## Start here

```bash
cd lab
./cks setup        # build the cluster + seed all 16 questions (~10-15 min first time)
./cks task 8       # read a task
./cks verify 8     # get graded
```

Step-by-step guide, every use case and troubleshooting: **[lab/README.md](lab/README.md)**

## The scenarios

| # | Topic | Scenario |
|---|---|---|
| 1 | Kubelet webhook auth, NodeRestriction, etcd client certs | [q1.md](q1.md) |
| 2 | Disable anonymous-auth; delete a ClusterRole | [q2.md](q2.md) |
| 3 | Dockerfile + Pod hardening (non-root, read-only rootfs) | [q3.md](q3.md) |
| 4 | securityContext on both containers of a Deployment | [q4.md](q4.md) |
| 5 | ServiceAccount automount off + projected token volume | [q5.md](q5.md) |
| 6 | NetworkPolicy: default-deny plus cross-namespace allow | [q6.md](q6.md) |
| 7 | TLS Secret mounted into a Deployment | [q7.md](q7.md) |
| 8 | Comply with `restricted` Pod Security Admission | [q8.md](q8.md) |
| 9 | API server audit logging with a 4-rule policy | [q9.md](q9.md) |
| 10 | Docker daemon hardening (group, unix socket only) | [q10.md](q10.md) |
| 11 | kubeadm node upgrade | [q11.md](q11.md) |
| 12 | TLS Secret + Ingress, verified with curl | [q12.md](q12.md) |
| 13 | ImagePolicyWebhook admission control | [q13.md](q13.md) |
| 14 | Falco: custom rules, output fields, find the offender | [q14.md](q14.md) |
| 15 | Image scanning + SBOM (SPDX via `bom`, CycloneDX via `trivy`) | [q15.md](q15.md) |
| 16 | Istio sidecar injection + STRICT mTLS | [q16.md](q16.md) |

Each scenario file ends with a **"Practise this in the lab"** section: the exact
commands for that question, what the lab seeds, what the grader checks, and the
gotcha that costs people the mark.

## What's in the repo

```
q1.md … q16.md    the scenarios, with worked and verified solutions
VALIDATION.md     what was wrong in the original solutions, with evidence
lab/              the practice lab (./cks setup | task | verify | reset | solve | clean)
kind.yaml         the cluster used for validation
Backup/           earlier notes and KCSA material
```

## Requirements for the lab

`docker` (running), `kind`, `kubectl`. Plus `bom` + `trivy` for q15 and `istioctl`
for q16. Everything else the lab installs or runs for you.

```bash
brew install kind kubectl bom trivy istioctl
```
