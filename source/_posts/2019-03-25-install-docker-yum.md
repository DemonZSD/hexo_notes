---
title: Centos 安装 docker
date: 2019-03-25 13:35:59
tags:
  - docker
categories:
  - 运维
  - docker
---

>本教程适用于对docker入门新手，在学习docker时，安装部署docker是第一步，然后跟着教程一步一步练习。

#### 移除旧版本docker
卸载旧版本docker，如果未安装，可以跳过
```
$ yum remove -y docker docker-client \
   docker-client-latest  \
   docker-common \
   docker-latest \
   docker-latest-logrotate \
   docker-logrotate \
   docker-selinux \
   docker-engine-selinux \
   docker-engine
```
#### 安装依赖软件
```
$ yum install -y yum-utils \
    device-mapper-persistent-data \
    lvm2
```
#### 配置yum源为阿里云提供的yum源
```
$ yum-config-manager \
--add-repo \
https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

#### 查看该yum源提供的可用docker-ce版本
```
$ yum list docker-ce –showduplicates | sort -r

docker-ce.x86_64            3:18.09.0-3.el7                    docker-ce-stable 
docker-ce.x86_64            18.06.1.ce-3.el7                   docker-ce-stable 
docker-ce.x86_64            18.06.1.ce-3.el7                   @docker-ce-stable
docker-ce.x86_64            18.06.0.ce-3.el7                   docker-ce-stable 
docker-ce.x86_64            18.03.1.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            18.03.0.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.12.1.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.12.0.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.09.1.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.09.0.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.06.2.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.06.1.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.06.0.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.03.3.ce-1.el7                   docker-ce-stable 
docker-ce.x86_64            17.03.2.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.03.1.ce-1.el7.centos            docker-ce-stable 
docker-ce.x86_64            17.03.0.ce-1.el7.centos            docker-ce-stable
```

 查看可用docker-ce版本，根据需求，安装指定版本的docker-ce
 安装docker-ce 18.06版本

 - 安装docker-ce 18.06版本

   `$ yum install docker-ce-18.06.1.ce -y`

 - 启动docker

   `$ systemctl start docker`

 - 设置开机启动

   `$ systemctl enable docker`

 - 授权用户
   
   将用户添加到docker组

   `$ sudo usermod -aG docker $USER`

- 配置镜像仓库加速

  配置镜像加速：使用aliyun提供的镜像加速

  通过修改daemon配置文件/etc/docker/daemon.json来使用加速器
   ```
   $ sudo mkdir -p /etc/docker
   $ sudo tee /etc/docker/daemon.json <<-'EOF' {
       "registry-mirrors":["https://xxxxxx.mirror.aliyuncs.com"] }
     EOF
   ```

   注意 https://xxxxxx.mirror.aliyuncs.com 需要注册阿里云申请镜像仓库
   如果没有，可以使用作者的：https://hjjs2fuv.mirror.aliyuncs.com

- 重新加载docker service使其生效

  `$ systemctl daemon-reload`

  `$ systemctl restart docker`


