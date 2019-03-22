---
title: Docker中启动jenkins容器，并在jenkins中使用docker 命令，解决docker command not found
date: 2018-03-21 20:04:07
tags:
  - docker
  - jenkins
categories:
  - 运维
  - docker
---


首先，制作支持docker的jenkins镜像，基础镜像是`jenkins:2.60.3`
参考[Running Docker in Jenkins (in Docker)](https://container-solutions.com/running-docker-in-jenkins-in-docker/)

编辑Dockerfile，内容如下：
```
FROM jenkins:2.60.3

USER root
RUN echo '' > /etc/apt/sources.list.d/jessie-backports.list \
  && echo "deb http://mirrors.aliyun.com/debian jessie main contrib non-free" > /etc/apt/sources.list \
  && echo "deb http://mirrors.aliyun.com/debian jessie-updates main contrib non-free" >> /etc/apt/sources.list \
  && echo "deb http://mirrors.aliyun.com/debian-security jessie/updates main contrib non-free" >> /etc/apt/sources.list

RUN apt-get update       && apt-get install -y sudo       && apt-get install -y libltdl7       && rm -rf /var/lib/apt/lists/*
RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

USER jenkins
COPY plugins.txt /usr/share/jenkins/plugins.txt
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/plugins.txt

```



出现在执行docker命令时报：`docker: error while loading shared libraries: libltdl.so.7: cannot open shared object file: No such file or directory`错误[解决办法，参考](https://www.cnblogs.com/leolztang/p/6934694.html)
加入如下代码后，问题解决：
```
RUN echo '' > /etc/apt/sources.list.d/jessie-backports.list \
  && echo "deb http://mirrors.aliyun.com/debian jessie main contrib non-free" > /etc/apt/sources.list \
  && echo "deb http://mirrors.aliyun.com/debian jessie-updates main contrib non-free" >> /etc/apt/sources.list \
  && echo "deb http://mirrors.aliyun.com/debian-security jessie/updates main contrib non-free" >> /etc/apt/sources.list
```
预先安装的插件，放入plugins.txt文件中，也可以部署jenkins后，手动安装插件。
```

scm-api:latest
git-client:latest
git:latest
greenballs:latest

```
启动jenkins容器，执行如下命令，启动jenkins容器

```
docker run -d -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/usr/bin/docker -v $PWD:/var/jenkins_home -p 8080:8080 jenkins:v2.6
```
注意挂载`-v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/usr/bin/docker`，才可以共享宿主机的docker资源
指定工作目录：`-v $PWD:/var/jenkins_home`，将当前目录作为jenkins的工作目录。
此时，可以通过ip:8080端口访问jenkins，按照提示一步一步进行。配置完后，就可以使用了。
首先，我们新建一个pipeline构建计划，Jenkinsfile内容：

```
pipeline {
    agent any
    stages {
        stage('Test') {
            steps {
                sh 'docker images'
            }
        }
    }
}
```
，执行立即构建，当执行pipeline中的`docker images`命令时，报错：
```
+ docker images
Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get http://%2Fvar%2Frun%2Fdocker.sock/v1.37/images/json: dial unix /var/run/docker.sock: connect: permission denied
```
这是jenkinsfile中的命令在访问宿主机的`unix:///var/run/docker.sock`守护进程时，权限不足。在jenkins中，执行pipeline的用户是jenkins，可以在pipelines中的docker命令前增加`sudo `，便成功执行：

```
[test_pipeline] Running shell script
+ sudo docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
jenkins             v2.6.3              7c6cba7c8a03        18 minutes ago      705MB
jenkins             v2.6                bb042102b598        3 hours ago         705MB
jenkins             2.60.3              cd14cecfdb3a        2 days ago          696MB
busybox             latest              22c2dd5ee85d        3 days ago          1.16MB
```
