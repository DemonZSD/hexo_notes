
---
title: 解决 kube-apiserver 报  too many open files 错误信息
date: 2019-03-29 10:31:21
tags:
  - kubernetes
  - Issue
categories:
  - 运维
  - kubernetes
---


在k8s集群中，在获取资源时，会遇到 `kubectl ` 命令阻塞，经查看发现是 kube-apiserver 报错，搜索解决方案，发现 github 上已经有人遇到过该问题，并提交了 [`Issues#703`](https://github.com/juju-solutions/bundle-canonical-kubernetes/issues/) 和 [`Issues#67004`](https://github.com/kubernetes/kubernetes/issues/67004)

**错误信息如下：**

```
$ systemctl status kube-apiserver -l
● kube-apiserver.service - Kubernetes API Server
   Loaded: loaded (/etc/systemd/system/kube-apiserver.service; disabled; vendor preset: disabled)
   Active: active (running) since Sat 2019-03-16 20:02:13 CST; 1 weeks 4 days ago
     Docs: https://github.com/GoogleCloudPlatform/kubernetes
 Main PID: 75456 (kube-apiserver)
    Tasks: 63
   Memory: 3.3G
   CGroup: /system.slice/kube-apiserver.service
           └─75456 /etc/kubernetes/bin/kube-apiserver --logtostderr=true --v=0 --etcd-servers=http://192.168.43.33:2379 --insecure-bind-address=0.0.0.0 --insecure-port=8080 --kubelet-read-only-port=10250 --allow-privileged=true --service-cluster-ip-range=10.254.0.0/16 --admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ResourceQuota --cert-dir=/etc/kubernetes/var/kube-apiserver --service-node-port-range=80-65535 --feature-gates=Accelerators=true

Mar 28 16:52:41 aios-4 kube-apiserver[75456]: I0328 16:52:41.255220   75456 logs.go:41] http: Accept error: accept tcp [::]:8080: accept4: too many open files; retrying in 1s
Mar 28 16:52:42 aios-4 kube-apiserver[75456]: I0328 16:52:42.255612   75456 logs.go:41] http: Accept error: accept tcp [::]:8080: accept4: too many open files; retrying in 1s
Mar 28 16:52:43 aios-4 kube-apiserver[75456]: I0328 16:52:43.255943   75456 logs.go:41] http: Accept error: accept tcp [::]:8080: accept4: too many open files; retrying in 1s
Mar 28 16:52:44 aios-4 kube-apiserver[75456]: I0328 16:52:44.256205   75456 logs.go:41] http: Accept error: accept tcp [::]:8080: accept4: too many open files; retrying in 1s
Mar 28 16:52:45 aios-4 kube-apiserver[75456]: I0328 16:52:45.256630   75456 logs.go:41] http: Accept error: accept tcp [::]:8080: accept4: too many open files; retrying in 1s
Mar 28 16:52:46 aios-4 kube-apiserver[75456]: I0328 16:52:46.257040   75456 logs.go:41] http: Accept error: accept tcp [::]:8080: accept4: too many open files; retrying in 1s
Mar 28 16:52:47 aios-4 kube-apiserver[75
```

**环境信息：**

- Kubernetes version (use kubectl version): v1.11.0
- Cloud provider or hardware configuration: vultr
- OS (e.g. from /etc/centos-release): CentOS Linux release 7.6.1810 (Core)
- Kernel (e.g. uname -a): Linux  vultr.guest 3.10.0-957.1.3.el7.x86_64


Linux操作系统中，有一个控制系统 `open files` 的参数，可以通过 `ulimit -a` 进行查看：

``` shell
$ ulimit -a 
core file size          (blocks, -c) 0
data seg size           (kbytes, -d) unlimited
scheduling priority             (-e) 0
file size               (blocks, -f) unlimited
pending signals                 (-i) 3872
max locked memory       (kbytes, -l) 64
max memory size         (kbytes, -m) unlimited
open files                      (-n) 1024
pipe size            (512 bytes, -p) 8
POSIX message queues     (bytes, -q) 819200
real-time priority              (-r) 0
stack size              (kbytes, -s) 8192
cpu time               (seconds, -t) unlimited
max user processes              (-u) 3872
virtual memory          (kbytes, -v) unlimited
file locks                      (-x) unlimited
```

可以看到，`open files` 当前限制为 1024 。 可以通过修改配置文件: /etc/security/limits.conf 修改参数值。 在这个文件后加上：
``` shell
* soft nofile 102400
* hard nofile 102400
```

重启机器，生效。


停止 `kube-apiserver`

``` shell
$ systemctl stop kube-apiserver
```

查看kube-apiserver.service配置文件：
``` shell
$ systemctl cat kube-apiserver
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target
After=etcd.service

[Service]
EnvironmentFile=-/etc/kubernetes/config/config
EnvironmentFile=-/etc/kubernetes/config/apiserver
User=k8suser
ExecStart=/etc/kubernetes/bin/kube-apiserver \
	    $KUBE_LOGTOSTDERR \
	    $KUBE_LOG_LEVEL \
	    $KUBE_ETCD_SERVERS \
	    $KUBE_API_ADDRESS \
	    $KUBE_API_PORT \
	    $KUBELET_PORT \
	    $KUBE_ALLOW_PRIV \
	    $KUBE_SERVICE_ADDRESSES \
	    $KUBE_ADMISSION_CONTROL \
	    $KUBE_APISERVER_CERT_DIR \
	    $KUBE_API_ARGS
Restart=on-failure
RestartSec=5
StartLimitIntervalSec=0
Type=notify

[Install]
WantedBy=multi-user.target

```
编辑 `kube-apiserver.service` 文件，在 `[Service]` 单元最下方添加参数最大文件限制个数 `LimitNOFILE=65536` 或者 `LimitNOFILE=infinity` ， 如下：

``` shell
...  
// 省略上方 kube-apiserver.service内容
RestartSec=5
StartLimitIntervalSec=0
Type=notify
LimitNOFILE=65536


[Install]
WantedBy=multi-user.target

```

然后重启服务

``` shell
$ systemctl daemon-reload
$ systemctl start kube-apiserver
```


查看 `kube-apiserver` 资源线程详情，75456为 `kube-apiserver` 线程ID：

``` shell
$ cat /proc/75456/limits
Limit                     Soft Limit           Hard Limit           Units     
Max cpu time              unlimited            unlimited            seconds   
Max file size             unlimited            unlimited            bytes     
Max data size             unlimited            unlimited            bytes     
Max stack size            8388608              unlimited            bytes     
Max core file size        unlimited            unlimited            bytes     
Max resident set          unlimited            unlimited            bytes     
Max processes             unlimited            unlimited            processes 
Max open files            65536                65536                files     
Max locked memory         65536                65536                bytes     
Max address space         unlimited            unlimited            bytes     
Max file locks            unlimited            unlimited            locks     
Max pending signals       3872                 3872                 signals   
Max msgqueue size         819200               819200               bytes     
Max nice priority         0                    0                    
Max realtime priority     0                    0                    
Max realtime timeout      unlimited            unlimited            us  
```



