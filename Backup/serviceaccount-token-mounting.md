
---
## Question 1 

Modify the the config file /opt/ks/pod-one.yaml to disable the mounting of the ServiceAccount token into that Pod.

Apply the modified file /opt/ks/pod-one.yaml to Namespace one .

Verify that the ServiceAccount token hasn't been mounted into the Pod.

### Solution:
```bash
controlplane:~$ cat /opt/ks/pod-one.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-one
  namespace: one
spec:
  serviceAccountName: custom
  containers:
  - name: webserver
    image: nginx:1.19.6-alpine
    ports:
    - containerPort: 80
```

```bash
apiVersion: v1
kind: Pod
metadata:
  name: pod-one
  namespace: one
spec:
  serviceAccountName: custom
  automountServiceAccountToken: false
  containers:
  - name: webserver
    image: nginx:1.19.6-alpine
    ports:
    - containerPort: 80

```

```bash
 k exec -n one pod-one -it -- sh
/ # cat /var/
cache/  empty/  lib/    local/  lock/   log/    mail/   opt/    run/    spool/  tmp/
/ # cat /var/run/secrets/kubernetes.io/serviceaccount/token
cat: can't open '/var/run/secrets/kubernetes.io/serviceaccount/token': No such file or directory
```

---
## Question 2

Modify the default ServiceAccount in Namespace two to prevent any Pod that uses it from mounting its token by default.

Apply the Pod configuration file /opt/ks/pod-two.yaml to Namespace two .

Verify that the ServiceAccount token hasn't been mounted into the Pod.

### Solution:

```bash
controlplane:~$ k config set-context --current --namespace two
Context "kubernetes-admin@kubernetes" modified.
controlplane:~$ k get sa
NAME      SECRETS   AGE
default   0         5m16s
controlplane:~$ k edit sa default 
serviceaccount/default edited
controlplane:~$ k get sa default -o yaml 
apiVersion: v1
automountServiceAccountToken: false
kind: ServiceAccount
metadata:
  creationTimestamp: "2025-11-15T02:45:08Z"
  name: default
  namespace: two
  resourceVersion: "25173"
  uid: 74128159-52bc-448f-b51c-23c696f0e152
controlplane:~$ k apply -f /opt/ks/pod-two.yaml -n two
pod/pod-two created
controlplane:~$ k exec -n two pod-two -it -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
cat: can't open '/var/run/secrets/kubernetes.io/serviceaccount/token': No such file or directory
command terminated with exit code 1
controlplane:~$ 
```