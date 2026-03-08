---
## Question 1 
There are two existing Deployments in Namespace world which should be made accessible via an Ingress.

First: create ClusterIP Services for both Deployments for port 80 . The Services should have the same name as the Deployments.

### Solution:

```bash
k config set-context --current --namespace world
```
```bash
k get deployments.apps 
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
asia     2/2     2            2           7m29s
europe   2/2     2            2           7m29s

k expose deployment asia --name asia --port 80        
service/asia exposed

k expose deployment europe --name europe --port 80
service/europe exposed

````

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: world
  namespace: world
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: world.universe.mine
    http:
      paths:
      - pathType: Prefix
        path: "/europe"
        backend:
          service:
            name: europe
            port:
              number: 80
      - pathType: Prefix
        path: "/asia"
        backend:
          service:
            name: asia
            port:
              number: 80
```