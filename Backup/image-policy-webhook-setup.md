---
## Question 1 

An ImagePolicyWebhook setup has been half finished, complete it:

Make sure admission_config.json points to correct kubeconfig
Set the allowTTL to 100
All Pod creation should be prevented if the external service is not reachable
The external service will be reachable under https://localhost:1234 in the future. It doesn't exist yet so it shouldn't be able to create any Pods till then
Register the correct admission plugin in the apiserver

### Solution:

```json
{
   "apiVersion": "apiserver.config.k8s.io/v1",
   "kind": "AdmissionConfiguration",
   "plugins": [
      {
         "name": "ImagePolicyWebhook",
         "configuration": {
            "imagePolicy": {
               "kubeConfigFile": "/etc/kubernetes/policywebhook/kubeconf",
               "allowTTL": 100,
               "denyTTL": 50,
               "retryBackoff": 500,
               "defaultAllow": false
            }
         }
      }
   ]
}
```

```bash
controlplane:/etc/kubernetes/policywebhook$ cat kubeconf 
apiVersion: v1
kind: Config

# clusters refers to the remote service.
clusters:
- cluster:
    certificate-authority: /etc/kubernetes/policywebhook/external-cert.pem  # CA for verifying the remote service.
    server: TODO                   # URL of remote service to query. Must use 'https'.
  name: image-checker

contexts:
- context:
    cluster: image-checker
    user: api-server
  name: image-checker
current-context: image-checker
preferences: {}

# users refers to the API server's webhook configuration.
users:
- name: api-server
  user:
    client-certificate: /etc/kubernetes/policywebhook/apiserver-client-cert.pem     # cert for the webhook admission controller to use
    client-key:  /etc/kubernetes/policywebhook/apiserver-client-key.pem             # key matching the cert
controlplane:/etc/kubernetes/policywebhook$ ls
admission_config.json  apiserver-client-cert.pem  apiserver-client-key.pem  external-cert.pem  external-key.pem  kubeconf
controlplane:/etc/kubernetes/policywebhook$ ls external-cert.pem  
external-cert.pem
controlplane:/etc/kubernetes/policywebhook$ vim kubeconf 
controlplane:/etc/kubernetes/policywebhook$ cat kubeconf 
apiVersion: v1
kind: Config

# clusters refers to the remote service.
clusters:
- cluster:
    certificate-authority: /etc/kubernetes/policywebhook/external-cert.pem  # CA for verifying the remote service.
    server: https://localhost:1234                # URL of remote service to query. Must use 'https'.
  name: image-checker

contexts:
- context:
    cluster: image-checker
    user: api-server
  name: image-checker
current-context: image-checker
preferences: {}

# users refers to the API server's webhook configuration.
users:
- name: api-server
  user:
    client-certificate: /etc/kubernetes/policywebhook/apiserver-client-cert.pem     # cert for the webhook admission controller to use
    client-key:  /etc/kubernetes/policywebhook/apiserver-client-key.pem             # key matching the cert
controlplane:/etc/kubernetes/policywebhook$ 
```

```bash
cat kube-apiserver.yaml | grep -iE "enable-admission-plugins|admission-control-config-fi
le"
    - --enable-admission-plugins=NodeRestriction,ImagePolicyWebhook
    - --admission-control-config-file=/etc/kubernetes/policywebhook/admission_config.json
```