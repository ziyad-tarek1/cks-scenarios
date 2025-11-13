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

---

## Question 3

> You are given:
>
> * A **Dockerfile**
> * A **Pod/Deployment YAML file**
>
> You must apply **best security practices**, including using:
>
> * A **non-root user** (`nobody`, UID `63356` provided)
> * A **readOnlyRootFilesystem** in the Pod spec
>
> Modify both files accordingly.

---

### Solution**

# **✔️ Part 1 — Fix the Dockerfile**

### 🔧 **Before (root user)**

Example (what they usually give):

```dockerfile
FROM ubuntu:20.04
# ... some commands
USER root
CMD ["python", "app.py"]
```

### 🔧 **After (non-root best practice)**

If user `nobody` already exists:

```dockerfile
FROM ubuntu:20.04

# (Optional) create a custom user if UID given:
RUN useradd -u 63356 -s /sbin/nologin appuser

# Switch to non-root user
USER 63356

CMD ["python", "app.py"]
```

Or if they explicitly ask to use `nobody`:

```dockerfile
USER nobody
```

> 💡 Using `USER` in Dockerfile is required for CKS.
> They expect **non-root image** + **non-root pod securityContext**.

---

# **✔️ Part 2 — Fix the YAML file**

They typically give you a Deployment like:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: app
        image: myimg:v1
```

### 🔧 **You must add `securityContext`:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 1
  template:
    spec:
      securityContext:
        runAsUser: 63356
        runAsNonRoot: true

      containers:
      - name: app
        image: myimg:v1
        securityContext:
          readOnlyRootFilesystem: true
```

---

## Question 4

> You are given a Deployment with **two containers**.
>
> You must add a **securityContext** to **both containers**, using:
>
> * `runAsUser: <ID given in question>`
> * `allowPrivilegeEscalation: false`
> * `readOnlyRootFilesystem: true`


---

### Solution**


#### **Step 1 — Open the Deployment**

```bash
kubectl edit deployment <name>
```

or if file is provided:

```bash
vi deployment.yaml
```

---

#### **Step 2 — Locate the two containers**

Example given:

```yaml
containers:
  - name: app1
    image: myimg1:v1
  - name: app2
    image: myimg2:v1
```

---

#### **Step 3 — Add the required securityContext to each container**

Use the UID provided in the question.
Example: UID = `63356`

### Updated version:

```yaml
containers:
  - name: app1
    image: myimg1:v1
    securityContext:
      runAsUser: 63356
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true

  - name: app2
    image: myimg2:v1
    securityContext:
      runAsUser: 63356
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
```

---

# 🎯 **Final Expected YAML Answer (Ready-to-Paste)**

Replace `<UID>` with the user ID given in the exam.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: app1
        image: myimg1:v1
        securityContext:
          runAsUser: <UID>
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true

      - name: app2
        image: myimg2:v1
        securityContext:
          runAsUser: <UID>
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
```