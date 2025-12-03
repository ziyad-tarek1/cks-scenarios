# cks-scenarios

---
## Question 1 
> Configure the cluster to:
>
> 1. Add **webhook mode** authorization and disable **anonymous users** in the **Kubelet**.
> 2. Enable **NodeRestriction** admission plugin and **RBAC + NodeRestriction** authorization modes in **kube-apiserver**.
> 3. Configure **etcd** with `--client-cert-auth=true`.
---
### Solution:

**Reference:**
- https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-reconfigure/
- https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-reconfigure/#reflecting-the-kubelet-changes

```bash
kubectl get cm -n kube-system kubelet-config
kubectl edit cm -n kube-system kubelet-config

kubeadm upgrade node phase kubelet-config

sudo systemctl daemon-reload 
sudo systemctl restart kubelet
```

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

### Solution:

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

### Solution:

```bash
kube-linter lint pod.yaml
kubesec scan  pod.yaml
```

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

### Solution:


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

### Solution:

**Reference:**
- https://kubernetes.io/docs/concepts/storage/projected-volumes/#serviceaccounttoken

> **Note:** `mountPath` is the directory name, while the folder name in the projected volume is `path`.

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
              path: token  # DIR NAME
              audience: api
              expirationSeconds: 3600

      containers:
      - name: app
        image: nginx
        volumeMounts:
        - name: token-vol
          mountPath: /var/run/secrets/tokens  # PARENT DIR
          readOnly: true
```

---

## Question 6

1. Create a NetworkPolicy that **DENIES all ingress** traffic in namespace `prod`.
2. Create another policy that **allows traffic from pods in namespace prod → pods in namespace data**
   Using **pod labels** + **namespace selectors**.
---

### Solution:

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

### Solution:


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

### Solution:

> **Note:** This solution applies to Pods with two containers.

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

### Solution:

**Reference:**
- https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/


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

### Solution:
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

## Question 11

> Upgrade nodes in cluster to v1.31.1

---

### Solution:

**Reference:**
- https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/

---

## Question 12

1. Create a TLS secret using a given key + cert file
2. Create an Ingress that uses that TLS secret
3. Add a host (given in the exam)
4. Test using curl
---

### Solution:
# ✅ Step 1 — Create TLS Secret (using provided `cert.crt` & `cert.key`)

```bash
kubectl create secret tls tls-secret \
  --cert=/path/to/cert.crt \
  --key=/path/to/cert.key \
  -n your-namespace
```

If namespace is not specified in the question → use `default`.

---

# ✅ Step 2 — Create an Ingress using TLS

Example host from exam: `app.example.com`

```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  namespace: your-namespace
spec:
  tls:
    - hosts:
        - app.example.com
      secretName: tls-secret
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: myapp-svc
                port:
                  number: 80
```

Apply:

```bash
kubectl apply -f ingress.yaml
```

---

# ✅ Step 3 — Test Using curl (IMPORTANT FOR CKS)

If self-signed: use `-k`:

```bash
curl -k https://app.example.com
```

If DNS not resolvable, use `/etc/hosts`:

```bash
sudo sh -c 'echo "$(kubectl get ing myapp-ingress -n your-namespace -o jsonpath={.status.loadBalancer.ingress[0].ip}) app.example.com" >> /etc/hosts'
```

Then:

```bash
curl -k https://app.example.com
```

---

## Question 13

1. Enable `ImagePolicyWebhook` in kube-apiserver
2. Add the full path of `kube.conf` in `/etc/kubernetes/imagepolicy/imagepolicyfile.yaml`
3. Change default allow = **false**
4. In `kube.conf`, set the `server:` URL (given in exam)
5. Test by applying the ReplicationController YAML

---

kubeadm clusters store the kube-apiserver flags in:

```
/etc/kubernetes/manifests/kube-apiserver.yaml
```

You edit this file → kubelet automatically restarts the API server.

---

# ✅ Step 1 — Create directory for ImagePolicyWebhook

```bash
sudo mkdir -p /etc/kubernetes/imagepolicy
```

---

# ✅ Step 2 — Create the image policy config file

File path:

```
/etc/kubernetes/imagepolicy/imagepolicyfile.yaml
```

Content:

```yaml
apiVersion: imagepolicy.k8s.io/v1alpha1
kind: ImagePolicyWebhook
allowTTL: 60
denyTTL: 60
retryBackoff: 500
defaultAllow: false
kubeConfigFile: "/etc/kubernetes/imagepolicy/kube.conf"
```

This is **the exact format used in CKS**.

---

# ✅ Step 3 — Create the kube.conf for the webhook client

Location:

```
/etc/kubernetes/imagepolicy/kube.conf
```

Content (example URL from exam):

```yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://image-webhook.example.com:443
    insecure-skip-tls-verify: true
  name: image-policy-cluster
contexts:
- context:
    cluster: image-policy-cluster
    user: image-bot
  name: image-policy-context
current-context: image-policy-context
users:
- name: image-bot
  user:
    token: dummy-token
```

The important part is:

```
server: <URL from question>
```

---

# ✅ Step 4 — Enable ImagePolicyWebhook in kube-api server

Edit:

```
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

Add to command arguments:

```yaml
- --admission-control-config-file=/etc/kubernetes/imagepolicy/imagepolicyfile.yaml
- --enable-admission-plugins=ImagePolicyWebhook
```

If the line already exists, append `,ImagePolicyWebhook` to it.

Save the file — **kubelet automatically restarts kube-apiserver**.

Check API server is running:

```bash
kubectl get pods -n kube-system
```

---

# ✅ Step 5 — Test using the provided ReplicationController YAML

The exam will give you something like:

```yaml
kubectl apply -f test-rc.yaml
```

The expected behavior:

* If the image is ALLOWED → RC is created
* If the image is DENIED → RC creation fails

Run:

```bash
kubectl apply -f test-rc.yaml
```

Check:

```bash
kubectl describe rc test-rc
```

Or check API server logs:

```bash
sudo journalctl -u kubelet -f
```
---

## Question 14

> **Part 1:**
>
> You have **three Deployments** of Ollama in your cluster. All three Deployments have pods with `SecurityContext: privileged=true`.
>
> You must determine **which pod writes to `/dev/mem`**.
>
> Identify the offending pod and mention **Falco** as the recommended tool for this detection.
>
> ---
>
> **Part 2:**
>
> Solve this question on: `ssh cks7262`
>
> Falco is installed on worker node `cks7262-node1`. Connect using `ssh cks7262-node1` from `cks7262`. There is a file `/etc/falco/rules.d/falco_custom.yaml` with rules that help you to:
>
> 1. Find a Pod running image `httpd` which modifies `/etc/passwd`.
>
>    Scale the Deployment that controls that Pod down to 0.
>
> 2. Find a Pod running image `nginx` which triggers rule "Package management process launched".
>
>    Change the rule log text after "Package management process launched" to only include:
>
>    `time-with-nanoseconds, container-id, container-name, user-name`
>
>    Collect the logs for at least 20 seconds and save them under `/opt/course/2/falco.log` on `cks7262`.
>
>    Scale the Deployment that controls that Pod down to 0.

> **Note:** Additional resources:
> - https://www.youtube.com/watch?v=K6rSAInLrQk&list=PLHBCinpJDX3yBb4nJNxoMeWN5pous2Mp5&index=2
> - https://www.youtube.com/watch?v=x_klpjAilMs

---

### Solution:
---

# ✅ **Step 1 — Check security context of the 3 Deployments**

(Quick visual verification)

```bash
kubectl get deploy -n <ns>
kubectl describe deploy <name> -n <ns> | grep -i privileged -A3
```

This tells you which Deployments have:

```yaml
securityContext:
  privileged: true
```

But this **does NOT tell you which one writes to /dev/mem**.

---

# ✅ **Step 2 — Use Falco to detect writes to `/dev/mem`**

Falco has an official rule detecting this behavior:

---

## 📘 **Falco Documentation Reference (important for CKS)**

Falco rule: **“Write below /dev”** or **"Write to special files like /dev/mem"**

Rule file locations:

* `/etc/falco/falco_rules.yaml`
* `/etc/falco/rules.d/`

Rule example:

```yaml
- rule: Write to dev mem
  desc: Detect any write attempt to /dev/mem
  condition: evt.type=write and fd.name=/dev/mem
  output: "Write to /dev/mem detected (user=%user.name pod=%k8s.pod.name container=%container.name)"  # add namesapce and pod name
  priority: CRITICAL
```

---

# ✅ **Step 3 — Run Falco and identify the pod**

**Note:** Falco may not be installed as a service. Use `falco -U` for monitoring.

Start Falco and monitor output:

```bash
# Primary method (if Falco is not installed as service)
sudo falco -U

# Alternative (if Falco is running as service)
sudo journalctl -u falco -f
```

Or run Falco with custom rules:

```bash
sudo falco -r /etc/falco/rules.d/falco_custom.yaml -U
```

Expected alert:

```
Write to /dev/mem detected (pod=ollama-deploy-2-xxx container=ollama)
```

This gives you:

* Pod name
* Deployment name
* Container name

---

# ✅ **Step 4 — Answer (CKS-style)**

**The pod that wrote to `/dev/mem` is the one Falco reported in the alert stream.**

Falco is the **correct Kubernetes runtime security tool** to detect writes to kernel memory devices such as `/dev/mem`.

---

# ✅ **Part 2 Solution — Falco Tasks on cks7262-node1**

## **Task 1: Find httpd Pod Modifying /etc/passwd**

### Step 1 — Connect to the worker node

```bash
ssh cks7262-node1
```

### Step 2 — Check Falco custom rules

```bash
cat /etc/falco/rules.d/falco_custom.yaml
```

### Step 3 — Monitor Falco logs for httpd pod modifying /etc/passwd

**Note:** Falco may not be installed as a service. Use `falco -U` for monitoring.

```bash
# Primary method: Run Falco directly with custom rules
sudo falco -r /etc/falco/rules.d/falco_custom.yaml -U | grep -i "httpd\|/etc/passwd"

# Alternative (if Falco is running as service)
sudo journalctl -u falco -f | grep -i "httpd\|/etc/passwd"
```

If Falco service exists but is not running:

```bash
sudo systemctl start falco
sudo systemctl status falco
```

### Step 4 — Identify the pod from Falco output

Look for alerts like:

```
Pod running image httpd modified /etc/passwd (pod=httpd-deploy-xxx container=httpd namespace=default)
```

Note the pod name and namespace.

### Step 5 — Find the Deployment and scale it down

```bash
# From cks7262 (master node)
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.metadata.ownerReferences[0].name}'

# Get the Deployment name
kubectl get deploy -n <namespace> | grep httpd

# Scale down to 0
kubectl scale deploy <deployment-name> -n <namespace> --replicas=0
```

---

## **Task 2: Find nginx Pod Triggering "Package management process launched"**

### Step 1 — Modify the Falco rule log format

Edit the custom rules file:

```bash
sudo vim /etc/falco/rules.d/falco_custom.yaml
```

Find the rule "Package management process launched" and modify the `output` field to only include:

```yaml
- rule: Package management process launched
  desc: Detect package management processes
  condition: package_mgmt_procs
  output: "%evt.time.s, %container.id, %container.name, %user.name"
  priority: WARNING
```

Save the file.

### Step 2 — Restart Falco to apply changes

**Note:** Falco may not be installed as a service. If running directly, stop with Ctrl+C and restart.

If Falco is running as service:

```bash
sudo systemctl restart falco
```

If running Falco directly:

```bash
# Stop current Falco process (Ctrl+C)
# Restart with updated rules
sudo falco -r /etc/falco/rules.d/falco_custom.yaml -U
```

### Step 3 — Monitor Falco logs for nginx pod

**Note:** Use `falco -U` for monitoring if Falco is not installed as a service.

```bash
# Primary method: Run Falco directly with custom rules
sudo falco -r /etc/falco/rules.d/falco_custom.yaml -U | grep -i "nginx\|package"

# Alternative (if Falco is running as service)
sudo journalctl -u falco -f | grep -i "nginx\|package"
```

### Step 4 — Collect logs for at least 20 seconds

From `cks7262-node1`:

**Note:** Use `falco -U` if Falco is not installed as a service.

```bash
# Primary method: Run Falco directly (if not installed as service)
sudo timeout 20s falco -r /etc/falco/rules.d/falco_custom.yaml -U > /tmp/falco.log

# Alternative (if Falco is running as service)
sudo timeout 20s journalctl -u falco -f > /tmp/falco.log
```

### Step 5 — Copy logs to cks7262

```bash
# From cks7262-node1, copy to cks7262
scp /tmp/falco.log cks7262:/opt/course/2/falco.log

# Or if you're already on cks7262-node1, you can use:
# Make sure the directory exists on cks7262 first
ssh cks7262 "mkdir -p /opt/course/2"
scp /tmp/falco.log cks7262:/opt/course/2/falco.log
```

Alternatively, if you have direct access from cks7262-node1 to the path:

```bash
# From cks7262-node1 (using falco -U)
sudo timeout 20s falco -r /etc/falco/rules.d/falco_custom.yaml -U | ssh cks7262 "cat > /opt/course/2/falco.log"

# Or if Falco is running as service
sudo timeout 20s journalctl -u falco -f | ssh cks7262 "cat > /opt/course/2/falco.log"
```

### Step 6 — Identify the nginx pod and scale down

From `cks7262`:

```bash
# Find nginx pods
kubectl get pods -A | grep nginx

# Get the Deployment name
kubectl get pod <nginx-pod-name> -n <namespace> -o jsonpath='{.metadata.ownerReferences[0].name}'

# Scale down to 0
kubectl scale deploy <deployment-name> -n <namespace> --replicas=0
```

### Step 7 — Verify the log file format

```bash
# On cks7262
cat /opt/course/2/falco.log
```

The log should contain entries in the format:

```
2024-01-15T10:30:45.123456789, abc123def456, nginx-container, root
```

Each line should have: `time-with-nanoseconds, container-id, container-name, user-name`

---

## **Quick Reference Commands**

```bash
# Connect to worker node
ssh cks7262-node1

# View custom rules
cat /etc/falco/rules.d/falco_custom.yaml

# Edit rules
sudo vim /etc/falco/rules.d/falco_custom.yaml

# Run Falco directly (primary method - if not installed as service)
sudo falco -r /etc/falco/rules.d/falco_custom.yaml -U

# Monitor Falco logs (if running as service)
sudo systemctl restart falco
sudo journalctl -u falco -f

# Collect logs for 20 seconds (primary method)
sudo timeout 20s falco -r /etc/falco/rules.d/falco_custom.yaml -U > /tmp/falco.log

# Collect logs for 20 seconds (if running as service)
sudo timeout 20s journalctl -u falco -f > /tmp/falco.log

# Copy to master node
scp /tmp/falco.log cks7262:/opt/course/2/falco.log

# Find and scale deployments
kubectl get pods -A | grep httpd
kubectl get pods -A | grep nginx
kubectl scale deploy <name> -n <namespace> --replicas=0
```

---

## Question 15
You have a Pod with **3 containers**:

```
alpine:3.14
alpine:3.16
alpine:3.18
```

You need to:

1. Scan all three images
2. Find which image contains **libproc_ar version 1.3-45**
3. Generate a BOM
4. Redirect the output to `spdx.json`

You must use: **bom** (Syft-style tool)

---

### Solution:


Credit: Anchore (open-source) — used for SBOM generation.

Installed name varies, either:

```
syft
```

or:

```
bom
```

Exam commonly uses:

```
bom
```

---

# ✅ **Step 1 — Pull all Alpine images**

If not already pulled:

```bash
docker pull alpine:3.14
docker pull alpine:3.16
docker pull alpine:3.18
```

---

# ✅ **Step 2 — Scan each image for the library**

Run:

```bash
bom alpine:3.14 | grep -i libproc_ar
bom alpine:3.16 | grep -i libproc_ar
bom alpine:3.18 | grep -i libproc_ar
```

You search for version **1.3-45**.

Example of expected match:

```
libproc_ar 1.3-45  apk
```

---

# 🟩 **Result:**

The image that shows:

```
libproc_ar 1.3-45
```

is the one required by the question.

(Usually Alpine 3.14 or 3.16 contains this version, depending on exam version.)

---

# ✅ **Step 3 — Generate SPDX SBOM for that image**

Example: if the vulnerable image is `alpine:3.16`

```bash
bom alpine:3.16 -o spdx-json > spdx.json
```

Or using syft syntax:

```bash
syft alpine:3.16 -o spdx-json > spdx.json
```

---

# 🎯 **CKS exam expects the EXACT output redirection line:**

```
> spdx.json
```

---

## Question 16

> Configure Istio service mesh to enforce **mutual TLS (mTLS)** for a specific workload in namespace `my-namespace`.
>
> 1. Enable Istio sidecar injection for the namespace `my-namespace`.
> 2. Create a **PeerAuthentication** resource named `workload-mtls` in namespace `my-namespace` that enforces **STRICT** mTLS mode for pods with label `app: my-app`.

---

### Solution:

**Reference:**
- https://istio.io/latest/docs/tasks/security/authentication/mtls-migration/
- https://istio.io/latest/docs/reference/config/analysis/ist0102/

```bash
kubectl label namespace <namespace-name> istio-injection=enabled
```

Pod-Level mTLS Enforcement Example

```yaml

apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: workload-mtls
  namespace: my-namespace
spec:
  selector:
    matchLabels:
      app: my-app
  mtls:
    mode: STRICT
```
