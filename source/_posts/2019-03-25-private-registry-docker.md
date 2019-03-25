---
title: Centos搭建Docker私有仓库, Registry
date: 2018-09-13 13:47:14
tags:
  - docker
categories:
  - 运维
  - docker
author: weshzhu

---


关于docker的安装：
[CENTOS7二进制安装DOCKER-CE](http://www.weshzhu.com/2019/01/03/binary-install-docker-ce-on-centos7/)
[CENTOS7 安装DOCKER-CE，并且配置 ALIYUN 加速](http://www.weshzhu.com/2019/03/25/install-docker-yum/)

1. 覆盖掉目录/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem （**对于刚拿到的系统，一定要先备份，切记！本教程适用于 循环创建Docker支持https的私有仓库**）
	cp /home/zsd/tls-ca-bundle.pem /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem

2. 修改openssl.cnf文件
	vi /etc/pki/tls/openssl.cnf
	在[v3_ca]下面添加 subjectAltName = IP:192.168.0.11
	
3. openssl生成私有证书
	openssl req [-subj "/C=CN/ST=BeiJing/L=Dongcheng/CN=192.168.0.11"] -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout registry.key -out registry.crt
	openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout registry.key -out registry.crt
	
4. 将生成证书内容追加到该服务器上的证书存放目录的内置信任的证书
	cat /certs/registry.crt >> /etc/pki/tls/certs/ca-bundle.crt
	
5. 重启docker
	systemctl restart docker

6. 运行registry
	docker run -d -p 443:443 --name registry -v /deploy/certs:/certs -e REGISTRY_HTTP_ADDR=0.0.0.0:443 -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/registry.crt -e REGISTRY_HTTP_TLS_KEY=/certs/registry.key registry:2
	
7. push镜像到registry
	docker push 192.168.0.11/nginx
	常见错误
	a. Get https://192.168.0.11/v2/: x509: cannot validate certificate for 192.168.0.11 because it doesn't contain any IP SANs  未操作第4步
	b. Get https://<IpAddress>/v2/: x509: certificate signed by unknown authority  #未操作第6步

具体教程可参考[x509: cannot validate certificate because of not containing any IP SANs](http://blog.csdn.net/zsd498537806/article/details/79290732)
