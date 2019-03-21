---
title: gcr.io和quay.io拉取镜像失败
date: 2019-03-21 11:17:18
tags:
  - docker
categories:
  - 运维
  - docker
---

k8s在使用编排（manifest）工具进行yaml文件启动pod时，会遇到官方所给例子中`spec.containers.image`包含：
```
quay.io/coreos/example_
gcr.io/google_containers/example_
```
也就是说，从quay.io和gcr.io进行镜像拉取，我们知道，国内访问外网是被屏蔽了的。可以将其替换为 quay-mirror.qiniu.com 和 registry.aliyuncs.com
- 例如
    **下拉镜像**：`quay.io/coreos/flannel:v0.10.0-s390x`
    如果拉取较慢，可以改为：`quay-mirror.qiniu.com/coreos/flannel:v0.10.0-s390x`
    
    **下拉镜像**：`gcr.io/google_containers/kube-proxy`
    可以改为： `registry.aliyuncs.com/google_containers/kube-proxy`



