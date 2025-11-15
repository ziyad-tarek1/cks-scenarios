---
## Question 1 

The Nginx Ingress Controller has been installed and an Ingress resource configured in Namespace world .

You can reach the application using

curl http://world.universe.mine:30080/europe

Generate a new TLS certificate using:

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout cert.key -out cert.crt -subj "/CN=world.universe.mine/O=world.universe.mine"

Configure the Ingress to use the new certificate, so that you can call

curl -kv https://world.universe.mine:30443/europe

The curl verbose output should show the new certificate being used instead of the default Ingress one.


### Solution:

```bash
# first create the cert and key using the provided command
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout cert.key -out cert.crt -subj "/CN=world.universe.mine/O=world.universe.mine"
# check the created files
ls
# change the cluster context to the namespace 
k config set-context --current --namespace world  

# create the tls secret
kubectl create secret tls world-secret \
  --cert=cert.crt \
  --key=cert.key        

# save the current ingress & backup from it
k get ingress world -o yaml > word.yaml
k get ingress world -o yaml > word.yaml.backup
```
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: world
  namespace: world
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /$1
spec:
  ingressClassName: nginx
  tls:                            # add
  - hosts:                        # add
    - world.universe.mine         # add
    secretName: world-secret       # add
  rules:
  - host: "world.universe.mine"
    http:
      paths:
      - path: /europe
        pathType: Prefix
        backend:
          service:
            name: europe
            port:
              number: 80
      - path: /asia
        pathType: Prefix
        backend:
          service:
            name: asia
            port:
              number: 80
```