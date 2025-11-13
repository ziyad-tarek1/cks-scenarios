# cks-scenarios

---
## Question 1 
> Configure the cluster to:
>
> 1. Add **webhook mode** authorization and disable **anonymous users** in the **Kubelet**.
> 2. Enable **NodeRestriction** admission plugin and **RBAC + NodeRestriction** authorization modes in **kube-apiserver**.
> 3. Configure **etcd** with `--client-cert-auth=true`.
---
### Solutio:

#### 🧱 Step 1 — Kubelet: Disable Anonymous Users & Enable Webhook Auth

#### 🧱 Step 1 — Kubelet: Disable Anonymous Users & Enable Webhook Auth

1. Edit the Kubelet config file:

   ```bash
   sudo vim /var/lib/kubelet/config.yaml
   ```
2. Find or add:

   ```yaml
   authentication:
     anonymous:
       enabled: false
     webhook:
       enabled: true
   authorization:
     mode: Webhook
   ```
3. Save and restart the Kubelet:

   ```bash
   sudo systemctl restart kubelet
   ```

---

#### 🧱 Step 2 — API Server: Enable RBAC + NodeRestriction

1. Edit the static pod manifest:

   ```bash
   sudo vim /etc/kubernetes/manifests/kube-apiserver.yaml
   ```

2. Inside the `command:` section, ensure these flags are present:

   ```yaml
   - --authorization-mode=NodeRestriction,RBAC
   - --enable-admission-plugins=NodeRestriction
   ```

   (If `--authorization-mode` already has something like `RBAC`, just append `,NodeRestriction`.)

3. Save and exit — since it’s a static pod, the API server will automatically restart.

4. Verify the flags:

   ```bash
   ps -ef | grep kube-apiserver
   ```

   or check:

   ```bash
   kubectl get pods -n kube-system -l component=kube-apiserver
   ```

---

#### 🧱 Step 3 — etcd: Enable Client Certificate Authentication

1. Edit etcd manifest:

   ```bash
   sudo vim /etc/kubernetes/manifests/etcd.yaml
   ```

2. Add or ensure the flag:

   ```yaml
   - --client-cert-auth=true
   ```

3. Save → etcd pod auto-restarts.

4. Confirm:

   ```bash
   ps -ef | grep etcd
   ```

   Look for `--client-cert-auth=true`.

---

#### ✅ Step 4 — Verification

* Check Kubelet status:

  ```bash
  curl -v --insecure https://localhost:10250
  ```

  You should get an **unauthorized** response, not open access.

* Check API server admission plugins:

  ```bash
  kubectl get --raw /metrics | grep NodeRestriction
  ```
---

### 🧠 Summary

You hardened:

* Kubelet → disabled anonymous access, enabled webhook authorization.
* API server → RBAC + NodeRestriction.
* etcd → enforces client cert authentication.

---

## Question 2

> Configure the cluster to disable **anonymous-auth** in the **kube-apiserver** and (something else — typically enabling RBAC or ensuring proper secure port usage).

---

### Solution**

#### 🧱 Step 1 — Edit API Server Static Pod

```bash
sudo vim /etc/kubernetes/manifests/kube-apiserver.yaml
```

Add or modify the following flags under `command:`:

```yaml
- --anonymous-auth=false
- --authorization-mode=RBAC,NodeRestriction
- --enable-admission-plugins=NodeRestriction
```

> 💡 Note: Make sure `--authorization-mode` is not duplicated — merge into one line if needed.

Save and exit — the static pod will restart automatically.

---

#### 🧱 Step 2 — Verify Changes

Run:

```bash
ps -ef | grep kube-apiserver
```

Ensure you see:

```
--anonymous-auth=false
--authorization-mode=RBAC,NodeRestriction
```

Check that the API server pod is running again:

```bash
kubectl get pods -n kube-system
```

---

#### 🧱 Step 3 — Test Anonymous Access Blocked

Try an unauthenticated curl:

```bash
curl -k https://localhost:6443/version
```

You should see:

```
Unauthorized
```

That means anonymous-auth is disabled.

---

### 🧠 Summary

* API server now denies any unauthenticated access.
* RBAC controls are enforced.
* Admission plugin NodeRestriction restricts kubelet certificate usage.
