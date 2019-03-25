---
title: Docker网络驱动(network driver)之————网桥(bridge) 
date: 2019-03-25 13:33:15
tags:
  - docker
categories:
  - 运维
  - docker
---

Docker网络驱动(network driver)之————网桥(bridge)
>在《计算机网络》这本教材中，我们学习过，**网桥**是一种工作在数据链路层，对帧进行转发的技术，它根据MAC帧的目标地址对收到的帧进行转发和过滤。网桥可以是硬件设备也可以是在主机内核（kernel）中运行的软件设备。

在Docker的网络系统中，**网桥**`bridge network`是默认的网络驱动。使用软件桥接器，允许连接到同一桥接网络的**容器**之间进行通信，同时隔离那些未连接到该**网桥**的容器。当启动`Docker daemon`（`docker`守护进程)时，会自动创建**网桥**（`bridge network`），称为:`bridge`，即对应host上的`docker0`。`Docker network`会自动在主机中安装规则，以阻止不同网桥上的容器进行相互通信。

查看主机上的网络设备
```
$ ip addr 
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:eb:89:b8 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global noprefixroute dynamic enp0s3
       valid_lft 84147sec preferred_lft 84147sec
    inet6 fe80::eef9:c7e0:7365:65b6/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:22:76:1d brd ff:ff:ff:ff:ff:ff
    inet 192.168.56.102/24 brd 192.168.56.255 scope global noprefixroute dynamic enp0s8
       valid_lft 996sec preferred_lft 996sec
    inet6 fe80::a88:e4da:b641:f973/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
4: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 02:42:60:e0:e9:55 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:60ff:fee0:e955/64 scope link 
       valid_lft forever preferred_lft forever
```
查看docker网络驱动
```
$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
b549b06a92e7        bridge              bridge              local
c5149e25deea        host                host                local
bfa90bfc3dfe        none                null                local
```

**网桥**`bridge network`适用于在同一个Docker守护进程的主机上运行的容器。对于在不同Docker守护进程主机上运行的容器之间的通信，可以在操作系统级别管理路由，可以使用原生的[覆盖网络`overlay`](https://docs.docker.com/network/overlay/)和[`macvlan`](https://docs.docker.com/network/macvlan/)。也可使用第三方网络插件：常用的包括 flannel、weave 和 calico

如果用户启动一个新的容器（`container`），则默认会连接到该网桥，除非在启动容器时指定了自定义网桥（`self-defined bridge networks`）。
**自定义网桥**在容器安全性、容器间通信等方面优于默认网桥（`bridge`）

#### 用户定义的网桥与默认网桥之间的区别

 - 用户定义的网桥可在容器化应用程序（`container application`）之间提供更好的隔离性和连通性
   连接到同一个用户定义的网桥的容器会自动将所有端口相互暴露，而不会向外界暴露任何端口。这使得容器中的应用程序可以轻松地相互通信，而阻止外界对容器的访问。

   比如：有一个web前端和db后端两个容器，集群外部需要访问web前端（比如80端口）。使用用户定义的网桥，可以实现允许外部访问web前端，阻止访问db后端（比如：3306）。而web前端可以通过自定义网桥对db容器进行访问。
   如果在默认网桥上运行相同的应用程序（web前端和db后端），则需要同时暴露Web端口（80）和数据库端口（3306），并为每个端口使用-p或--publish标志。 这意味着Docker主机需要通过其他方式阻止对db数据库端口的访问。

 - 用户定义的桥接器在容器之间提供自动DNS解析
   默认网桥上的容器只能通过IP地址相互访问（无法直接访问IP:PORT），除非您使用`--link`选项（该属性官方建议后续不再使用）。 而在用户定义的桥接网络上，容器可以通过名称或别名相互解析。
   还拿上个例子说明：如果在默认网桥上运行web容器和db容器，则需要在容器之间手动的创建链接（`--link`）。如果容器数量达到几十或者几百，那么工作量将会非常大。
   
 - 容器可以在运行中与用户定义的网络连接和分离
   
 - 每个用户定义的网络都会创建一个可配置的网桥
   如果容器使用默认桥接网络，则可以对其进行配置，但所有容器都使用相同的设置，例如MTU（最大传输数据包大小）和iptables规则。 此外，配置默认桥接网络，需要重新启动Docker。 使用`docker network create`创建和配置用户定义的网桥。 如果不同的应用程序组具有不同的网络要求，则可以在创建时单独配置每个用户定义的网桥。
   ```
   $ docker network create my-net
   ```

 - 默认桥接网络上的链接容器共享环境变量
   最初，在两个容器之间共享环境变量的唯一方法是使用--link标志链接它们。 用户定义的网络无法实现这种类型的变量共享。 但是，有更好的方法来共享环境变量。 一些想法：

   - 多个容器可以挂载包含共享信息的文件或目录，使用`Docker volume`挂载卷进行文件或者变量共享。

   - 可以使用`docker-compose`一起启动多个容器，并且compose文件可以定义共享变量。

   - 您可以使用集群服务（`swamp service`）而不是独立容器，并利用[`secrets`](https://docs.docker.com/engine/swarm/secrets/)和[`configs`](https://docs.docker.com/engine/swarm/configs/)共享变量。
     ```
	 docker service create \
     --name nginx \
     --secret site.key \
     --secret site.crt \
     --config source=site.conf,target=/etc/nginx/conf.d/site.conf,mode=0440 \
     --publish published=3000,target=443 \
     nginx:latest \
     sh -c "exec nginx -g 'daemon off;'"
	 ```
#### 创建用户自定义网桥（self-define ）

- 使用命令`docker network create ` 命令创建用户自定义网络
   
   具体使用方法可以使用`docker network create --help`获取帮助  
    ```
    $ docker network create \
     --driver=bridge \
     --subnet=172.28.0.0/16 \
     --ip-range=172.28.5.0/24 \
     --gateway=172.28.5.254 \
        br0
   ```

- 使用命令`docker network rm `命令删除已存在的网络
   ```
   $ docker network rm my-net
   ```
当用户**删除**或**创建**网络，或者用户将容器连接（断开连接）到自定义网络时，操作系统会管理底层网络基础架构（创建（删除）网桥或者修改`iptables`规则）。这些操作对用户来说是透明的。

#### 连接容器到自定义网络
用户在创建容器时，可以指定连接到自定义网络（使用`--network`方式）；也可以将正在运行的（runing)的容器连接到自定义网络。

 - 创建容器，并连接到自定义网络

   例如：创建`Nginx`容器，连接到`my-net`网络中
   ```
   $ docker create --name my-nginx \
      --network my-net \
      --publish 8080:80 \
      nginx:latest
   ```
   创建一个容器`my-nginx`，连接到已存在的`my-net` 网络中，并且将容器内部开放的80端口映射到宿主机的8080端口上。在容器外部，可以通过8080端口访问该容器。

 - `running`容器连接到自定义网络中

   启动`my-nignx`容器
   ```
   $ docker run --name my-nginx \
      --publish 8080:80 \
      nginx:latest
   ```
   连接到`my-net`自定义网络
   ```
   $ docker network connect my-net my-nginx
   ```
   如果启动docker容器时，不指定自定义网桥，则容器会连接默认网桥。连接到默认网桥的容器客户相互通信，但是只能通过IP地址进行通信。

#### 修改Docker默认网桥
修改默认网桥，有两种方式：修改dockerd启动配置文件 和 修改Docker守护进程daemon.json文件

 - 修改dockerd启动配置文件

   dockerd启动文件默认位置：`/usr/lib/systemd/system/docker.service`
   ```
   ...
   ExecStart=/usr/bin/dockerd -H unix:///var/run/docker.sock \
     -H tcp://0.0.0.0:2376 \
     --bip=10.2.54.1/24 \ 
     --mtu=1450 \ 
     --dns=["10.20.1.2","10.20.1.3"]
   ...
   ```

 - daemon.json文件
   ```
   {
      "bip": "192.168.1.5/24",
      "fixed-cidr": "192.168.1.5/25",
      "fixed-cidr-v6": "2001:db8::/64",
      "mtu": 1500,
      "default-gateway": "10.20.1.1",
      "default-gateway-v6": "2001:db8:abcd::89",
      "dns": ["10.20.1.2","10.20.1.3"]
   }
   ```
使参数生效，则需要重启Docker守护进程。







