---
## Question 1 

Your team has decided to use kube-bench via a DaemonSet instead of installing via package manager.

Go ahead and remove the kube-bench package using the default package manager.

### Solution:

```bash
apt show kube-bench

apt remove kube-bench
```

---
## Question 2:

The package vsftpd has been installed.

Don't uninstall it, just stop the service.

### Solution:

```bash
sudo systemctl status vsftpd
sudo systemctl stop vsftpd
```