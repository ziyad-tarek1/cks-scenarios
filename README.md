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

---

## Question 5

1. Create a **ServiceAccount** in namespace `monitoring`
   → **automountServiceAccountToken: false**

2. In a **Deployment**, mount this serviceAccount’s token **as a projected volume**
   → token must be **readOnly**
   → must use `serviceAccountToken` type projection
   → must specify `audience` + `path` + `expirationSeconds`
---

### Solution**
## **Step 1 — Create the ServiceAccount**

```bash
kubectl create namespace monitoring
kubectl create serviceaccount monitor-sa -n monitoring
```

Now edit it:

```bash
kubectl edit sa monitor-sa -n monitoring
```

Add:

```yaml
automountServiceAccountToken: false
```
## **Step 2 — Modify Deployment to use projected token**

Open file or edit:

```bash
kubectl edit deployment mydeploy -n monitoring
```

Add under `.spec.template.spec`:

### volumes:

```yaml
volumes:
- name: token-vol
  projected:
    sources:
    - serviceAccountToken:
        path: token
        audience: api
        expirationSeconds: 3600
```

### container volumeMounts:

```yaml
containers:
- name: app
  image: myimg
  volumeMounts:
  - name: token-vol
    mountPath: /var/run/secrets/tokens
    readOnly: true
```

### serviceAccountName:

```yaml
serviceAccountName: monitor-sa
```

# **FULL EXPECTED ANSWER (Copy/Paste Ready)**

### **ServiceAccount**

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: monitor-sa
  namespace: monitoring
automountServiceAccountToken: false
```

### **Deployment**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  namespace: monitoring
spec:
  replicas: 1
  template:
    spec:
      serviceAccountName: monitor-sa

      volumes:
      - name: token-vol
        projected:
          sources:
          - serviceAccountToken:
              path: token
              audience: api
              expirationSeconds: 3600

      containers:
      - name: app
        image: nginx
        volumeMounts:
        - name: token-vol
          mountPath: /var/run/secrets/tokens
          readOnly: true
```

---

## Question 6

1. Create a NetworkPolicy that **DENIES all ingress** traffic in namespace `prod`.
2. Create another policy that **allows traffic from pods in namespace prod → pods in namespace data**
   Using **pod labels** + **namespace selectors**.
---

### Solution**

# 🧱 PART 1 — Deny all ingress in namespace `prod`

Namespace must have **default deny** policy.

### **deny-all-ingress.yaml**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: prod
spec:
  podSelector: {}     # all pods
  policyTypes:
  - Ingress
  ingress: []          # deny everything
```

# 🧱 PART 2 — Allow pods from `prod` → `data` namespace (ingress allow)

You must:

* Select pods in namespace `data` using **podSelector**
* Allow traffic only from pods in namespace `prod`
  → using **namespaceSelector** with labels
  → AND with podSelector

### **Pre-req:** Add labels to namespaces

```bash
kubectl label namespace prod name=prod --overwrite
kubectl label namespace data name=data --overwrite
```


### **allow-prod-to-data.yaml**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-prod-to-data
  namespace: data
spec:
  podSelector:
    matchLabels:
      role: backend   # example: depends on question
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: prod
      podSelector:
        matchLabels:
          app: myapp   # example label from the question
```
---

# 📌 FINAL FORMULA SUMMARY FOR QUESTION 6

### Deny all ingress:

```yaml
podSelector: {}
ingress: []
policyTypes: [Ingress]
```

### Allow traffic from namespace prod:

```yaml
from:
- namespaceSelector: { label: prod }
  podSelector: { label: <prod-app-label> }
```

---

## Question 7

1. You are *given* a certificate and a key, usually at paths like:

   * `/root/certs/tls.crt`
   * `/root/certs/tls.key`

2. You must create a **TLS Secret** in Kubernetes.

3. You must update a **Deployment** to use that secret, either as:
   ✔️ a **volume** (mounted cert/key files)
   or
   ✔️ environment variable (less common — usually NOT for TLS)
---

### Solution**


## **Step 1 — Create the TLS secret**

### Command:

```bash
kubectl create secret tls my-tls-secret \
  --cert=/root/certs/tls.crt \
  --key=/root/certs/tls.key \
  -n default
```

If they specify a namespace, use it:

```bash
kubectl create secret tls my-tls-secret \
  --cert=/root/certs/tls.crt \
  --key=/root/certs/tls.key \
  -n mynamespace
```

---

## **Step 2 — Edit Deployment to mount the TLS secret**

Open deployment:

```bash
kubectl edit deployment mydeploy -n default
```

Under `.spec.template.spec.volumes` add:

```yaml
volumes:
- name: tls-vol
  secret:
    secretName: my-tls-secret
```

Under container `.volumeMounts` add:

```yaml
volumeMounts:
- name: tls-vol
  mountPath: /etc/tls            # choose any secure path
  readOnly: true
```

---

# 📌 **FINAL YAML ANSWER (Exactly what CKS expects)**

### **TLS Secret**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-tls-secret
  namespace: default
type: kubernetes.io/tls
data:
  tls.crt: <base64-cert>
  tls.key: <base64-key>
```

(You do **NOT** need to base64 encode if you create via `kubectl create secret tls`.)

---

### **Deployment**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mydeploy
  namespace: default
spec:
  replicas: 1
  template:
    spec:
      volumes:
      - name: tls-vol
        secret:
          secretName: my-tls-secret

      containers:
      - name: app
        image: nginx
        volumeMounts:
        - name: tls-vol
          mountPath: /etc/tls
          readOnly: true
```

---

## Question 8

A namespace named **`confidential`** has **Pod Security Admission (restricted)** applied.

Meaning:

🔒 Only **restricted** security settings are allowed in this namespace.
❌ Default pods will **NOT start** unless they meet restricted rules.

**Your task:**

👉 Modify the Pod/Deployment YAML so it **complies with the restricted PSA**.
---

### Solution**


## **Step 1 — Inspect namespace**

```bash
kubectl get ns confidential --show-labels
```

You will see something like:

```
pod-security.kubernetes.io/enforce=restricted
```

---

## **Step 2 — Try to create a pod (it fails)**

You might see errors like:

```
pod is forbidden: violates PodSecurity "restricted"
```

This is expected.

---

## **Step 3 — Patch your Pod/Deployment to satisfy "restricted"**

Add the following under each **container securityContext**:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000         # or UID provided in the exam
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
    - ALL
```

If the Deployment used `securityContext` at pod level, add:

```yaml
securityContext:
  fsGroup: 2000
  runAsNonRoot: true
```

(Only if needed.)

---

# 📌 **FINAL YAML FIX (What the CKS grader expects)**

**Example Deployment inside `confidential` namespace:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  namespace: confidential
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: app
        image: nginx
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
```

---

## Question 9

1. **Enable audit logging** in the kube-apiserver.
2. Add `--audit-policy-file=/etc/kubernetes/audit/audit.yaml`
3. Configure log rotation:

   * `--audit-log-maxage=<given>`
   * `--audit-log-maxbackup=<given>`
   * `--audit-log-maxsize=<given>` (usually also needed)
4. Create an **audit policy** with:

   * **All namespaces:** request+response metadata
   * **`web-apps` namespace:** deployments → audit **metadata level**
   * **All namespaces:** delete on ConfigMaps & Secrets → **RequestResponse body**
   * Everything else → **Metadata**

---

### Solution**


# ✅ **Step 1 – Edit kube-apiserver manifest**

File:

```
/etc/kubernetes/manifests/kube-apiserver.yaml
```

Add these flags under `command:`:

```yaml
    - --audit-policy-file=/etc/kubernetes/audit/audit.yaml
    - --audit-log-path=/var/log/kubernetes/audit.log
    - --audit-log-maxage=5
    - --audit-log-maxbackup=10
    - --audit-log-maxsize=100
```

(Create directory if required)

```bash
sudo mkdir -p /etc/kubernetes/audit
```

---

# ✅ **Step 2 – Create audit policy**

File:

```
/etc/kubernetes/audit/audit.yaml
```

Content:

```yaml
apiVersion: audit.k8s.io/v1
kind: Policy

# Default level
rules:

  # 1️⃣ Log delete operations of ConfigMaps & Secrets with RequestResponse body
  - level: RequestResponse
    verbs: ["delete"]
    resources:
    - group: ""
      resources: ["configmaps", "secrets"]

  # 2️⃣ Capture Deployments interactions in web-apps namespace (metadata)
  - level: Metadata
    resources:
    - group: "apps"
      resources: ["deployments"]
    namespaces: ["web-apps"]

  # 3️⃣ Log ALL namespace interactions (metadata)
  - level: Metadata
    resources:
    - group: ""
      resources: ["namespaces"]

  # 4️⃣ Everything else at Metadata level
  - level: Metadata
```

---

# 🔄 **Step 3 – kubelet automatically restarts kube-apiserver**

No need for manual restart because it’s a static pod under `/etc/kubernetes/manifests`.

Check:

```bash
kubectl logs -n kube-system kube-apiserver-<node>
```

Audit logs stored at:

```bash
/var/log/kubernetes/audit.log
```
---

## Question 10

1. Remove user **developer** from **docker** group
2. Disable **TCP** access to Docker daemon
3. Make Docker listen **only** on the Unix socket:

   ```
   /var/run/docker.sock
   ```
---

### Solution**
# ✅ **Step 1 — Remove user developer from docker group**

```bash
sudo gpasswd -d developer docker
```

Or:

```bash
sudo deluser developer docker
```

Confirm:

```bash
id developer
```

You should NOT see `docker` group.

---

# ✅ **Step 2 — Deny TCP traffic to Docker daemon**

Docker listens on TCP only if you explicitly enabled it in:

```
/etc/docker/daemon.json
```

Edit it to **remove any TCP host**:

### ❌ If you have:

```json
{
  "hosts": [
    "tcp://0.0.0.0:2375",
    "unix:///var/run/docker.sock"
  ]
}
```

### ✅ Replace with:

```json
{
  "hosts": [
    "unix:///var/run/docker.sock"
  ]
}
```

---

# ✅ **Step 3 — Enforce Unix Socket Only (Mandatory CKS)**

Ensure Docker is **not listening on TCP**.

Check service file:

```
/lib/systemd/system/docker.service
```

Look for:

```
ExecStart=/usr/bin/dockerd
```

If you see any `-H tcp://...`, delete it.

Example:

### ❌ If you have:

```
ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock
```

### ✅ Replace with:

```
ExecStart=/usr/bin/dockerd -H unix:///var/run/docker.sock
```

Then reload & restart:

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

---

# 🔐 **Step 4 — (Optional but expected in CKS) Block port 2375 using firewall**

If TCP was previously exposed, block it:

### UFW:

```bash
sudo ufw deny 2375/tcp
```

### IPTables:

```bash
sudo iptables -A INPUT -p tcp --dport 2375 -j DROP
```

---

# 🔍 Verification

### Check Docker isn't listening on TCP:

```bash
sudo ss -ltnp | grep dockerd
```

You should see:

```
unix  /var/run/docker.sock
```

No `tcp` entries.

---