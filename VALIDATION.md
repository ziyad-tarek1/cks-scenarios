# Validation Report — CKS Practice Questions

Every question in `q1.md`–`q16.md` was executed against a **real kubeadm cluster** (kind, Kubernetes
v1.37.0, 1 control-plane + 1 worker) plus the real tooling (`falco` 0.39.2, `bom` 0.8.0, `trivy`,
`istioctl`/Istio 1.31, `docker`, `kube-linter`, `kubesec`, `ingress-nginx`).

Each solution was applied **exactly as written** first. Where that failed, the failure was captured and
the file corrected with the working version. Every claim marked ✅ below was reproduced; every ⛔ was
reproduced as a failure.

## Summary

| # | Topic | Verdict | What was wrong |
|---|---|---|---|
| 1 | Kubelet / apiserver / etcd hardening | ⛔ Fixed | "RBAC + NodeRestriction authorization modes" is invalid — `--authorization-mode=RBAC,NodeRestriction` **stops the API server booting**. Solution never showed `--authorization-mode` at all. |
| 2 | Disable anonymous-auth | ⛔ Fixed | Core claim false: kubectl keeps working. Real effect is apiserver pod `0/1 NotReady` (probes are anonymous → 401). Also `candiented` typo; `system:user` is not a default ClusterRole. |
| 3 | Dockerfile + Pod hardening | ⛔ Fixed | `nobody` is UID **65534**, not `63356` — the two options given were not interchangeable. Added the nginx-as-non-root CrashLoop gotcha. |
| 4 | securityContext on two containers | ✅ Correct | No changes needed. Verified `uid=63356`, read-only rootfs enforced on both containers. |
| 5 | Projected ServiceAccount token | ✅ Correct | YAML correct. Fixed only the explanatory note: `path` is the **file** name, not a directory. |
| 6 | NetworkPolicy deny-all + cross-namespace | ✅ Correct | Both policies enforce correctly under real traffic. Added the AND-vs-OR `from` trap. |
| 7 | TLS Secret + mount | ⛔ Fixed | `secretName: m` — truncated. Pod hangs in `ContainerCreating` / `FailedMount`. |
| 8 | Pod Security Admission (restricted) | ⛔ Fixed | **Missing `seccompProfile: RuntimeDefault`** → every Pod rejected. Also `readOnlyRootFilesystem` is *not* required by `restricted`. |
| 9 | Audit logging | ⛔ Fixed | **Missing hostPath volumes/volumeMounts** → API server crash-loops (`no such file or directory`). Policy rules themselves verified correct. |
| 10 | Docker daemon hardening | ⛔ Fixed | Steps 2+3 together **break Docker** (`hosts` specified as both flag and in config file). `ss -ltnp` can never show a unix socket — documented output was impossible. |
| 11 | kubeadm node upgrade | ⛔ Fixed | Question said `v1.31.1`, commands installed `1.34.1`. Missing `apt-mark hold`; missing `kubeadm upgrade apply` for the control plane. |
| 12 | Ingress + TLS | ⛔ Fixed | `{.status.loadBalancer.ingress[0].ip}` is **empty** on non-LB clusters → the `/etc/hosts` one-liner writes a broken entry. Replaced with `curl --resolve`. Added `ingressClassName`. |
| 13 | ImagePolicyWebhook | ⛔ Fixed | **Config file format invalid** — `kind: ImagePolicyWebhook` is not accepted (`no kind ... is registered`); must be `AdmissionConfiguration`. Missing hostPath mount. Step 5 wrong: the RC *is* created; only Pods are denied. |
| 14 | Falco | ⛔ Fixed | `%evt.time.s` is the **no-nanoseconds** field (task asks for nanoseconds → `%evt.time`). `falco -r <custom>` alone fails (`Undefined macro`). No built-in `/dev/mem` rule exists. |
| 15 | SBOM / image scanning | ⛔ Fixed | `--format spdx-json` **does not exist** in `bom` (valid: `tag-value`, `json`, `spdx3-json`). Two "different" commands were identical. |
| 16 | Istio mTLS | ✅ Correct | STRICT verified blocking plaintext (curl 56) while mTLS got 200. Updated to `security.istio.io/v1` (preferred) and added the injection-ordering gotcha. |

**4 correct as written** (4, 5, 6, 16 — 5 and 6 had only explanatory-note fixes) · **12 contained defects**
· **6 would have brought down the control plane or been outright rejected** (1, 7, 8, 9, 10, 13).

## The highest-value lessons

1. **Static pods only see what is mounted.** kubeadm mounts `/etc/kubernetes/pki`, **not**
   `/etc/kubernetes`. Any new file you point the API server at (audit policy, admission config) needs a
   `hostPath` volume **and** a `volumeMount`. This broke both q9 and q13.
2. **`kubectl apply` succeeding proves nothing.** PSA rejections (q8) and ImagePolicyWebhook denials (q13)
   surface on the *ReplicaSet*, not the Deployment. Always `kubectl get pods`, then `kubectl describe rs`.
3. **When the API server is down, kubectl cannot help you.** Read the real error on the node:
   `sudo crictl logs $(sudo crictl ps -a --name kube-apiserver -q | head -1)`.
   Back up `/etc/kubernetes/manifests/*.yaml` before editing.
4. **Admission plugin ≠ authorization mode.** `NodeRestriction` is admission; `Node` is authorization.
5. **Verify with the data plane, not the control plane.** A NetworkPolicy, mTLS policy or Ingress that the
   API server accepts may do nothing. Prove it with `curl`.

## Practise it yourself

`lab/` turns all 16 scenarios into a reproducible lab with an exam-style grader:

```bash
cd lab
./cks setup      # build the kubeadm cluster and seed every question
./cks task 8     # read a task
./cks verify 8   # graded, with a hint on every failure
./cks reset 8    # try again from scratch
./cks clean      # destroy everything
```

The grader checks **end state**, not commands: real pod-to-pod traffic for the
NetworkPolicy question, the audit log read back to confirm each rule's level, a
real `falco` binary validating your rule file, HTTPS through the ingress controller,
an actual `Forbidden` from the ImagePolicyWebhook. Every question was verified
setup -> fail -> solve -> pass from a from-scratch cluster. See `lab/README.md`.

## Reproducing this

```bash
kind create cluster --config kind.yaml       # 1 control-plane + 1 worker
# control-plane node is a container, so:
docker exec -it <cluster>-control-plane bash
#   /etc/kubernetes/manifests/   -> static pod manifests
#   /var/lib/kubelet/config.yaml -> kubelet config
#   crictl ps -a / crictl logs   -> when kubectl is dead
```

Caveat: repeatedly restarting the API server can leave `kube-controller-manager` stuck in
`CrashLoopBackOff` on a stale leader-election lease. Clear it with
`kubectl -n kube-system delete lease kube-controller-manager`. That is a lab artifact, not a question defect.
