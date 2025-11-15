---
## Question 1 

Perform a manual static analysis on files /root/apps/app1-* considering security.

Move the less secure file to /root/insecure


### Solution:
```bash
controlplane:~/apps$ ls | grep app1
app1-214422c7-Dockerfile
app1-9df32ce3-Dockerfile
controlplane:~/apps$ cat app1-214422c7-Dockerfile
FROM ubuntu
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y golang-go
COPY app.go .
RUN CGO_ENABLED=0 go build app.go
FROM alpine
COPY --from=0 /app .
CMD ["./app"]
controlplane:~/apps$ cat app1-9df32ce3-Dockerfile
FROM ubuntu
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y golang-go
COPY app.go .
RUN CGO_ENABLED=0 go build app.go
CMD ["./app"]
controlplane:~/apps$ cat app1-214422c7-Dockerfile
FROM ubuntu
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y golang-go
COPY app.go .
RUN CGO_ENABLED=0 go build app.go
FROM alpine
COPY --from=0 /app .
CMD ["./app"]
controlplane:~/apps$ mv /root/apps/app1-9df32ce3-Dockerfile /root/insecure
controlplane:~/apps$ 
````

---
## Question 2

Perform a manual static analysis on files /root/apps/app2-* considering security.

Move the less secure file to /root/insecure


### Solution:

```bash
controlplane:~/apps$ ls | grep app2
app2-2782517e-Dockerfile
app2-5cde5c3d-Dockerfile
controlplane:~/apps$ cat app2-2782517e-Dockerfile
FROM ubuntu:20.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y golang-go=2:1.13~1ubuntu2
COPY app.go .
RUN CGO_ENABLED=0 go build app.go
FROM alpine:3.12.0
RUN addgroup -S appgroup && adduser -S appuser -G appgroup -h /home/appuser
COPY --from=0 /app /home/appuser/
USER appuser
CMD ["/home/appuser/app"]
controlplane:~/apps$ 
controlplane:~/apps$ 
controlplane:~/apps$ 
controlplane:~/apps$ cat app2-5cde5c3d-Dockerfile
FROM ubuntu
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y golang-go
COPY app.go .
RUN CGO_ENABLED=0 go build app.go
FROM alpine:3.11.6
COPY --from=0 /app .
CMD ["./app"]

controlplane:~/apps$ mv app2-5cde5c3d-Dockerfile /root/insecure/
```

---
## Question 3

Perform a manual static analysis on files /root/apps/app3-* considering security.

Move the less secure file to /root/insecure


### Solution:
```bash
controlplane:~/apps$ ls | grep app3
app3-1c8650b1-Dockerfile
app3-4049a117-Dockerfile
controlplane:~/apps$ cat app3-1c8650b1-Dockerfile
FROM ubuntu
COPY my.cnf /etc/mysql/conf.d/my.cnf
COPY mysqld_charset.cnf /etc/mysql/conf.d/mysqld_charset.cnf
RUN apt-get update && \
    apt-get -yq install mysql-server-5.6 &&
COPY import_sql.sh /import_sql.sh
COPY run.sh /run.sh
RUN /etc/register.sh $SECRET_TOKEN
EXPOSE 3306
CMD ["/run.sh"]
controlplane:~/apps$ 
controlplane:~/apps$ 
controlplane:~/apps$ 
controlplane:~/apps$ cat app3-4049a117-Dockerfile
FROM ubuntu
COPY my.cnf /etc/mysql/conf.d/my.cnf
COPY mysqld_charset.cnf /etc/mysql/conf.d/mysqld_charset.cnf
RUN apt-get update && \
    apt-get -yq install mysql-server-5.6 &&
COPY import_sql.sh /import_sql.sh
COPY run.sh /run.sh
RUN echo $SECRET_TOKEN > /tmp/token
RUN /etc/register.sh /tmp/token
RUN rm /tmp/token
EXPOSE 3306
CMD ["/run.sh"]
controlplane:~/apps$ diff app3-1c8650b1-Dockerfile app3-4049a117-Dockerfile
8c8,10
< RUN /etc/register.sh $SECRET_TOKEN
---
> RUN echo $SECRET_TOKEN > /tmp/token
> RUN /etc/register.sh /tmp/token
> RUN rm /tmp/token
controlplane:~/apps$ mv app3-4049a117-Dockerfile /root/insecure
controlplane:~/apps$ 
```