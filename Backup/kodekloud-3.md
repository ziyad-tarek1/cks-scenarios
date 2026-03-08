# kodekloud Mock Exam CKS Practice Questions

---

## Question 1

You are setting up a new Kubernetes cluster and need to secure Docker as part of the cluster setup.

Ensure that docker runs under the "root" group and that no external TCP connections are allowed to the docker daemon.

Ensure the configuration is persistent across restarts.

**Verification Questions:**
- Is docker modified to run as part of the root group?
- Has the docker daemon been modified to have no external TCP connections?

### Solution 1

**Solution**

Change the ownership of the docker file:

```bash
sudo chown root:root /var/run/docker.sock
```

Then add `--group=root` to the ExecStart of docker systemd file:

```bash
sudo systemctl edit docker
```

Add the following configuration:

```ini
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --group=root
```

Then reload the docker daemon:

```bash
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl restart docker
```

To remove the TCP external connections, modify the `/etc/docker/daemon.json` to remove the tcp section so that the file looks like this:

```json
{
  "hosts": ["unix:///var/run/docker.sock"]
}
```

Then restart docker again.

---

## Question 2

A pod definition file has been created at `/root/CKS/simple-pod.yaml`. Using the kubesec tool, generate a report for this pod definition file and fix the major issues so that the subsequent scan report no longer fails.

Once done, generate the final report and save it to the file `/root/CKS/kubesec-report.txt`.

**Verification Questions:**
- Is the pod definition file fixed?
- Is the report generated at `/root/CKS/kubesec-report.txt`?

### Solution 2

**Solution**

Remove the `SYS_ADMIN` capability from the container for the `simple-webapp-1` pod in the POD definition file and re-run the scan.

```bash
kubesec scan /root/CKS/simple-pod.yaml > /root/CKS/kubesec-report.txt
```

The fixed report should PASS with a message like this:

```json
[
  {
    "object": "Pod/simple-webapp-1.default",
    "valid": true,
    "fileName": "simple-pod.yaml",
    "message": "Passed with a score of 0 points",
    "score": 0
  }
]
```

---

## Question 3

Enable auditing on this cluster using the basic policy file available at `/etc/kubernetes/cluster-policy.yaml`.

Store the logs at `/var/log/cluster-audit.log` and ensure they are retained for 10 days. The log size should not exceed 10MB and up to a maximum of 3 files should be kept at a time.

After enabling auditing on the cluster, update the basic policy file to track the following:

- Delete activity on secrets in the `kube-system` namespace at the Metadata level
- Changes to deployments in the `default` namespace at the Request level
- All other requests at the Metadata level

Ensure that the updated policy is applied and in effect.

**Note:** A copy of the `kube-apiserver.yaml` is available in `~/` so you can revert if the configuration goes wrong. Ensure that the kube-apiserver is working correctly, as it will be required for grading the exam.

**Verification Questions:**
- Does `/var/log/cluster-audit.log` exist with the logs written to it?
- Does auditing follow the mentioned parameters as specified in the question?
- Is the delete activity on secrets tracked at the Metadata level in the `kube-system` namespace?
- Is the edit activity on deployments tracked at the Request level in the `default` namespace?

### Solution 3

First complete the `/etc/kubernetes/cluster-policy.yaml`:

```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:
  - "RequestReceived"
rules:
  - level: Metadata
    verbs: ["delete"]
    resources:
      - group: ""
        resources: ["secrets"]
    namespaces: ["kube-system"]
  - level: Request
    verbs: ["create", "update", "patch", "delete"]
    resources:
      - group: "apps"
        resources: ["deployments"]
    namespaces: ["default"]
  - level: Metadata
```

Then add/modify the properties in the `/etc/kubernetes/manifests/kube-apiserver.yaml` file. First add these flags:

```yaml
- --audit-policy-file=/etc/kubernetes/cluster-policy.yaml
- --audit-log-path=/var/log/cluster-audit.log
- --audit-log-maxage=10
- --audit-log-maxbackup=3
- --audit-log-maxsize=10
```

Under volumes section in the same file, add the following:

```yaml
volumes:
  - name: audit-policy
    hostPath:
      path: /etc/kubernetes/cluster-policy.yaml
      type: File
  - name: varlog
    hostPath:
      path: /var/log
      type: Directory
```

Under volumeMounts section in the same file, add the following as well:

```yaml
- mountPath: /etc/kubernetes/cluster-policy.yaml
  name: audit-policy
  readOnly: true
- mountPath: /var/log
  name: varlog
```

Save and exit the file. Then run the following command to check the status of the api server and other components:

```bash
kubectl get pods -n kube-system
```

Wait till all components come up in a running state.

Finally, check the status of the log file:

```bash
ls -l /var/log/cluster-audit.log
```

The file should be automatically created and should now start storing logs.

---

## Question 4

Create a service account named `bot-sa` in the `automated` namespace. Ensure that it does not get automatically mounted to workloads.

A workload named `sweeper` also exists in the same namespace. Update this deployment to use the newly created service account, and mount the service account token as a projected volume. Do not change any other fields in the deployment.

**Verification Questions:**
- Has the service account `bot-sa` been created without auto-mount?
- Has the `bot-sa` service account been set as the deployment's service account?
- Has the `bot-sa` service account token been mounted to the deployment as a projected volume?
- No default auto-mount on the Pod?

### Solution 4

Create the ServiceAccount `bot-sa` without auto-mount:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: bot-sa
  namespace: automated
automountServiceAccountToken: false
```

Then, update the existing `sweeper` deployment in the automated namespace to:

- Use the new `bot-sa` service account
- Manually mount the service account token via a projected volume

Recreate the deployment or edit it with the following definition:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sweeper
  namespace: automated
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sweeper
  template:
    metadata:
      labels:
        app: sweeper
    spec:
      serviceAccountName: bot-sa    # Added
      automountServiceAccountToken: false  # Prevent auto-mount
      containers:
        - name: sweeper
          image: busybox:1.36
          command: ["sleep", "3600"]
          volumeMounts:    # Section added
            - name: sa-token
              mountPath: /var/run/secrets/tokens
              readOnly: true
      volumes:   # Section added
        - name: sa-token
          projected:
            sources:
              - serviceAccountToken:
                  path: bot-token
                  expirationSeconds: 3600
                  audience: default
```

The token is now manually mounted as a projected volume at `/var/run/secrets/tokens/bot-token`.

---

## Question 5

Create a new pod called `audit-nginx` in the default namespace using the `nginx` image. Secure the syscalls that this pod can use by using the `audit.json` seccomp profile in the pod's security context.

The `audit.json` file is located in the `/root/CKS` directory. Before creating the pod, move it to the profiles directory inside the default seccomp directory.

**Verification Questions:**
- Does `audit-nginx` use the right image?
- Is the pod running?
- Does the pod use the correct seccomp profile?

### Solution 5

Copy the `audit.json` seccomp profile to `/var/lib/kubelet/seccomp/profiles` on the controlplane node:

```bash
mv /root/CKS/audit.json /var/lib/kubelet/seccomp/profiles
```

Next, create the pod using the below YAML File:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: nginx
  name: audit-nginx
spec:
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: profiles/audit.json
  containers:
  - image: nginx
    name: nginx
```

---

## Question 6

We want to deploy an ImagePolicyWebhook admission controller to secure the deployments in our cluster.

Fix the error in `/etc/kubernetes/pki/admission_configuration.yaml` which will be used by ImagePolicyWebhook.

Ensure that the policy is set to implicit deny. If the webhook service is not reachable, the configuration should automatically reject all images.

Enable the plugin on the API server.

The kubeconfig file for the existing imagepolicywebhook resources is located at `/etc/kubernetes/pki/admission_kube_config.yaml`.

**Verification Questions:**
- Is the `admission_configuration.yaml` fixed?
- Is the deny policy implicit?
- Is the imagepolicywebhook enabled on the API server?
- Is the imagepolicywebhook config added on the API server?

### Solution 6

Update `/etc/kubernetes/pki/admission_configuration.yaml` and add the path to the kubeconfig file:

```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  configuration:
    imagePolicy:
      kubeConfigFile: /etc/kubernetes/pki/admission_kube_config.yaml
      allowTTL: 50
      denyTTL: 50
      retryBackoff: 500
      defaultAllow: false
```

Update `/etc/kubernetes/manifests/kube-apiserver.yaml` as below:

```yaml
- --enable-admission-plugins=NodeRestriction,ImagePolicyWebhook
- --admission-control-config-file=/etc/kubernetes/pki/admission_configuration.yaml
```

API server will automatically restart and pickup this configuration.

---

## Question 7

Delete all pods from the `alpha` namespace that are not immutable.

**Note:** A pod is considered non-immutable if it uses elevated privileges or can store state inside the container.

**Verification Questions:**
- Is the non-immutable pod deleted?
- Is the immutable pod running?

### Solution 7

Pod `solaris` is immutable as it has `readOnlyRootFilesystem: true` so it should not be deleted.

Pod `sonata` is running with `privileged: true` and `triton` doesn't define `readOnlyRootFilesystem: true` so both break the concept of immutability and should be deleted.

---

## Question 8

You have an existing Kubernetes setup with the following services running:

**Namespace:**
- `system-hardening`

**Pods:**
- `nginx-internal` (Accessible internally)
- `nginx-external` (Exposed externally via NodePort service)

**Services:**
- `nginx-internal-service` (Exposed as ClusterIP - internal-only)
- `nginx-external-service` (Exposed as NodePort - accessible externally)

**Objective:**
Your task is to disable or unexpose ports to minimize external access to unnecessary services.

**Verification Questions:**
- Has the service type for `nginx-external-service` been changed to ClusterIP?

### Solution 8

We will change the `nginx-external-service` to be only accessible within the cluster by changing its service type to ClusterIP.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-external-service
  namespace: system-hardening
spec:
  selector:
    app: nginx-external
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
    - name: https
      protocol: TCP
      port: 443
      targetPort: 443
  type: ClusterIP
```

Save it as `nginx-external-service-clusterip.yaml`.

Apply the change:

```bash
kubectl replace -f nginx-external-service-clusterip.yaml
```

If we don't need the internal service exposed anymore (or it's for testing purposes), we can delete it.

```bash
kubectl -n system-hardening delete svc nginx-internal-service
```

This will stop the internal service from being available. However, you could also leave it as-is if you want to keep testing internal services.

---

## Question 9

A deployment named `web-server` is running in namespace `restricted`.

Identify why the deployment is not in a running state, and then fix the issue so that it is in a running state.

**Verification Questions:**
- Has the deployment been fixed, and is the pod in a running state?

### Solution 9

First check the status of the web-server deployment:

```bash
kubectl get deployments.apps -n restricted
```

You should see the READY column showing `0/1` which means the pod is not running.

Then run the following command:

```bash
kubectl describe deployments.apps web-server -n restricted
```

In the output, check the Conditions section:

```
Conditions:
  Type             Status  Reason
  ----             ------  ------
  Progressing      True    NewReplicaSetCreated
  Available        False   MinimumReplicasUnavailable
  ReplicaFailure   True    FailedCreate
```

This shows that the replica creation failed. Let's find out the reason why:

```bash
kubectl describe replicaset -n restricted
```

The Events section will provide the exact error cause:

```
  Warning  FailedCreate  25s (x6 over 105s)  replicaset-controller  (combined from similar events): Error creating: pods "web-server-7d8b84ccc8-9ppsm" is forbidden: violates PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "nginx" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "nginx" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "nginx" must set securityContext.runAsNonRoot=true), runAsUser=0 (container "nginx" must not set runAsUser=0), seccompProfile (pod or container "nginx" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
```

This confirms the pod was blocked by Pod Security Admission (PSA) because it doesn't meet the restricted security policy.
Now, check that the namespace is labeled to enforce the restricted policy:

```bash
kubectl get namespace restricted --show-labels
```

You should see this label present: `pod-security.kubernetes.io/enforce=restricted` which means kubernetes is actively enforcing restricted-level pod Security in this namespace.

According to the Events section of the replicaset, we need to make some changes in our deployment's securityContext section. Open the deployment file to edit:

```bash
kubectl edit deployment web-server -n restricted
```

Enter insert mode by typing `i` and change the securityContext section under `spec.containers` as follows:

```yaml
securityContext:
    allowPrivilegeEscalation: false
    capabilities:
      drop:
      - ALL
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
```

Also, remove `runAsUser: 0` and then press `Esc` followed by `:wq!`. This will save the changes.

You should then see the pod in a running state:

```bash
kubectl get pods -n restricted
```

Output:
```
NAME                          READY   STATUS    RESTARTS   AGE
web-server-55549f978f-lgp8w   1/1     Running   0          5m
```

---

## Question 10

Configure the kubelet on the `cluster2-controlplane` node to disallow anonymous authentication.

The admin kubeconfig file for this cluster is located at:
`/root/custom-config/admin.conf`

Additionally, utilize this kubeconfig file to delete the role `custom-role` in namespace `delta`.

**Verification Questions:**
- Has anonymous auth been disabled on the kubelet?
- Is the cluster not accessible without passing the `--kubeconfig` flag with kubectl?
- Has the `custom-role` been deleted?

### Solution 10

First ssh to cluster2-controlplane cluster:

```bash
ssh cluster2-controlplane
```

Then, open the kubelet config file to edit:

```bash
sudo nano /var/lib/kubelet/config.yaml
```

and change the `authentication.anonymous.enabled` to `false`:

```yaml
authentication:
  anonymous:
    enabled: false
```

and `authorization.mode` to `Webhook`:

```yaml
authorization:
  mode: Webhook
```

Save and exit the file and then restart the kubelet:

```bash
sudo systemctl restart kubelet
```

To make the cluster info inaccessible without the kubeconfig flag:

```bash
mv ~/.kube/config ~/.kube/config.bak
unset KUBECONFIG
```

The kubernetes commands should then not work without using `--kubeconfig=/root/custom-config/admin.conf`.

Now delete the `custom-role` using this kubeconfig file:

```bash
kubectl delete role custom-role -n delta --kubeconfig=/root/custom-config/admin.conf
```

---

## Question 11

A deployment named `fruits` in the namespace `salad` has three containers:

- apple
- banana, and
- kiwi

One of these containers has the package `curl` installed. Identify which container has that package from the running containers, and create an SBOM SPDX for the container's image.

Use the tarball archive of that particular image stored under `/root/ImageTarballs` directory for generating the SPDX JSON. The archives have names matching their images.

Save the output in `~/bugged-fruit.spdx`. Save the container name in `~/bugged-container.txt`.

**Note:** bom and all its required dependencies have already been installed.

**Verification Questions:**
- Is the SPDX JSON SBOM format for the image with curl installed stored at `~/bugged-fruit.spdx`?
- Is the container name stored in `~/bugged-container.txt`?

### Solution 11

First check the deployment running in the salad namespace:

```bash
kubectl get deployments -n salad
```

Then, run the following commands in succession to fetch the container name in the text file:

```bash
kubectl exec -n salad fruits-<string> -c apple -- apk info | grep curl && echo apple > ~/bugged-container.txt
```

Replace `<string>` with the actual random string in your pod name.

Do the same for kiwi and banana as well.

Determine the image name used in that container by describing the pod and checking the Containers section in the output:

```bash
kubectl describe pod fruits-54665c68db-mcwg9 -n salad
```

Your pod name could be different.

Once you have determined the image name, navigate to the `/root/ImageTarballs/` directory and identify the tarball of that image by its name.

Then run the following command to generate the SPDX JSON:

```bash
bom generate --image-archive /root/ImageTarballs/<image_name>.tar --format json --output ~/bugged-fruit.spdx
```

Replace the `<image_name>` with the actual name of the tar file.

---

## Question 12

In the `space` namespace, a deployment `rocket-server` is exposed by a service of the same name.

Create an ingress resource named `rocket-ingress` to load balance the incoming traffic to the workload on path `/`.

Use the hostname `rocket-server.local` for the Ingress rules.

Utilize the TLS certificate stored in the secret `rocket-tls` in the `space` namespace to enable TLS traffic on that ingress resource.

**Verification Questions:**
- Is the ingress resource correctly created?
- Has the ingress TLS secret been attached?
- Does the ingress route to the correct path and port?
- Is curl working for the HTTPS connection via the ingress?

### Solution 12

Run the command:

```bash
kubectl describe deployment rocket-server -n space
```

and check the Port field under Pod Template -> Containers.

Then create and apply the following ingress yaml file:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rocket-ingress
  namespace: space
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - rocket-server.local
      secretName: rocket-tls
  rules:
    - host: rocket-server.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: rocket-server
                port:
                  number: 80
```

Once that is done, check the IP address under CLUSTER-IP header of the ingress-nginx-controller:

```bash
kubectl get svc -n ingress-nginx
```

Then add this IP to the `/etc/hosts` file:

```bash
echo "<INGRESS-IP> rocket-server.local" | sudo tee -a /etc/hosts
```

Finally you can check the working:

```bash
curl -k https://rocket-server.local
```

You should see the nginx welcome page.

---

## Question 13

In the namespace `code`, create a TLS secret `code-secret` using the following certificate and key:

- cert: `/root/custom-cert.crt`
- key: `/root/custom-key.key`

Attach this secret as a volume named `secret-volume` in the deployment `code-server`.

**Verification Questions:**
- Is the `code-secret` secret created in the namespace `code` with the mentioned specs?
- Is the secret mounted as a volume on the container in the deployment `code-server`?

### Solution 13

First create the TLS secret:

```bash
kubectl create secret tls code-secret \
  --cert=/root/custom-cert.crt \
  --key=/root/custom-key.key \
  -n code
```

Then edit the deployment to mount the secret:

```bash
kubectl edit deployment code-server -n code
```

Under the `spec.template.spec` section, add:

```yaml
volumes:
  - name: secret-volume
    secret:
      secretName: code-secret
```

Under the `spec.template.spec.containers` section, add the volume mount then:

```yaml
volumeMounts:
  - name: secret-volume
    mountPath: /etc/code/tls
    readOnly: true
```

Save and exit the deployment.

---

## Question 14

`jacob` is a developer who needs access to work on the `dev-a`, `dev-b` and `dev-z` namespace. He should have the ability to carry out any operation on any pod in `dev-a` and `dev-b` namespaces.

However, on the `dev-z` namespace, he should only have the following permissions:

- get, list, and watch pods
- get and list configmaps
- No access at all to secrets

The current setup is too permissive and does not meet the above condition. Update the permissions to secure jacob's access in the cluster. You may re-create objects, but ensure that the resource names remain unchanged.

**Verification Questions:**
- Does jacob have unrestricted access to all pods in `dev-a`?
- Does jacob have unrestricted access to all pods in `dev-b`?
- Can jacob only list, get, and watch pods in `dev-z`?
- Can jacob only list and get configmaps in `dev-z`?
- Does jacob have no access to secrets in `dev-z`?

### Solution 14

The role called `dev-user-access` has been created for all three namespaces: `dev-a`, `dev-b` and `dev-z`. However, the role in the `dev-z` namespace grants jacob access to all operation on all pods. To fix this, delete and re-create the role using the following YAML:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
    name: dev-user-access
    namespace: dev-z
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list"]
```

---

## Question 15

The administrator has partially upgraded cluster1.

Complete the upgrade process by updating the worker node to the latest installed version available among the nodes.

**Verification Questions:**
- Has the worker node been upgraded to the correct version?
- Is the worker node in a ready state?

### Solution 15

**Solution**

First run the following command from the controlplane node:

```bash
kubectl get nodes
```

You should get an output like below, indicating that the worker node node02 is at an earlier version of kubernetes:

```
NAME                    STATUS   ROLES           AGE   VERSION
cluster1-controlplane   Ready    control-plane   49m   v1.34.0
node02                  Ready    worker          29m   v1.33.0
```

SSH into the node02 node:

```bash
ssh node02
```

Use any text editor you prefer to open the file that defines the Kubernetes apt repository.

```bash
vim /etc/apt/sources.list.d/kubernetes.list
```

Update the version in the URL to the next available minor release, i.e v1.34.

```
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /
```

After making changes, save the file and exit from your text editor. Proceed with the next instruction.

```bash
echo 'y' | curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

```bash
sudo apt-get update
```

```bash
apt-cache madison kubeadm
```

Momentarily go back to cluster1-controlplane node to drain the worker node:

```bash
kubectl drain node02 --ignore-daemonsets --delete-emptydir-data
```

Based on the version information displayed by `apt-cache madison`, it indicates that for Kubernetes version 1.34.0, the available package version is `1.34.0-1.1`. Therefore, to install kubeadm for Kubernetes v1.34.0, use the following command:

```bash
sudo apt-get install -y kubeadm=1.34.0-1.1
```

Run the following command to upgrade the node:

```bash
sudo kubeadm upgrade node
```

Unhold kubeadm if it's on hold while upgrading or use the appropriate suggestion mentioned in the output.

**Note:** The above steps can take a few minutes to complete.

Now, unhold and then upgrade the kubelet and kubectl versions:

```bash
sudo apt-mark unhold kubelet kubectl
sudo apt-get install --allow-change-held-packages -y kubelet=1.34.0-1.1 kubectl=1.34.0-1.1
```

Optionally hold them again:

```bash
sudo apt-mark hold kubelet kubectl
```

Run the following commands to refresh the systemd configuration and apply changes to the Kubelet service:

```bash
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

Go back to the controlplane node again and uncordon node02:

```bash
kubectl uncordon node02
```

Finally verify the version upgrade:

```bash
kubectl get nodes
```

This should now show both at v1.34:

```
NAME                    STATUS   ROLES           AGE   VERSION
cluster1-controlplane   Ready    control-plane   70m   v1.34.0
node02                  Ready    worker          50m   v1.34.0
```
