Question 1:
Between what two Kubernetes network components will a fundamental Kubernetes networking trust be violated?

Answer:
API Server to Container Runtime

Overall explanation
CORRECT ANSWER:
API Server to Container Runtime - This path would be problematic as the API Server should not communicate directly with the Container Runtime. Communication is typically through the Kubelet, so a direct link indicates a fundamental networking trust issue.

WRONG ANSWERS:
Kubelet to API Server - This is normal and expected. The Kubelet communicates with the API Server to report pod status and receive instructions.

Controller Manager to API Server - This is a standard communication path. The Controller Manager uses the API Server to manage and maintain the desired state of resources.

Scheduler to API Server - This is normal. The Scheduler interacts with the API Server to allocate resources and schedule pods.

---
Question 2:
Which Kubernetes feature allows you to define a specific action to take when a container terminates?
Answer:
PreStop Hook

Overall explanation
CORRECT ANSWER:

PreStop Hook - PreStop Hooks allow you to run commands just before a container is terminated.

WRONG ANSWERS:

Liveness Probe - Checks if a container is running.

Readiness Probe - Checks if a container is ready to serve traffic.

PostStart Hook - Runs commands immediately after a container starts.

---
Question 3:

What is one of the best ways to enhance your pod's security posture?
Answer:
Pod Security Standards

Overall explanation
CORRECT ANSWER:
Pod Security Standards - Pod Security Standards (PSS) provide a set of best practices and guidelines for securing pods. They define standards for pod security across different levels and help enforce security configurations in a Kubernetes cluster.

WRONG ANSWERS:
Pod Security Policy - Pod Security Policy (PSP) was a mechanism for securing pods but is deprecated and replaced by Pod Security Standards. It defined policies for pod security, but it is no longer recommended for new deployments.

Setting pod Limits & Requests - Setting limits and requests for CPU and memory helps manage resource usage but does not specifically address overall pod security posture.

Adding a LimitRange to your namespace - A LimitRange controls resource usage limits within a namespace but does not directly enhance pod security. It is more about resource allocation and management.

---
Question 4:
What is the purpose of the PodDisruptionBudget resource in Kubernetes?

answer
To manage the maximum number of pods that can be unavailable during maintenance


---
Question 5:
Which Kubernetes resource is used to restrict consumption and creation of cluster resources for a namespace?
Your answer is correct
ResourceQuota

---
Question 6:
What is an effective way to ensure passwords are secure in Kubernetes?
Your answer is correct
Encrypting passwords in transit and at rest

---
Question 7:
What is the purpose of the apiVersion field in Kubernetes resource manifests?
Your answer is correct

To define the API group and version for the resource

---
Question 8:
What is an essential practice for securing cloud infrastructure?
Correct answer
Implementing IAM policies

Overall explanation
CORRECT ANSWER:

Implementing IAM policies - Implementing Identity and Access Management (IAM) policies is essential for securing cloud infrastructure. IAM controls who has access to cloud resources and what actions they can perform, reducing the risk of unauthorized access and enhancing overall security.

WRONG ANSWERS:

Adding exceptions to firewall rules - Adding exceptions can introduce vulnerabilities by allowing unintended access through the firewall.

Removing instances with public IP addresses - While this reduces exposure, it is not as comprehensive as implementing IAM policies for overall security.

Making services available to all regions - Expanding service availability increases the attack surface and does not contribute to securing the infrastructure.

---
Question 9:
What is the successor of PodSecurityPolicies (PSP) in Kubernetes?
Your answer is correct
PodSecurityAdmission (PSA)

---
Question 10:
Which cloud infrastructure security feature ensures encrypted data transfer between services?
Correct answer
Transport Layer Security (TLS)
Overall explanation
CORRECT ANSWER:

Transport Layer Security (TLS) - TLS ensures encrypted data transfer between services in the cloud by encrypting data in transit, protecting it from interception and tampering.

WRONG ANSWERS:

Identity and Access Management (IAM) - IAM manages user identities and permissions but does not encrypt data transfer.

Data Loss Prevention (DLP) - DLP focuses on preventing data leaks, not on encrypting data between services.

Key Management Service (KMS) - KMS manages encryption keys but does not directly handle data encryption during transfer.

---
Question 11:
How can you encrypt Kubernetes secrets at rest?
Your answer is correct
By enabling etcd encryption in the API server
Overall explanation
CORRECT ANSWER:

By enabling etcd encryption in the API server - Encrypts secrets at rest in etcd.

WRONG ANSWERS:

By enabling certificates in the API server - Secures communication, not data at rest.

By changing the secret YAML - Does not enable encryption at rest.

Encryption at rest is not possible for Kubernetes secrets - Incorrect; it is possible.

---
Question 12:
Your single node API Server is running on one control plane and is hit by a DDOS attack, how does running more nodes on the control plane help?
Your answer is correct
Distributes the attack load, increases resiliency and reduces likelihood of a single point of failure

---
Question 13:
John wants to change his pod's container image using a MutatingAdmissionWebhook. Can John change the pod image, and how?

Your answer is correct
Yes, by adding logic that responds to the pod creation request and which modifies the spec.containers[].image field.

---
Question 14:
What is the security reasoning behind running a Kubernetes cluster on a managed cloud?
Your answer is correct
Because the applications are only as safe as it’s underlying infrastructure

---
Question 15:
Which framework is commonly used to standardize cloud security controls?
Correct answer
ISO 27001
Overall explanation
CORRECT ANSWER:

ISO 27001 - ISO 27001 is a widely recognized framework for standardizing cloud security controls. It provides a comprehensive set of guidelines for establishing, implementing, maintaining, and continually improving an information security management system.

WRONG ANSWERS:

PCI-DSS - Targets payment card industry data security, not general cloud security controls.

OWASP Top 10 - Lists common web application vulnerabilities but does not provide a standard framework for cloud security.

GDPR - Focuses on data protection and privacy regulations in the EU, not on standardizing security controls.

---
Question 16:
Which of the following is true about Kubernetes namespaces?
Your answer is correct
They help organize resources within a cluster
---
Question 17:
How can you secure communication between Kubernetes components?
Your answer is correct
By using TLS encryption

---
Question 18:
What Kubernetes object can be used to control which nodes a pod can be scheduled on?

Overall explanation
CORRECT ANSWER:

All of the other answers - NodeSelector, Taints/Tolerations, and Affinity rules are all used to control which nodes a pod can be scheduled on.

WRONG ANSWERS:

NodeSelector - Correct but only one method; 'All of the other answers' includes this and more.

Taint - Correct but only part of the solution.

Affinity - Correct but not the only method.

---
Question 19:
What is trojan classified as in the STRIDE threat model?
Correct answer
Spoofing

Overall explanation
CORRECT ANSWER:

Spoofing - In the STRIDE threat model, a trojan is classified under Spoofing because it disguises itself as legitimate software to deceive users or systems.

WRONG ANSWERS:

Tampering - Tampering involves unauthorized modification of data, which is not the primary characteristic of a trojan.

Repudiation - Repudiation refers to the denial of actions or transactions, which does not apply to trojans.

Elevation of Privilege - While trojans may lead to elevated privileges, their main tactic is deception, aligning them with Spoofing.

---
Question 20:
What are the built-in authentication methods in Kubernetes which are enabled by default?
Your answer is correct
x509 certificates, Bootstrap tokens, Service account tokens

---
Question 21:
What security framework focuses on tactics, techniques and procedures (TTPs)?

Correct answer
MITRE ATT&CK
Overall explanation
CORRECT ANSWER:

MITRE ATT&CK - The MITRE ATT&CK framework focuses on cataloging cyber adversary tactics, techniques, and procedures (TTPs). It provides a comprehensive matrix of known attacker behaviors to help organizations understand and defend against cybersecurity threats.

WRONG ANSWERS:

NIST - The National Institute of Standards and Technology (NIST) provides cybersecurity frameworks and guidelines, such as the NIST Cybersecurity Framework, but it does not specifically focus on TTPs.

CIS - The Center for Internet Security (CIS) offers benchmarks and best practices for securing systems but does not concentrate on documenting adversary TTPs.

ISO 27002 - ISO 27002 is an international standard providing guidelines for information security management practices, not specifically focused on the tactics, techniques, and procedures of cyber adversaries.
---
Question 22:
Your cluster has two worker nodepools, which have two different container runtimes. You wish to use another container runtime on your running pod, how do you perform this change?
Correct answer
Edit pod YAML field 'runtimeClassName' (Use a RunTimeClass)
Overall explanation
CORRECT ANSWER:
Edit pod YAML field 'runtimeClassName' (Use a RunTimeClass) - RuntimeClass is a Kubernetes feature that allows specifying the container runtime to use for a particular pod by defining the runtimeClassName field in the pod specification.

WRONG ANSWERS:
Edit Docker daemon config - Changing Docker daemon configuration won't affect the container runtime of a specific pod, and Docker may not even be the runtime in use.

Use command kubectl annotate - Adding annotations won’t change the runtime of an existing or new pod.

Use command kubeadm config - kubeadm is used for setting up or managing Kubernetes clusters, not for changing container runtimes on running pods.
---
Question 23:
Which Kubernetes object is used to securely store sensitive information, such as passwords and tokens?
Your answer is correct
Secret
---
Question 24:
A Kubernetes admin decides to give a user a rolebinding (not clusterRoleBinding) with the role cluster-admin. What can the user delete in the cluster?
Your answer is correct
Delete all resources in the namespace, including its own namespace

Overall explanation
CORRECT ANSWER:

Delete all resources in the namespace, including its own namespace - A RoleBinding with the cluster-admin role grants the user full permissions within that namespace, including deleting all resources and the namespace itself.

WRONG ANSWERS:

Delete all resources in the namespace, but not its own namespace - The user can delete the namespace since they have full permissions within it.

Delete all resources in all namespaces, including all namespaces - A RoleBinding is scoped to a single namespace; to affect all namespaces, a ClusterRoleBinding is required.

Delete all resources in all namespaces, but not all namespaces - Again, a RoleBinding does not grant cluster-wide permissions.
---
Question 25:
How do you restrict a Kubernetes Service to be accessible only within the cluster?
Your answer is correct
By setting the Service type to ClusterIP
---
Question 26:
What is the standard way to secure pod-pod communication in kubernetes?
Your answer is correct
Network Policies
---
Question 27:
Which setting helps prevent privilege escalation within a Kubernetes cluster?

Your answer is correct
Setting allowPrivilegeEscalation: false in the container security context
---
Question 28:
What command would you use to create a secret from a file in Kubernetes?
Your answer is correct
kubectl create secret generic --from-file=[]
---
Question 29:
Which of the 4 C's of Cloud Native Security focuses on ensuring that the application code is free from vulnerabilities before deployment?
Your answer is correct
Code
---
Question 30:
How do you limit the number of simultaneous connections to a Kubernetes API server?
Your answer is correct
By setting API server flags such as '--max-requests-inflight'
---
Question 31:
Which of the 4 C's of Cloud Native Security involves implementing robust identity and access management (IAM) policies to secure infrastructure?
Correct answer
Cloud
---
Question 32:
What is a key security consideration when configuring PersistentVolumes in Kubernetes?
Your answer is correct
Ensuring PersistentVolumes are encrypted to protect sensitive data at rest
---
Question 33:
Which of the 4 C's of Cloud Native Security includes enabling Role-Based Access Control (RBAC) to manage permissions effectively?
Your answer is correct
Cluster
---
Question 34:
How can you automate the scaling of a Kubernetes deployment based on CPU usage?
Your answer is correct
Using a HorizontalPodAutoscaler
---
Question 35:
Which control framework focuses on managing and mitigating risks in a cloud environment?
Correct answer
NIST Cybersecurity Framework

---
Question 36:
What payment method and industry are the security standard PCI DSS in?
Your answer is correct
Credit, debit cards. Payment card industry

---
Question 37:
Which of the 4 C's of Cloud Native Security involves regularly updating base images and using vulnerability scanning to ensure security?
Your answer is correct
Container
---
Question 38:
Which Kubernetes component is responsible for ensuring containers are running in a Pod?
Your answer is correct
kubelet
---
Question 39:
What is a crucial security measure for managing container images?
Your answer is correct
Storing images in a private repository
---
Question 40:
What command checks the enforced Pod Security Standard level in a Kubernetes namespace?
Your answer is correct
kubectl get ns --show-labels -n <namespace>
---
Question 41:
Which tool can be used to enforce Kubernetes security policies and ensure compliance?
Your answer is correct
OPA/Gatekeeper
---
Question 42:
What isolation method can be used to logically isolate workloads in Kubernetes?
Your answer is correct
Namespace
---
Question 43:
Which one of these statements are true about Kubernetes configmaps?
Your answer is correct
ConfigMaps store data in plain text, which can be easily read by anyone with access to the ConfigMap, leading to potential security breaches

---
Question 44:
What is the role of an Admission Controller in Kubernetes?
Your answer is correct
To validate and modify API requests before they are persisted
---
Question 45:
What is the purpose of the kube-bench tool in Kubernetes security?
Your answer is correct
To check Kubernetes clusters against CIS benchmarks
---
Question 46:
What is true about static pods and the Kubelet?
Your answer is correct
Kubelet circumvents kube-scheduler and creates pod locally on the node, making it difficult to track and manage
---
Question 47:
How did a user with full CRUD rights on a namespace allow a privileged pod to run even when it is being disallowed by the Pod Security Admission controller?
Your answer is correct
The user removed a label on the namespace
---
Question 48:
Which Kubernetes feature isolates pod-to-pod network traffic to prevent unauthorized access?
Your answer is correct
NetworkPolicy
---
Question 49:
What does having no egress network policies do to your Kubernetes resources?
Your answer is correct
Allows all egress traffic to external services
---
Question 50:
Which Kubernetes object is used to expose a set of pods as a network service?
Your answer is correct
Service
---
Question 51:
What controllers except kube-controller are also a built-in part of kubernetes?
Your answer is correct
DaemonSet Controller, Deployment Controller, StatefulSet Controller

Overall explanation
CORRECT ANSWER:

DaemonSet Controller, Deployment Controller, StatefulSet Controller - These are built-in Kubernetes controllers that manage DaemonSets, Deployments, and StatefulSets, handling the creation and maintenance of these resources.

WRONG ANSWERS:

ReplicaSet controller, pod controller, cronjob controller - While the ReplicaSet and CronJob controllers are built-in, there is no dedicated "pod controller" in Kubernetes.

Ingress controller, pod controller, DaemonSet controller - The Ingress controller is not built-in; it typically requires third-party implementations. There is also no "pod controller".

ReplicaSet controller, pod controller, DaemonSet controller - Although ReplicaSet and DaemonSet controllers are built-in, Kubernetes does not include a separate "pod controller".
---
Question 52:
How do you disallow privileged pods from running in a namespace when using Pod Security Standards?
Your answer is correct
Add pod-security.kubernetes.io/enforce: baseline label to the namespace
---
Question 53:
What is the primary focus of the 4Cs of Cloud Native Security?
Your answer is correct
Layered security approach
---
Question 54:
Which of the following best describes the purpose of Kubernetes Role-Based Access Control (RBAC)?
Your answer is correct
To restrict access to resources based on user roles
---
Question 55:
How can you ensure that a container runs with non-root user privileges in Kubernetes?
Your answer is correct
By modifying the 'runAsUser' field in the Pod security context YAML configuration
---
Question 56:
Which tool helps to ensure the integrity of container images?
Correct answer
Notary
Overall explanation
CORRECT ANSWER:

Notary - Notary ensures the integrity of container images through signing and verification, confirming that images are from trusted sources and have not been tampered with.

WRONG ANSWERS:

Shielder - Not a standard tool for ensuring container image integrity.

Thanos - Used for scaling Prometheus data, not for image integrity.

Kyverno - A policy engine for Kubernetes, but not specifically focused on image integrity.
---
Question 57:
Which of the following tools is commonly used to scan container images for vulnerabilities?
Your answer is correct
Trivy
---
Question 58:
What security principle does "The 4C’s of Cloud Native Security" modify?
Correct answer
Defense in Depth
---
Question 59:
In what order of execution does the admission controllers run in Kubernetes?
Your answer is correct
Mutating admission controller first, then Validating admission controller
---
Question 60:
How does a ServiceAccount improve Kubernetes security for pods?
Your answer is correct
By providing credentials to restrict a pod’s API access

Overall explanation
CORRECT ANSWER:

By providing credentials to restrict a pod’s API access - ServiceAccounts assign permissions to pods, limiting API access as needed.

WRONG ANSWERS:

By limiting access to external resources from the pod’s network - External network restrictions are managed by NetworkPolicies, not ServiceAccounts.

By encrypting pod traffic within the cluster - Traffic encryption requires TLS or network security, not ServiceAccounts.

By isolating storage access between pods - Storage isolation is handled by PersistentVolumes and PersistentVolumeClaims, not ServiceAccounts.

---
Question 1:
Why is it not smart to store Kubernetes secrets in configmaps?
Correct answer
Kubernetes won't recognize or handle the sensitive data stored in configmaps as sensitive
Overall explanation
CORRECT ANSWER:

Kubernetes won't recognize or handle the sensitive data stored in configmaps as sensitive - ConfigMaps are intended for non-sensitive data, and Kubernetes does not treat their contents with the same security as Secrets.

WRONG ANSWERS:

Data in Configmaps are unencrypted, while secrets are encrypted using Base64 and therefore more secure - Base64 encoding is not encryption; the main issue is how Kubernetes treats ConfigMaps versus Secrets.

There are no drawbacks to using configmaps to store secrets - ConfigMaps are not secure for storing sensitive data.

Data in Configmaps are available to pods by populating a pod's volume, making them insecure - This is a general usage feature but not the key reason for not storing secrets in ConfigMaps.

---
Question 2:
What security measure should be taken for Kubelet communication?
Your answer is correct
Enabling Transport Layer Security (TLS) for Kubelet API communication
Overall explanation
CORRECT ANSWER:

Enabling Transport Layer Security (TLS) for Kubelet API communication - TLS encrypts the communication between the Kubelet and other Kubernetes components, ensuring secure and authenticated connections.

WRONG ANSWERS:

Implementing token-based authentication for Kubelet API access - Token-based authentication adds security but does not encrypt the communication channel like TLS does.

Configuring network policies to restrict Kubelet access to specific IP ranges - NetworkPolicies control pod traffic, not Kubelet communication.

Using role-based access control (RBAC) to manage Kubelet permissions - RBAC manages permissions but doesn't secure the communication channel itself.
---
Question 3:
How can you ensure that a Kubernetes pod is securely restricted to run on specific nodes?
Your answer is correct
By setting the node affinity rules on the pod
---
Question 4:
How can you ensure secure access for Kubernetes clients?
Your answer is correct
Use TLS certificates to authenticate clients
---
Question 5:
How can the data in Etcd be protected?
Your answer is correct
Enabling data encryption at rest
---
Question 6:
How can you bolster container runtime security within a Kubernetes cluster?
Your answer is correct
Implementing intrusion detection systems for threat detection
---
Question 7:
How does the Kubernetes Controller Manager contribute to maintaining security in a Kubernetes cluster?
Your answer is correct
By ensuring that security policies are applied consistently across all controllers
---
Question 8:
What mechanism does Kubernetes use to manage user permissions?
Your answer is correct
Role-Based Access Control (RBAC)
---
Question 9:
What are the three policies in the Pod Security Standard?
Your answer is correct
privileged, baseline, restricted
---
Question 10:
What is an important practice in Client Security when working with Kubernetes?
Correct answer
Securing your kubeconfig file
Overall explanation
CORRECT ANSWER:

Securing your kubeconfig file - The kubeconfig file contains sensitive information about access to your Kubernetes cluster and should be protected.

WRONG ANSWERS:

Scanning images in your container registry for vulnerabilities - This is important for image security but not directly related to client security.

Keeping the cluster's nodes up-to-date - Node updates are essential for cluster security but are not specifically related to client security.

Using Kubernetes Secrets instead of Configmaps for confidential data - This is important but pertains to data security, not client security.
---
Question 11:
How does the Cloud Native tool Falco enhance security in a Kubernetes environment?
Your answer is correct
By monitoring and detecting suspicious activity at the kernel level in real-time
---
Question 12:
Which authentication method is a recommended enhancement for Kubernetes API server?
Correct answer
Implementing OAuth2 tokens
Overall explanation
CORRECT ANSWER:

Implementing OAuth2 tokens - OAuth2 tokens provide a modern, secure method for API server authentication.

WRONG ANSWERS:

Implementing A/B authentication - This is not a recognized authentication method for Kubernetes.

Implementing SHA-1 authentication - SHA-1 is outdated and insecure.

Making the cluster private - This improves network security but does not directly enhance authentication.
---
Question 13:
What practice ensures that application code does not contain known vulnerabilities?
Your answer is correct
Static code analysis
---
Question 14:
Which practice enhances the security of a private image repository?
Your answer is correct
Implementing role-based access control (RBAC) and automated vulnerability scanning
---
Question 15:
What is the successor to PodSecurityPolicy (PSP) for enforcing security policies on pods in Kubernetes?
Your answer is correct
Pod Security Admission (PSA)
---
Question 16:
How can the kubectl apply command contribute to improving Kubernetes security?
Your answer is correct
To apply updated RBAC roles and policies from configuration files
---
Question 17:
How can the OWASP Kubernetes Top Ten guide be utilized to improve security in a Kubernetes environment?
Correct answer
By identifying and mitigating common security risks and vulnerabilities specific to Kubernetes
Overall explanation
CORRECT ANSWER:

By identifying and mitigating common security risks and vulnerabilities specific to Kubernetes - The OWASP Kubernetes Top Ten guide helps mitigate common security risks in Kubernetes environments.

WRONG ANSWERS:

By applying threat modeling frameworks - While important, this isn't specific to the OWASP guide's purpose.

By verifying all software components - This is more related to supply chain security, not the focus of OWASP Kubernetes Top Ten.

By ensuring Kubernetes aligns with compliance frameworks - The OWASP guide is about security vulnerabilities, not compliance alignment.
---
Question 18:
How does AppArmor enhance security for containers running in a Kubernetes environment?
Your answer is correct
By defining a set of mandatory access control rules that restrict what processes within a container can do
Overall explanation
CORRECT ANSWER:

By defining a set of mandatory access control rules that restrict what processes within a container can do - AppArmor uses mandatory access control (MAC) to restrict container actions.

WRONG ANSWERS:

By filtering a process's system calls - This describes seccomp, not AppArmor.

By enforcing strict Pod Security Standards (PSS) - AppArmor does not enforce Pod Security Standards.

By adjusting user rights to grant additional privileges - AppArmor restricts privileges rather than granting them.
---
Question 19:
What is the purpose of the kubernetes.io/enforce-mountable-secrets annotation in Kubernetes?
Correct answer
To specify that secrets should be mounted into a pod only if they meet certain criteria defined by the annotation
Overall explanation
CORRECT ANSWER:

To specify that secrets should be mounted into a pod only if they meet certain criteria defined by the annotation - The kubernetes.io/enforce-mountable-secrets annotation limits how and when secrets can be mounted into pods based on criteria.

WRONG ANSWERS:

To ensure that secrets are encrypted when mounted into a pod - Secrets are encrypted by default, and this annotation doesn't manage encryption.

To enforce that secrets can only be mounted into a pod as environment variables - This annotation doesn't enforce such restrictions.

To prevent secrets from being mounted into a pod - This annotation enforces conditions, not outright prevention.

---
Question 20:
What is a primary security benefit of deploying a service mesh in a Kubernetes environment?
Correct answer
Enforcing end-to-end encryption and consistent security policies across services
Overall explanation
CORRECT ANSWER:

Enforcing end-to-end encryption and consistent security policies across services - A service mesh provides security by enabling encryption and enforcing consistent policies across service-to-service communications.

WRONG ANSWERS:

Disabling faulty network policies for internal traffic - A service mesh does not disable network policies; it adds additional layers of control and security.

Centralizing all traffic through a single secure gateway - A service mesh manages traffic within the cluster, not through a single gateway.

Temporary data used for communications between services is encrypted at rest - Service mesh focuses on encryption in transit, not at rest.
---
Question 21:
Which of the following is a key principle of Kubernetes Pod Security Standards?

Correct answer
Using least privilege to limit pod permissions
Overall explanation
CORRECT ANSWER:

Using least privilege to limit pod permissions - Applying least privilege ensures that pods only have the minimum permissions required, enhancing security.

WRONG ANSWERS:

Using a shared service account - Shared accounts increase security risks by making tracking and controlling access harder.

Using PodSecurityPolicy to enforce Pod Security Standards - PodSecurityPolicy is deprecated in favor of newer security tools.

Turning on RBAC on all pods in all namespaces - RBAC should be used with a least privilege approach, not broadly without limitations.
---
Question 22:
What is an easy way to find regularly appearing Vulnerabilities found in Kubernetes?
Your answer is correct
Go to the Official CVE Feed in the Kubernetes documentation
---
Question 23:
How can you control access to the Kubernetes API server?
Correct answer
By implementing RBAC authorization
---
Question 24:
Which feature limits a container’s system calls to enhance pod security?
Your answer is correct
Seccomp
---

Question 25:
What security function does the Container Runtime Interface (CRI) enable in Kubernetes?
Your answer is correct
Facilitating container isolation by supporting security policies like Seccomp and AppArmor through the runtime
Overall explanation
CORRECT ANSWER:

Facilitating container isolation by supporting security policies like Seccomp and AppArmor through the runtime – The CRI allows the kubelet to communicate with container runtimes and apply isolation policies such as Seccomp and AppArmor, which help control system call access and resource restrictions, enhancing container security.

WRONG ANSWERS:

Enabling encrypted communication between the kubelet and container runtime – While the CRI manages communication between the kubelet and container runtime, encryption is handled by other layers like TLS, not by the CRI itself.

Managing network policies between container runtimes – CRI is responsible for container management and lifecycle operations, not network policies, which are handled by network plugins or policies in Kubernetes.

Providing direct control over container runtime security settings via the API Server – The CRI does not provide direct security management through the API Server. Security settings are managed through security contexts or Pod Security Admission, not directly through CRI.
---
Question 26:
What is a popular Cloud Native Tool that is an alternative or compliment to Pod Security Admission (PSA) in Kubernetes?
Your answer is correct
Kyverno
---

Question 27:
What is a recommended method to ensure secure communication with the Kubernetes API Server?
Your answer is correct
Configuring Transport Layer Security (TLS) for encrypted communication
---
Question 28:
Which is the standard kubernetes resource used to restrict pod-to-pod network traffic?

Your answer is correct
NetworkPolicy
---
Question 29:
How can understanding trust boundaries help improve security in a Kubernetes cluster?
Your answer is correct
By identifying and segmenting different parts of the cluster to limit the impact of a security breach
Overall explanation
CORRECT ANSWER:

By identifying and segmenting different parts of the cluster to limit the impact of a security breach - Understanding trust boundaries helps contain security breaches within certain parts of the cluster.

WRONG ANSWERS:

By preventing communication between components - Trust boundaries don’t prevent necessary communication but segment it securely.

By merging namespaces into larger namespaces - This would reduce security, not improve it.

By enabling security policies to reduce malicious activities - While true, this is not specific to the role of trust boundaries.
---
Question 30:
How can developers mitigate the risk associated with third-party dependencies in their applications?
Your answer is correct
Regularly updating and scanning dependencies for vulnerabilities
---
Question 31:
What is a comprehensive security measure for container runtime environments?
Correct answer
Using SELinux or AppArmor to restrict container privileges
Overall explanation
CORRECT ANSWER:
Using SELinux or AppArmor to restrict container privileges - These tools enforce mandatory access controls to limit container actions, reducing the risk of privilege escalation and protecting the host.

WRONG ANSWERS:
Granting containers access to host-level namespaces - Weakens isolation and increases the risk of privilege escalation attacks.

Configuring Seccomp profiles to limit system calls for containers - A useful measure, but it focuses only on restricting system calls, not comprehensive privilege control.

Allowing containers to access runtime APIs - Increases attack vectors and creates potential vulnerabilities in the runtime environment.
---
Question 32:
Which of the following is a typical result of a Denial of Service (DoS) attack on a Kubernetes cluster?
Your answer is correct
Resource exhaustion causing legitimate services to become unavailable
---
Question 33:
What is a Cloud Native container repository tool and what tool can be used for Container scanning?
Correct answer
Harbor and Trivy
Overall explanation
CORRECT ANSWER:

Harbor and Trivy - Harbor is a container repository, and Trivy is a tool for scanning container images for vulnerabilities.

WRONG ANSWERS:

Azure Hub and Snyk - Azure Hub is not a known repository tool; however, Snyk is a security scanning tool.

Prometheus and Anchore - Prometheus is used for monitoring, not a container repository tool.

Docker hub and flux - Flux is a GitOps tool, not a security scanner.
---
Question 34:
What is a potential risk associated with overly permissive API Server access, and how can it be mitigated?
Your answer is correct
Increased attack surface; mitigated by strict role-based access control (RBAC)
---
Question 35:
How can the supply chain be secured in a Kubernetes environment?
Your answer is correct
Enforcing image signing and scanning for vulnerabilities
---
Question 36:
What is a potential security risk associated with persistence in Kubernetes?
Your answer is correct
Sensitive data being stored in unencrypted volumes
---
Question 37:
Why is it critical to apply security patches to your application code?
Your answer is correct
To fix known vulnerabilities and reduce security risks
---
Question 38:
What are some possible settings that a security context can define for a Pod or a container?
Your answer is correct
User ID, Group ID and Privilege
---
Question 39:
What is a potential security risk associated with persistence in Kubernetes?
Your answer is correct
Sensitive data being stored in unencrypted volumes
---
Question 40:
What is a primary security risk associated with using a NodePort service in Kubernetes?
Your answer is correct
It exposes the service on a static port accessible externally, increasing the attack surface
---
Question 41:
In a terminal, which kubectl command would output the logs from a container?
Your answer is correct
kubectl logs <POD> -c <CONTAINER>
---
Question 42:
What are the three possible modes/actions of Pod Security Admission (PSA)?
Your answer is correct
enforce, audit, warn
---
Question 43:
What does the Kubernetes Controller Manager do and what is one of it's security implications?
Your answer is correct
It reconciles desired state with actual state; security policies must be consistent to avoid drift.
---
Question 44:
How does the Kubernetes Scheduler contribute to cluster security?
Your answer is correct
By scheduling pods on nodes according to Node Affinity rules, Node Anti-Affinity rules, Node taints, Node tolerations and resource constraints
---
Question 45:
What are two common Cloud Native Observability tools?
Your answer is correct
Grafana and Prometheus
---
Question 46:
Which strategy helps minimize the damage potential if an application component is compromised?
Your answer is correct
Implementing a least privilege model
---
Question 47:
How can a ReplicaSet contribute to the security of a Kubernetes application?
Your answer is correct
By ensuring a certain number of pod replicas are running to slow down resource exhaustion due to denial-of-service attacks
---
Question 48:
Why is audit logging important in Kubernetes security?
Your answer is correct
To track and log user actions within the cluster
---
Question 49:
What role does Public Key Infrastructure (PKI) play in securing a Kubernetes cluster?
Your answer is correct
It enables secure communication through the issuance and management of certificates
Overall explanation
CORRECT ANSWER:

It enables secure communication through the issuance and management of certificates - PKI helps in securing communication within the Kubernetes cluster by managing certificates for encryption and identity verification.

WRONG ANSWERS:

It replaces the need for authentication tokens - PKI works alongside tokens, not as a replacement.

It simplifies the process of key management by automating key rotation - PKI doesn’t inherently automate key rotation, though it facilitates key management.

It allows for the use of self-signed certificates for internal services - Self-signed certificates can be used but aren't a primary function of PKI.
---
Question 50:
What is the primary security risk of not setting resource limits in Kubernetes pods?
Your answer is correct
It could lead to denial-of-service attacks by allowing a pod to consume all available cluster resources
---
Question 51:
What are four common container runtimes?
Correct answer
Containerd, CRI-O, Docker Engine, Mirantis
Overall explanation
CORRECT ANSWER:

Containerd, CRI-O, Docker Engine, Mirantis - These are well-known container runtimes used in Kubernetes environments.

WRONG ANSWERS:

OCI, CRI-O, Docker Engine, Envoy - OCI is a standard, and Envoy is a service proxy, not a container runtime.

Containerd, CRI-O, Docker Engine, gRPC - gRPC is a communication protocol, not a container runtime.

Containerd, CRI-O, Docker Engine, Vitess - Vitess is a database solution, not a container runtime.
---
Question 52:
What is the primary benefit of using immutable infrastructure in application code security?
Your answer is correct
Preventing configuration drift
---
Question 53:
Which tools are commonly used for performing security assessments and compliance checks in Kubernetes environments?
Your answer is correct
Kube-bench, Kubescape, Checkov, Trivy
---
Question 54:
What measure helps secure Kubernetes storage?
Your answer is correct
Enabling encryption for persistent volumes
---
Question 55:
Which advanced isolation technique can be used to enforce network security within a Kubernetes cluster, beyond simple namespace isolation?
Your answer is correct
Zero Trust Network segmentation using microservices-based architecture
---
Question 56:
How does the concept of immutability enhance the security of container images stored in an artifact repository?
Your answer is correct
By ensuring that images cannot be altered once pushed, reducing the risk of tampering
---
Question 57:
What does Pod Security Admission enforce in Kubernetes?
Correct answer
Security context requirements for pods
---
Question 58:
What security role does KubeProxy play in a Kubernetes cluster?
Correct answer
Managing traffic forwarding between pods and external clients
Overall explanation
CORRECT ANSWER:
Managing traffic forwarding between pods and external clients - KubeProxy handles forwarding traffic to services and ensures service exposure, which has security implications for how services are exposed to the cluster or externally.

WRONG ANSWERS:
Encrypting communication between cluster nodes - This is handled by the Kubernetes API server and PKI, not KubeProxy.
Ensuring proper enforcement of pod-to-pod NetworkPolicies - NetworkPolicy enforcement is managed by the CNI plugin, not KubeProxy.
Implementing authentication mechanisms for API requests - API authentication is handled by the API server and does not involve KubeProxy.
---
Question 59:
Which configuration enhances the security of the Kubernetes API Server against unauthorized access?
Your answer is correct
Implementing Role-Based Access Control (RBAC) with least privilege
---
Question 60:
Which tool is often used to manage secrets securely in application environments?
Your answer is correct
HashiCorp Vault
---
Question 1:
How do you configure Kubernetes to use a specific container runtime, such as containerd, on a node?
Your answer is correct
Set the ‘–container-runtime-endpoint’ flag in the kubelet configuration
---
Question 2:
In threat modeling using Data Flow Diagrams (DFDs), what key aspects of a system are primarily visualized?
Your answer is correct
Entry points, exit points, data flows, and potential threat vectors within the system
---
Question 3:
Which statement best describes the role of container scanning tools like Aqua Security or Clair?
Your answer is correct
They automate vulnerability detection in container images, typically before deployment
---
Question 4:
Is there a Kubernetes object specifically designed to limit the number of concurrent requests to the API server?
Your answer is correct
There is no such object
---
Question 5:
Does setting ‘privileged: true’ on a Kubernetes pod grant it access to Kubernetes Secrets?
Your selection is correct
No, it only elevates the pod's privileges on the host system but does not affect Secrets access
Correct selection
Access depends solely on RBAC permissions, regardless of privileged mode
Overall explanation
CORRECT ANSWERS:

No, it only elevates the pod’s privileges on the host system but does not affect Secrets access and Access depends solely on RBAC permissions, regardless of privileged mode - Privileged mode affects host-level permissions but doesn’t grant access to Kubernetes Secrets. Secret access is controlled by RBAC and ServiceAccount permissions.

WRONG ANSWERS:

Yes, it grants full access to all Secrets in the cluster - Privileged mode doesn’t bypass Kubernetes RBAC for API resources.

Yes, but only to Secrets within the same namespace - Privileged mode doesn’t grant any additional Secret access.

No, it explicitly prevents access to Secrets - Privileged mode doesn’t prevent Secret access; it’s neutral regarding API permissions.
---
Question 6:
Which security development framework explicitly incorporates threat modeling and validation phases to ensure secure software development?
Your answer is correct
Microsoft Security Development Lifecycle (SDL)
Overall explanation
CORRECT ANSWER:

Microsoft Security Development Lifecycle (SDL) - SDL is a comprehensive security assurance process that explicitly includes threat modeling and security validation as core phases throughout the software development lifecycle.

WRONG ANSWERS:

Open Container Initiative (OCI) Standard - OCI defines container format and runtime standards, not a security development framework.

JWT Token Compliance Framework - This is not a comprehensive development framework but a token standard.

HTTP Strict Transport Security (HSTS) - HSTS is a web security policy mechanism, not a development framework.

NIST Special Publication 800-63 - This provides digital identity guidelines but is not a complete software development framework.
---
Question 7:
Which statement best describes the purpose of the CIS Kubernetes Benchmark?
Your answer is correct
It offers prescriptive configuration guidelines for hardening Kubernetes clusters
---
Question 8:
How can you enable Pod Security Admission (PSA) in a Kubernetes cluster to enforce pod security standards?
Your answer is correct
By configuring the API server to enable the PodSecurity admission controller
---
Question 9:
What is the primary purpose of threat modeling using Data Flow Diagrams (DFDs) in security architecture?
Your answer is correct
To visualize how data moves through a system and identify potential attack vectors
Overall explanation
CORRECT ANSWER:

To visualize how data moves through a system and identify potential attack vectors - Data Flow Diagrams in threat modeling help security architects understand how data flows through systems, identify trust boundaries, and systematically analyze potential threats at each point.

WRONG ANSWERS:

To monitor network traffic in real-time - DFDs are design-time modeling tools, not real-time monitoring systems.

To automatically patch security vulnerabilities - DFDs are used for analysis and design, not automated remediation.

To encrypt data at rest in databases - DFDs help identify where encryption is needed but don’t implement encryption.

To manage user access permissions - DFDs focus on data flow analysis, not access control management.
---
Question 10:
What types of data are stored inside the etcd key-value store in a Kubernetes cluster?
Your selection is correct
Kubernetes cluster state

Correct selection
Secrets and ConfigMaps
Overall explanation
CORRECT ANSWERS:

Kubernetes cluster state and Secrets and ConfigMaps - etcd stores all Kubernetes API objects including cluster state, resource definitions, Secrets, and ConfigMaps.

WRONG ANSWERS:

Persistent application data - Application data is stored in persistent volumes, not etcd.

Pod logs - Logs are stored on nodes and collected by logging systems, not in etcd.

Container images - Images are stored in container registries, not etcd.
---
Question 11:
What does the ‘–anonymous-auth=false’ flag do when set on the kube-apiserver?
Your answer is correct
Disables anonymous requests to the API server
---
Question 12:
What is the primary purpose of Microsoft Security Development Lifecycle (SDL) in software security?
Your answer is correct
A framework for integrating security practices throughout the software development process
Overall explanation
CORRECT ANSWER:

A framework for integrating security practices throughout the software development process - Microsoft SDL is a software security assurance process that helps developers build more secure software by integrating security practices into each phase of the development lifecycle.

WRONG ANSWERS:

A cloud-based vulnerability scanner - SDL is a development process framework, not a scanning tool.

A network monitoring tool for detecting intrusions - SDL focuses on secure development practices, not network monitoring.

A compliance standard for financial institutions - SDL is a development methodology, not a compliance standard.

An automated penetration testing platform - SDL is about secure development practices, not automated testing tools.
---
Question 13:
Which of the following controllers is NOT managed by the kube-controller-manager in Kubernetes?
Your answer is correct
Ingress Controller
---
Question 14:
What is the recommended method to restrict access to the Kubernetes kubelet API securely?
Your answer is correct
Configure kubelet with ‘–authorization-mode=Webhook’ and ‘–authentication-token-webhook=true’ flags
---
Question 15:
What is the default behavior of Kubernetes network traffic when no Network Policies are applied to a namespace?
Your answer is correct
All ingress and egress traffic is allowed
---
Question 16:
Which of the following lists the five core functions of the NIST Cybersecurity Framework?
Correct answer
Identify, Protect, Detect, Respond, and Recover
Overall explanation
CORRECT ANSWER:

Identify, Protect, Detect, Respond, and Recover - These are the five core functions of the NIST Cybersecurity Framework that provide a comprehensive approach to cybersecurity risk management.

WRONG ANSWERS:

Monitor, Map, Maintain, Minimise, and Mutate - These are not the NIST CSF core functions.

Review, Replace, Retract, Renew, and Reserve - These are not the NIST CSF core functions.

Discover, Compare, Archive, Document, and Renew - These are not the NIST CSF core functions.

Encrypt, Store, Backup, Alert, and Evaluate - These are security activities but not the NIST CSF core functions.
---
Question 17:
Which authentication mechanisms are commonly used by kubeadm during Kubernetes cluster bootstrapping?
Correct selection
Token-based authentication
Your selection is correct
TLS certificates

Overall explanation
CORRECT ANSWERS:

TLS certificates and Token-based authentication - kubeadm uses TLS certificates for secure communication between cluster components and bootstrap tokens for initial node joining and authentication during cluster setup.

WRONG ANSWERS:

OAuth tokens - kubeadm doesn’t use OAuth tokens during bootstrapping.

Static passwords - Static passwords are not used in kubeadm’s authentication mechanisms.

Biometric authentication - Biometric authentication is not supported in Kubernetes cluster bootstrapping.
---
Question 18:
What is the primary function of the Kubernetes scheduler in a cluster?
Your answer is correct
To assign pods to nodes based on resource availability and scheduling policies
---
Question 19:
In Kubernetes Role-Based Access Control (RBAC), what is the purpose of a RoleBinding?
Your answer is correct
Associates a Role with users, groups, or service accounts within a namespace
---
Question 20:
What is the primary purpose of the NIST Cybersecurity Framework (CSF)?
Your answer is correct
A set of risk management guidelines to identify, protect, detect, respond to, and recover from cyber threats
Overall explanation
CORRECT ANSWER:

A set of risk management guidelines to identify, protect, detect, respond to, and recover from cyber threats - The NIST CSF provides a policy framework of computer security guidance for organizations to assess and improve their cybersecurity posture.

WRONG ANSWERS:

A universal law for international data privacy - The CSF is a voluntary framework, not a law.

A standard for container registry licensing - The CSF is not specific to containers or licensing.

A government mandate exclusively for financial institutions - The CSF is voluntary and applicable to all sectors.

A platform for automating software supply chain security - The CSF is a framework, not an automation platform.
---
Question 21:
What is the main objective of Microsoft’s Security Development Lifecycle (SDL)?
Your answer is correct
To incorporate threat modeling and mitigation throughout the software development process
---
Question 22:
Which of the following actions can improve the security of the Kubernetes kubelet?
Your selection is correct
Disable anonymous access to the kubelet
Your selection is correct
Enable authentication and authorization on the kubelet API

Your selection is correct
Use TLS certificates for kubelet communication
---
Question 23:
What is the default service type in Kubernetes if not explicitly specified?
Your answer is correct
ClusterIP
---
Question 24:
Which best defines PCI DSS in a containerized environment?
Your answer is correct
A set of security standards for systems handling cardholder data, applicable to container-based workflows
---
Question 25:
What is a common reason why a Kubernetes Network Policy might not be enforced as expected in a cluster?
Your answer is correct
The installed CNI plugin does not support Network Policies
---
Question 26:
What is the primary function of Resource Quotas in a Kubernetes namespace?
Your answer is correct
Control the amount of resources consumed within a namespace
---
Question 27:
Can you enforce more than one Pod Security Admission (PSA) policy level concurrently within a single namespace?
Correct answer
No, only one policy level per namespace
Overall explanation
CORRECT ANSWER:

No, only one policy level per namespace - Each namespace can only have one Pod Security Standard level enforced at a time. You can have different modes (enforce, audit, warn) but they all apply the same security level.

WRONG ANSWERS:

Yes, by applying multiple labels - While you can have multiple mode labels (enforce, audit, warn), they must all reference the same security level.

Yes, but only with custom configurations - There’s no mechanism to enforce multiple policy levels simultaneously in a namespace.

Only if the namespace is partitioned - Namespaces cannot be partitioned for different security levels.

It depends on the Kubernetes version - This behavior is consistent across Kubernetes versions that support PSA.
---
Question 28:
What command is used to check the version of the Kubernetes API server?
Your answer is correct
‘kubectl version’
---
Question 29:
Which of the following restrictions does the ‘baseline’ Pod Security Standard enforce?
Correct selection
Blocks host networking and ports
Correct selection
Disallows privileged containers
Overall explanation
CORRECT ANSWERS:

Disallows privileged containers and Blocks host networking and ports - The baseline Pod Security Standard prevents privileged containers and blocks access to host networking and ports to maintain basic security isolation.

WRONG ANSWERS:

Allows hostPath volumes - The baseline standard restricts hostPath volumes to prevent access to the host filesystem.

Requires running as non-root - This is enforced by the restricted standard, not baseline.

Allows all Linux capabilities - The baseline standard restricts dangerous Linux capabilities.
---
Question 30:
Which tool is widely used to automate compliance checks against the CIS Kubernetes Benchmark?
Your answer is correct
Kube-bench
---
Question 31:
How do you enable Pod Security Admission (PSA) in a Kubernetes cluster?
Your answer is correct
Add ‘PodSecurity’ to the ‘–enable-admission-plugins’ flag in the API server
---
Question 32:
What is the impact on a Kubernetes cluster if the kube-proxy component enters a ‘CrashLoopBackOff’ state?
Your answer is correct
Network traffic between services may be disrupted or fail
---
Question 33:
Which of the following best practices are recommended to secure the Kubernetes scheduler (kube-scheduler)?
Correct selection
Configure network policies to restrict network access to and from the scheduler
Your selection is correct
Use Role-Based Access Control (RBAC) to restrict access to the scheduler API

Your selection is correct
Run the scheduler as a non-root user to minimize privilege escalation risks
Overall explanation
CORRECT ANSWERS:

Use Role-Based Access Control (RBAC) to restrict access to the scheduler API, Run the scheduler as a non-root user to minimize privilege escalation risks, and Configure network policies to restrict network access to and from the scheduler - These practices follow security best practices of least privilege, proper access control, and network segmentation.

WRONG ANSWERS:

Bind the scheduler to 0.0.0.0 to ensure it is accessible from all network interfaces - This increases the attack surface; the scheduler should only bind to necessary interfaces.

Enable anonymous authentication to simplify access for debugging purposes - Anonymous access creates security vulnerabilities and should be disabled.
---
Question 34:
Which of the following are best practices for securing etcd in a Kubernetes cluster?
Your selection is correct
Limit access to etcd endpoints to trusted networks only

Your selection is correct
Store etcd backups in a secure and access-controlled locatio

Your selection is correct
Enable TLS encryption for all communication with etcd

Your selection is correct
Use authentication and authorization mechanisms for etcd access
---
Question 35:
Which of the following are common CNI plugins that support Network Policies?
Correct selection
AWS VPC CNI
Correct selection
Weave Net

Your selection is correct
Calico

Your selection is correct
Cilium
Overall explanation
CORRECT ANSWERS:

Calico, Weave Net, AWS VPC CNI, and Cilium - These CNI plugins all support Network Policy enforcement, providing the ability to control pod-to-pod communication through network rules.

WRONG ANSWER:

Flannel - Basic Flannel configuration doesn’t support Network Policies, though it can be combined with other tools like Calico for policy enforcement.
---
Question 36:
Which Kubernetes admission controller runs first during the admission control process?
Your answer is correct
MutatingAdmissionWebhook
---
Question 37:
Which Kubernetes component is responsible for enforcing Pod Security Standards through admission control?
Your answer is correct
kube-apiserver with the PodSecurity admission plugin
---
Question 38:
Why is a ConfigMap not suitable for storing sensitive information such as secrets in Kubernetes?
Your answer is correct
Data stored in ConfigMaps is kept in plain text and not encrypted
---
Question 39:
If a user is granted the ‘cluster-admin’ ClusterRole through a RoleBinding, what level of access will they have?
Your answer is correct
Full administrative privileges limited to the namespace where the RoleBinding is applied
---
Question 40:
In managed Kubernetes services (e.g., EKS, GKE, AKS), who is responsible for managing the etcd cluster?
Your answer is correct
The cloud provider manages etcd
---
Question 41:
Which Kubernetes feature enables encryption of Secrets data at rest within the cluster?
Your answer is correct
Using the etcd encryption provider for at-rest encryption
---
Question 42:
Why is integrating TLS certificates critical for supply chain security in Kubernetes environments?
Your answer is correct
It secures communication between admission controllers and the API server, preventing man-in-the-middle attacks
---
Question 43:
What is the role of the Service Account Controller in Kubernetes?
Your answer is correct
Manages the creation and lifecycle of service accounts and their associated authentication tokens
---
Question 44:
How do Kubernetes Secrets provide improved security compared to ConfigMaps?
Your answer is correct
Secrets are base64-encoded and can be encrypted at rest, whereas ConfigMaps are stored in plain text
---
Question 45:
Why might a pod retain privileged access even after applying the ‘restricted’ Pod Security Standard (PSS) or Pod Security Admission (PSA) policy to its namespace?
Your selection is correct
The Pod Security Standard does not apply retroactively to existing pods
Your selection is correct
The namespace labels required for policy enforcement are misconfigured or missing
Overall explanation
CORRECT ANSWERS:

The Pod Security Standard does not apply retroactively to existing pods and The namespace labels required for policy enforcement are misconfigured or missing - PSA only affects new pod creation and updates, not existing pods. Also, incorrect or missing namespace labels can prevent policy enforcement.

WRONG ANSWERS:

The Kubernetes API server does not support Pod Security Standards - Modern Kubernetes versions support PSS/PSA.

The pod specification explicitly overrides the policy - Pod specifications cannot override namespace-level security policies.

Privileged access is always allowed regardless of policy - Properly configured PSA will block privileged pods.
---
Question 46:
What is the primary difference between Kubernetes Secrets and ConfigMaps in terms of data handling?

Your answer is correct
Secrets are base64-encoded and can be encrypted at rest, ConfigMaps store plain text
---
Question 47:
Which NIST Special Publication provides comprehensive guidelines on security and privacy controls specifically for federal information systems?
Correct answer
NIST SP 800-53 Rev. 5
Overall explanation
CORRECT ANSWER:

NIST SP 800-53 Rev. 5 - This publication provides the most comprehensive catalog of security and privacy controls for federal information systems and organizations.

WRONG ANSWERS:

NIST SP 800-190 - This focuses specifically on application container security guidance.

NIST SP 800-63 - This covers digital identity guidelines and authentication.

NIST SP 800-171 - This provides security requirements for protecting controlled unclassified information in non-federal systems.

NIST SP 800-30 - This focuses on risk assessment methodology.
---
Question 48:
What is the effect of disabling anonymous authentication on the kubelet?
Your answer is correct
Increased security by requiring authentication
---
Question 49:
Which of the following controllers are included in the Kubernetes kube-controller-manager?
Your selection is correct
Service Account Controller
Your selection is correct
Node Controller

Your selection is correct
ReplicaSet Controller
---
Question 50:
What is the purpose of the ‘–allow-privileged’ flag in the Kubernetes API server configuration?
Correct answer
Allows pods to run privileged containers with elevated permissions
Overall explanation
CORRECT ANSWER:

Allows pods to run privileged containers with elevated permissions - The --allow-privileged flag enables pods to run privileged containers, which have access to all host capabilities and can perform operations that would normally be restricted.

WRONG ANSWERS:

Enables unauthenticated access to the API server - This flag doesn’t affect API server authentication; that’s controlled by other flags like --anonymous-auth.

Grants cluster-admin rights to all users - This flag doesn’t affect user permissions; RBAC controls user access.

Disables security contexts on pods - Security contexts are still enforced; this flag only allows privileged mode when specified.

Controls enforcement of network policies - Network policies are enforced by CNI plugins, not this API server flag.
---
Question 51:
What are the potential impacts of enabling detailed auditing of request responses in a Kubernetes cluster?
Your answer is correct
Performance overhead and increased storage usage due to detailed logs
---
Question 52:
What is the primary purpose of Botkube in a Kubernetes environment?
Your answer is correct
To automate Slack-based alerts for compliance and security events
Overall explanation
CORRECT ANSWER:

To automate Slack-based alerts for compliance and security events - Botkube is a messaging bot that monitors Kubernetes clusters and sends notifications about events, errors, and security issues to communication platforms like Slack, Microsoft Teams, or Discord.

WRONG ANSWERS:

To provide an integrated container build system - Botkube is a monitoring and alerting tool, not a build system.

To serve as an API gateway for microservices - Botkube is not an API gateway but a notification system.

To orchestrate container autoscaling across clusters - Botkube monitors clusters but doesn’t handle autoscaling.

To replace kubelet on worker nodes - Botkube is an external monitoring tool, not a replacement for core Kubernetes components.
---
Question 53:
What is a significant security risk associated with not restricting egress traffic in a Kubernetes cluster?
Your answer is correct
It creates a potential pathway for data exfiltration from compromised pods to external, unauthorized destinations
---
Question 54:
What is the primary role of the kube-proxy component in Kubernetes?
Your answer is correct
Providing service discovery and routing
---
Question 55:
Which of the following statements about static pods in Kubernetes are true?
Your selection is correct
They are useful for running critical system components

Your selection is correct
They are managed directly by the kubelet on a node
Overall explanation
CORRECT ANSWERS:

They are managed directly by the kubelet on a node and They are useful for running critical system components - Static pods are managed by kubelet reading pod manifests from a local directory, making them ideal for system components like kube-apiserver.

WRONG ANSWERS:

They are defined in the API server and stored in etcd - Static pods are defined locally on nodes, not in the API server.

They are automatically rescheduled on other nodes if the node fails - Static pods are tied to specific nodes and aren’t rescheduled.

They can be updated using kubectl commands - Static pods are updated by modifying local manifest files, not via kubectl.
---
Question 56:
What was the precursor to the Pod Security Standards (PSS) in Kubernetes?
Correct answer
PodSecurityPolicy (PSP)
Overall explanation
CORRECT ANSWER:

PodSecurityPolicy (PSP) - PodSecurityPolicy was the predecessor to Pod Security Standards, providing a way to control security-sensitive aspects of pod specifications. PSPs were deprecated in Kubernetes v1.21 and removed in v1.25, replaced by Pod Security Standards and Pod Security Admission.

WRONG ANSWERS:

Pod Security Admission (PSA) - PSA is the successor mechanism that enforces Pod Security Standards, not the precursor.

Kubernetes Security Policies (KSP) - This is not a real Kubernetes feature.

Network Policies - These control network traffic between pods, not pod security specifications.

Role-Based Access Control (RBAC) - RBAC controls access to Kubernetes resources but doesn’t define pod security constraints.
---
Question 57:
What is Kyverno’s primary function in a Kubernetes environment?
Your answer is correct
An admission controller that enables writing and enforcing policies as Kubernetes resources
---
Question 58:
How can you update the container image of a Kubernetes deployment without modifying other deployment configurations?
Your answer is correct
Use the ‘kubectl set image’ command to update the image
---
Question 59:
When you run the command ‘kubectl apply’, which Kubernetes component processes the request first?
Your answer is correct
kube-apiserver
---
Question 60:
Which directories on a client machine contain sensitive information related to accessing Kubernetes clusters?
Your selection is correct
~/.kube/config
Correct selection
~/.ssh/
Overall explanation
CORRECT ANSWERS:

~/.kube/config and ~/.ssh/ - The kubeconfig file contains cluster credentials and certificates, while SSH keys in ~/.ssh/ may be used for cluster access or node management.

WRONG ANSWERS:

/var/log/ - System logs may contain some information but aren’t primarily for cluster access credentials.

/etc/hosts - This file contains hostname mappings but not sensitive cluster credentials.

/tmp/ - Temporary directory that shouldn’t contain persistent sensitive information.
---
Question 1:
Which field in a Network Policy specification defines which pods the policy applies to?
Your answer is correct
podSelector
---
Question 2:
What does the ‘baseline’ Pod Security Standard prohibit?
Your answer is correct
Using host networking and privileged containers
---
Question 3:
What is the purpose of the kubelet’s --protect-kernel-defaults flag?
Correct answer
To ensure kernel parameters are set to secure defaults
Overall explanation
CORRECT ANSWER:

To ensure kernel parameters are set to secure defaults - This flag makes the kubelet exit if kernel parameters are not set to secure default values, helping ensure the node is properly hardened.

WRONG ANSWERS:

To prevent kernel modules from being loaded - This flag doesn’t control kernel module loading.

To protect against kernel exploits - While it improves security, it specifically checks kernel parameter defaults.

To enable kernel auditing - Kernel auditing is controlled by other mechanisms.

To restrict system calls - System call restrictions are handled by seccomp, not this flag.
---
Question 4:
Which kubelet configuration prevents containers from accessing the host’s process namespace?
Correct answer
Proper pod security contexts (not a kubelet flag)
Overall explanation
CORRECT ANSWER:

Proper pod security contexts (not a kubelet flag) - Process namespace isolation is controlled by pod security contexts (hostPID: false), not by kubelet configuration flags.

WRONG ANSWERS:

–protect-kernel-defaults - This flag checks kernel parameters, not process namespace isolation.

–anonymous-auth=false - This controls authentication, not process namespace access.

–authorization-mode=Webhook - This controls authorization, not process namespace access.

–read-only-port=0 - This disables the read-only port but doesn’t affect process namespace access.
---
Question 5:
Which of the following actions in Kubernetes cross trust boundaries and potentially introduce security risks?
Your selection is correct
Using service accounts across different namespaces

Your selection is correct
Mounting hostPath volumes into pods

Your selection is correct
Pulling container images from public registries
Overall explanation
CORRECT ANSWER:

Mounting hostPath volumes into pods, Using service accounts across different namespaces, and Pulling container images from public registries - These actions cross trust boundaries: hostPath volumes allow access to the host filesystem, cross-namespace service accounts can bypass namespace isolation, and public registry images introduce risks from untrusted sources.

WRONG ANSWERS:

Accessing the Kubernetes API server - API access is controlled and authenticated, within expected trust boundaries.

Communicating between pods within the same namespace - This communication is generally within the same trust boundary and less risky.
---
Question 6:
In Kubernetes RBAC, what does a Role define?
Your answer is correct
Permissions within a namespace
---
Question 7:
What is the primary difference between a Kubernetes Role and a ClusterRole?
Your answer is correct
Role applies to a specific namespace, ClusterRole applies cluster-wide
---
Question 8:
Which security context setting makes the container’s root filesystem read-only?
Your answer is correct
readOnlyRootFilesystem: true
---
Question 9:
What is the purpose of a ServiceAccount in Kubernetes?
Your answer is correct
To provide an identity for processes running in pods
---
Question 10:
Which component is responsible for implementing the Container Runtime Interface (CRI)?
Your answer is correct
Container runtime (containerd, CRI-O, etc.)
---
Question 11:
Which etcd flag enables client certificate authentication?
Your answer is correct
–client-cert-auth
Overall explanation
CORRECT ANSWER:

–client-cert-auth - This flag enables client certificate authentication, requiring clients to present valid certificates to access etcd.

WRONG ANSWERS:

–cert-file - This specifies the server certificate file but doesn’t enable client certificate authentication.

–key-file - This specifies the server private key file but doesn’t enable client authentication.

–trusted-ca-file - This specifies the CA file for verifying certificates but doesn’t enable client authentication by itself.

–peer-cert-file - This is used for peer-to-peer communication, not client authentication.
---
Question 12:
What is the purpose of etcd’s --auto-tls flag?
Your answer is correct
To generate self-signed certificates for testing (not recommended for production)
---
Question 13:
What is the security implication of enabling the kubelet’s read-only port?
Correct answer
It exposes sensitive information without authentication
Overall explanation
CORRECT ANSWER:

It exposes sensitive information without authentication - The read-only port exposes kubelet metrics and pod information without requiring authentication, which can be a security risk.

WRONG ANSWERS:

It provides encrypted access to kubelet metrics - The read-only port typically provides unencrypted access.

It improves performance - Performance is not the primary concern with this port.

It enables better monitoring - While it may enable monitoring, the security risk is the primary concern.

It has no security implications - There are significant security implications to consider.
---
Question 14:
Which statement accurately describes how Kubernetes Network Policies control pod-to-pod communication within a cluster?
Your answer is correct
They use iptables rules (via the CNI plugin) to control pod communication
---
Question 15:
What is required for Network Policies to function in a Kubernetes cluster?
Your answer is correct
A compatible CNI plugin that supports Network Policies
---
Question 16:
Which practice is most important for etcd security in production?
Your answer is correct
Using strong authentication, TLS encryption, and network isolation
---
Question 17:
What is the purpose of the --rotate-certificates kubelet flag?
Your answer is correct
To automatically rotate kubelet client certificates
---
Question 18:
What is the purpose of the AlwaysPullImages admission controller?
Your answer is correct
To force pods to always pull the latest image version
---
Question 19:
What happens during the admission control phase in Kubernetes?
Your answer is correct
Requests are validated and potentially modified before being stored in etcd
---
Question 20:
Which admission controller can mutate pod specifications before they are stored?
Your answer is correct
MutatingAdmissionWebhook
---
Question 21:
Which Pod Security Standard level allows privileged containers?
Correct answer
Privileged
Overall explanation
CORRECT ANSWER:

Privileged - The ‘privileged’ Pod Security Standard allows all pod configurations, including privileged containers with full host access.

WRONG ANSWERS:

Baseline - The baseline standard prohibits privileged containers and other high-risk configurations.

Restricted - The restricted standard is the most stringent and prohibits privileged containers.

None of them - The privileged standard specifically allows privileged containers.

All of them - Only the privileged standard allows privileged containers.
---
Question 22:
Which admission controller prevents the use of the default namespace for workloads?
Correct answer
There is no built-in controller for this
Overall explanation
CORRECT ANSWER:

There is no built-in controller for this - Kubernetes does not have a built-in admission controller that prevents the use of the default namespace. This would need to be implemented using a custom ValidatingAdmissionWebhook.

WRONG ANSWERS:

NamespaceLifecycle - This controller manages namespace creation and deletion, not namespace usage restrictions.

DefaultNamespace - This is not a valid admission controller name.

NamespaceAutoProvision - This is not a valid admission controller name.

ResourceQuota - This controller enforces resource limits within namespaces but doesn’t prevent default namespace usage.
---
Question 23:
What is the primary purpose of Grafana in IT operations?
Your answer is correct
Visualizing and monitoring metrics through dashboards
---
Question 24:
What is the recommended way to secure etcd communication?
Your answer is correct
Enable TLS for all client and peer communication
---
Question 25:
What is the difference between Secrets and ConfigMaps in terms of security?
Your answer is correct
Secrets are base64 encoded and can be encrypted at rest, ConfigMaps store plain text
---
Question 26:
Which admission controller ensures that pods have a ServiceAccount assigned?
Correct answer
ServiceAccount
Overall explanation
CORRECT ANSWER:

ServiceAccount - The ServiceAccount admission controller ensures that pods have a ServiceAccount assigned and automatically mounts the associated token.

WRONG ANSWERS:

DefaultServiceAccount - This is not the correct name of the admission controller.

ServiceAccountAdmission - This is not the correct name of the admission controller.

PodServiceAccount - This is not a valid admission controller name.

AccountManager - This is not a valid admission controller name.
---
Question 27:
Which file contains the kubelet’s configuration on a typical Kubernetes node?
Your answer is correct
/var/lib/kubelet/config.yaml
---
Question 28:
Which tool serves as a data source for visualizing Kubernetes cluster metrics in Grafana?
Your answer is correct
Prometheus
Overall explanation
CORRECT ANSWER:

Prometheus - Prometheus is the most commonly used metrics collection and storage system for Kubernetes clusters, serving as the primary data source for Grafana dashboards to visualize cluster metrics.

WRONG ANSWERS:

Elasticsearch - While Elasticsearch can store metrics, it’s primarily used for log aggregation and search.

InfluxDB - InfluxDB is a time-series database but not the standard choice for Kubernetes metrics.

MySQL - MySQL is a relational database, not suitable for time-series metrics data.

Redis - Redis is an in-memory data store, not typically used for metrics storage.
---
Question 29:
Which Network Policy rule type controls traffic leaving a pod?
Your answer is correct
Egress
---
Question 30:
What does the ‘allowPrivilegeEscalation: false’ security context setting do?
Correct answer
Prevents the container from gaining more privileges than its parent process
Overall explanation
CORRECT ANSWER:

Prevents the container from gaining more privileges than its parent process - This setting prevents processes within the container from gaining additional privileges beyond what they started with.

WRONG ANSWERS:

Prevents the container from running as root - This is controlled by runAsNonRoot, not allowPrivilegeEscalation.

Prevents the container from accessing host resources - Host resource access is controlled by other settings like privileged mode.

Prevents the container from making network connections - Network access is not controlled by this setting.

Prevents the container from writing to the filesystem - Filesystem write access is controlled by readOnlyRootFilesystem.
---
Question 31:
How are Pod Security Standards enforced in a Kubernetes cluster?
Your answer is correct
Via the PodSecurity admission controller
---
Question 32:
Which type of Secret is automatically created for ServiceAccounts?
Your answer is correct
kubernetes.io/service-account-token

Overall explanation
CORRECT ANSWER:

kubernetes.io/service-account-token - This type of Secret is automatically created for ServiceAccounts and contains the authentication token for API server access.

WRONG ANSWERS:

Opaque - This is the default Secret type for user-defined data.

kubernetes.io/dockercfg - This type is used for Docker registry authentication.

kubernetes.io/tls - This type is used for TLS certificates and keys.

kubernetes.io/basic-auth - This type is used for basic authentication credentials.
---
Question 33:
What is the purpose of the LimitRanger admission controller?
Your answer is correct
To set default resource requests and limits for pods
---
Question 34:
Which is the recommended seccomp profile for most containers?
Your answer is correct
RuntimeDefault
Overall explanation
CORRECT ANSWER:

RuntimeDefault - The RuntimeDefault seccomp profile provides a good balance of security and compatibility, using the container runtime’s default seccomp profile.

WRONG ANSWERS:

Unconfined - This provides no seccomp filtering and is less secure.

Localhost - This refers to custom profiles stored on the node, not the general recommendation.

Custom - While custom profiles can be more secure, RuntimeDefault is the general recommendation.

Disabled - Disabling seccomp reduces security.
---
Question 35:
Which port does the kubelet use for its read-only API by default?
Your answer is correct
10255
Overall explanation
CORRECT ANSWER:

10255 - The kubelet’s read-only port traditionally defaults to 10255, though this is often disabled in secure configurations.

WRONG ANSWERS:

10250 - This is the kubelet’s main API port, not the read-only port.

10248 - This is the kubelet’s health check port.

8080 - This is sometimes used for insecure API server access.

6443 - This is the standard secure API server port.
---
Question 36:
Which kubelet flag controls whether anonymous requests are allowed?
Your answer is correct
–anonymous-auth

---
Question 37:
Which label is used to apply Pod Security Standards to a namespace?
Your answer is correct
pod-security.kubernetes.io/enforce
---
Question 38:
What is the purpose of the ResourceQuota admission controller?
Your answer is correct
To enforce resource limits within namespaces
---
Question 39:
Which security context setting prevents a container from running as the root user?
Your answer is correct
runAsNonRoot: true
---
Question 40:
What does the kubelet’s --authorization-mode=Webhook setting do?
Correct answer
Uses the API server for authorization decisions
Overall explanation
CORRECT ANSWER:

Uses the API server for authorization decisions - Webhook authorization mode delegates authorization decisions to the API server, which uses its configured authorization modules (like RBAC).

WRONG ANSWERS:

Disables all authorization - This setting enables authorization, not disables it.

Enables local file-based authorization - File-based authorization would be a different mode.

Uses RBAC for authorization - RBAC is used by the API server, but this setting delegates to the API server generally.

Allows all requests - This setting enforces authorization, not allows all requests.
---
Question 41:
Which admission controller can reject requests based on custom validation logic?

Your answer is correct
ValidatingAdmissionWebhook
---
Question 42:
What is the difference between ‘enforce’, ‘audit’, and ‘warn’ modes in Pod Security Standards?
Your answer is correct
They determine how policy violations are handled
---
Question 43:
What is the purpose of seccomp profiles in Kubernetes?
Your answer is correct
To restrict system calls that containers can make
---
Question 44:
What does AppArmor provide in Kubernetes security?
Your answer is correct
Mandatory Access Control (MAC) for applications
Overall explanation
CORRECT ANSWER:

Mandatory Access Control (MAC) for applications - AppArmor provides Mandatory Access Control by restricting programs’ capabilities with per-program profiles that define what files, paths, and operations are allowed.

WRONG ANSWERS:

Network isolation between pods - Network isolation is provided by Network Policies and CNI plugins.

Encryption of secrets - Secret encryption is handled by etcd encryption and other mechanisms.

User authentication - Authentication is handled by other Kubernetes mechanisms.

Resource quotas - Resource quotas are handled by ResourceQuota objects.
---
Question 45:
How can you prevent a Secret from being automatically mounted into pods?
Correct answer
Set automountServiceAccountToken: false on the ServiceAccount
---
Question 46:
Which Kubernetes resource is used to bind a Role to a user or service account within a namespace?
Your answer is correct
RoleBinding
---
Question 47:
Does setting ‘privileged: true’ on a Kubernetes pod grant it access to Kubernetes Secrets?
Correct selection
Access depends solely on RBAC permissions, regardless of privileged mode

Your selection is correct
No, it only elevates the pod’s privileges on the host system but does not affect Secrets access
Overall explanation
CORRECT ANSWER:

No, it only elevates the pod’s privileges on the host system but does not affect Secrets access and Access depends solely on RBAC permissions, regardless of privileged mode - Privileged mode affects host system access but doesn’t bypass Kubernetes RBAC for Secret access.

WRONG ANSWERS:

Yes, it grants full access to all Secrets in the cluster - Privileged mode doesn’t override RBAC permissions for Secrets.

Yes, but only to Secrets within the same namespace - Privileged mode doesn’t grant any Secret access beyond RBAC.

No, it explicitly prevents access to Secrets - Privileged mode doesn’t prevent Secret access; RBAC controls it.
---
Question 48:
What is the recommended method to rotate TLS certificates in a Kubernetes cluster managed by kubeadm?
Correct answer
Use the ‘kubeadm certs renew’ command to renew certificates
Overall explanation
CORRECT ANSWER:

Use the ‘kubeadm certs renew’ command to renew certificates - Kubernetes clusters initialized with kubeadm provide the ‘kubeadm certs renew’ command to safely renew TLS certificates without manual deletion or downtime.

WRONG ANSWERS:

Manually delete and recreate certificates - Manual deletion can cause downtime and is not the recommended approach.

TLS certificates cannot be rotated once issued - Certificates can and should be rotated for security.

Restart the kubelet service to refresh certificates - Restarting kubelet alone doesn’t renew certificates.

Use a third-party certificate manager exclusively - While third-party managers can be used, kubeadm’s built-in commands are the recommended approach
---
Question 49:
Which etcd security feature encrypts data at rest?
Your answer is correct
Encryption at rest configuration
---
Question 50:
Which admission controller is responsible for automatically mounting ServiceAccount tokens into pods?
Correct answer
ServiceAccount
Overall explanation
CORRECT ANSWER:

ServiceAccount - The ServiceAccount admission controller is responsible for automatically mounting ServiceAccount tokens into pods and ensuring pods have a ServiceAccount assigned.

WRONG ANSWERS:

DefaultServiceAccount - This is not a valid admission controller name.

ServiceAccountTokenVolumeProjection - This is a feature for token projection, not an admission controller.

ServiceAccountAdmission - This is not the correct name of the admission controller.

TokenMount - This is not a valid admission controller name.
---
Question 51:
How do you specify an AppArmor profile for a container in Kubernetes?
Correct answer
Using annotations on the pod
Overall explanation
CORRECT ANSWER:

Using annotations on the pod - AppArmor profiles are specified using the container.apparmor.security.beta.kubernetes.io/<container-name> annotation on the pod.

WRONG ANSWERS:

Using security context in the pod spec - Security context doesn’t include AppArmor profile specification.

Using labels on the namespace - AppArmor profiles are not specified via namespace labels.

Using a separate AppArmor resource - There is no separate AppArmor resource type in Kubernetes.

Using environment variables - AppArmor profiles are not specified via environment variables.
---
Question 52:
What happens when you delete a ServiceAccount that is currently being used by running pods?
Your answer is correct
The pods continue running with their existing tokens until restart
---
Question 53:
What is the primary role of Public Key Infrastructure (PKI) in IT security?
Your answer is correct
Issuing and managing digital certificates and encryption keys
---
Question 54:
In the STRIDE threat model, which category best describes a Trojan horse that compromises a build server?
Correct answer
Tampering

Overall explanation
CORRECT ANSWER:

Tampering - A Trojan horse compromising a build server is an example of tampering because it involves unauthorized modification of system components or data, affecting the integrity of software or systems.

WRONG ANSWERS:

Spoofing - Spoofing involves impersonation of identity, not system modification.

Repudiation - Repudiation relates to denial of actions taken, not system compromise.

Information Disclosure - Information disclosure concerns unauthorized data exposure, not system modification.

Denial of Service - DoS targets availability, not system integrity through malicious modification.
---
Question 55:
What is the recommended way to consume Secrets in pods?
Correct answer
As mounted volumes (preferred) or environment variables
Overall explanation
CORRECT ANSWER:

As mounted volumes (preferred) or environment variables - Secrets can be consumed as mounted volumes (which is preferred for security) or as environment variables, depending on the use case.

WRONG ANSWERS:

As environment variables only - While possible, volume mounts are preferred for security reasons.

As mounted volumes only - Environment variables are also a valid consumption method.

Through direct API calls - Direct API calls require additional authentication and are not the standard approach.

Through ConfigMaps - ConfigMaps are separate resources and don’t provide Secret functionality.
---
Question 56:
What is the primary security benefit of using a CRI-compliant runtime like containerd over Docker?
Your answer is correct
Smaller attack surface and no daemon running as root
Overall explanation
CORRECT ANSWER:

Smaller attack surface and no daemon running as root - CRI-compliant runtimes like containerd have a smaller attack surface and don’t require a daemon running as root, unlike the Docker daemon which traditionally runs with root privileges.

WRONG ANSWERS:

Better performance - While performance may be better, this is not the primary security benefit.

More container formats supported - Container format support is not the primary security benefit.

Better networking capabilities - Networking capabilities are not the primary security benefit.

Built-in image scanning - Image scanning is not a built-in feature of CRI runtimes.
---
Question 57:
Which of the following CNI plugins supports Kubernetes Network Policies?
Your answer is correct
Calico
---
Question 58:
What is the purpose of the ‘restricted’ Pod Security Standard?
Your answer is correct
To enforce the most restrictive security policies for pods
---
Question 59:
What does the term ‘container breakout’ refer to in the context of container security?
Your answer is correct
An attack where an attacker escapes container isolation to gain access to the host system
---
Question 60:
What is the default behavior for pod-to-pod communication when no Network Policies are applied?
Your answer is correct
All communication is allowed

---
