---
title: docker网络驱动之--overlay网络
date: 2019-03-21 20:23:46
tags: 
  - docker
categories:
  - 运维
  - docker
---



>`docker overlay`网络用于创建多个docker主机之间的分布式网络。该网络位于（覆盖）特定于主机的网络之上，可以将`swarm`集群服务和`containers`容器与`overlay`网络进行连接，使各个服务或者服务与容器之间进行通信。

#### 创建或加入`swarm`服务

在创建和使用`overlay`之前，必须初始化一个[`swarm`](https://docs.docker.com/engine/swarm/)或者加入某个`swarm`:

- 创建一个`swarm`集群服务

  用法：`docker swarm init [OPTIONS]`，针对常用的`[OPTIONS]`介绍见下方表格：
  
  参数说明

  |参数|类型|默认值|说明|
  |-----|-----|-----|-----|
  |`--advertise-addr`| string ||多块网卡时对应多个IP地址时，需要指定|
  |`--data-path-addr`|string||用于数据流量传输的IP地址或者网卡名称（例：`eth0`）|
  |`--listen-addr`|node-addr|0.0.0.0:2377|监听地址|


  **示例：创建`swarm`服务**
 
  我们用两个节点进行演示，一个node既是管理节点，工作节点；一个node仅是工作节点：

   ```
   node1 : 192.168.0.190  (manager & worker)
   node2 : 192.168.0.191 (worker)
   ```
   
   ![swarm架构](/images/swarmcluster.png)
   
   - 创建`swarm`集群服务

     ```
     $ docker swarm init --advertise-addr 192.168.0.190
     Swarm initialized: current node      (se5tsje7l9oibpsx54bbe7nuf) is now amanager.
     To add a worker to this swarm, run the following      command:
       docker swarm join      --tokenSWMTKN-1-45ffvnn83wrl0aprynpcs0cogtg951kns  t fq  n7ok98hizonw9s-e5p7e5yjfit5tx6l1kp3e6d9      192.168.0.190:2377
     To add a manager to this swarm, run 'docker swarm      join-tokenmanager' and follow the instructions.
   
     ```
 
     注意到执行初始化`swarm`语句时，会打印出其他node节点加 入该`swarm`的方式：
 
     ```
     docker swarm join --token xxxx <manager-ip>:<port>
     ```
     
     可以将其保存到文档，以便于后续`swarm`Node的[join]   (https://docs.docker.   com/engine/reference/commandline/swarm_join/)。
   
     查看docker网络
   
     ```
     $docker network ls
     NETWORK ID          NAME                DRIVER                 SCOPE
     ba18dbad1160        bridge              bridge                 local
     58886c346808        docker_gwbridge     bridge                 local
     7966432ad37e        host                host                   local
     yryhkokko1tk        ingress             overlay                swarm
     d1ab833f3555        none                null                   local
     ```
 
     可以看到在docker网络中，新增了`ingress`和 `docker_gwbridge`网络。
   
     - `ingress`

       一个名为ingress的覆盖网络，用于处理与`swarm`服务相关   的控制和数据流量。创建`swarm`服务时，如果不将其连接   到用户定义的覆盖网络，则默认情况下会连接到该   `ingress`网络

       使用 `docker network inspect ingress`查看现有的   `ingress`网络。
     
       ```
       $ docker inspect ingress
       [
           {
               "Name": "ingress",
               "Id": "yryhkokko1tkpkhx0pf0e1zm3",
               "Created": "2019-01-08T17:05:50.511486192+08:00",
               "Scope": "swarm",
               "Driver": "overlay",
               "EnableIPv6": false,
               "IPAM": {
                   "Driver": "default",
                   "Options": null,
                   "Config": [
                       {
                           "Subnet": "10.255.0.0/16",
                           "Gateway": "10.255.0.1"
                       }
                   ]
               },
               "Internal": false,
               "Attachable": false,
               "Ingress": true,
               "ConfigFrom": {
                   "Network": ""
               },
               "ConfigOnly": false,
               "Containers": {
                   "ingress-sbox": {
                       "Name": "ingress-endpoint",
                       "EndpointID": "75df50d1f8228ff64d65a6801bc2a93e31de3f72adaec01e147abd266d3d64eb",
                       "MacAddress": "02:42:0a:ff:00:03",
                       "IPv4Address": "10.255.0.3/16",
                       "IPv6Address": ""
                   }
               },
               "Options": {
                   "com.docker.network.driver.overlay.vxlanid_list": "4096"
               },
               "Labels": {},
               "Peers": [
                   {
                       "Name": "5e8427535708",
                       "IP": "192.168.0.190"
                   },
                   {
                       "Name": "42c5607b0c46",
                       "IP": "192.168.0.191"
                   }
               ]
           }
       ]
       ```

     - `docker_gwbridge`

       一个名为`docker_gwbridge`的桥接网络，它用于各个  `swarm`中，各个node节点进行通信的桥接网络。
     
       ```
       $ docker inspect docker_gwbridge
       [
           {
               "Name": "docker_gwbridge",
               "Id": "2c7254c25f765b28833668e060246a813d69b8936a5db1a8cd2bc7237dfc7df4",
               "Created": "2019-01-08T17:05:51.263715613+08:00",
               "Scope": "local",
               "Driver": "bridge",
               "EnableIPv6": false,
               "IPAM": {
                   "Driver": "default",
                   "Options": null,
                   "Config": [
                       {
                           "Subnet": "172.18.0.0/16",
                           "Gateway": "172.18.0.1"
                       }
                   ]
               },
               "Internal": false,
               "Attachable": false,
               "Ingress": false,
               "ConfigFrom": {
                   "Network": ""
               },
               "ConfigOnly": false,
               "Containers": {
                   "ingress-sbox": {
                       "Name": "gateway_ingress-sbox",
                       "EndpointID": "4f6821a4096104af4f04aea5caab7a5a3419a2b6469b31ea7a52f4c92b9023af",
                       "MacAddress": "02:42:ac:12:00:02",
                       "IPv4Address": "172.18.0.2/16",
                       "IPv6Address": ""
                   }
               },
               "Options": {
                   "com.docker.network.bridge.enable_icc": "false",
                   "com.docker.network.bridge.enable_ip_masquerade": "true",
                   "com.docker.network.bridge.name": "docker_gwbridge"
               },
               "Labels": {}
           }
       ]
       ```

- 增加工作（`worker`）节点
   
    将node2(192.168.0.191)加入到该`swarm`：

    ```
    $ docker swarm join --token \
      SWMTKN-1-45ffvnn83wrl0aprynpcs0cogtg951knstfqn7ok98hizonw9s-e5p7e50yjfit5tx6l1kp3e6d9  \
      192.168.0.190:2377

      This node joined a swarm as a worker.
    ```

    查看node

    ```
    $ docker node ls
      ID                            HOSTNAME             STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
      se5tsje7l9oibpsx54bbe7nuf *   host1                 Ready               Active              Leader              18.03.1-ce
      timpbicei0sxbsuv9rq1625eh     host2                 Ready               Active                                  18.03.1-ce
    ```
   
     查看**工作节点**的docker网络
   
     ```
     $ docker network ls 
       NETWORK ID          NAME                DRIVER                    SCOPE
       e39a5d50e807        bridge              bridge                    local
       2c7254c25f76        docker_gwbridge     bridge                    local
       a284efd6e1f2        host                host                      local
       yryhkokko1tk        ingress             overlay                   swarm
       13bd88a34632        none                null                  local
     ```

#### `overlay`网络
 
 - 创建`overlay`网络

   在创建`overlay`网络前，需要初始化或者加入`swarm`服务。即使可能后续不会使用`swarm`服务，也需要执行此操作。之后，您可以创建其他用户定义的覆盖网络。

   要创建用于swarm服务的覆盖网络，请使用如下命令：
   
   ```
   $ docker network create -d overlay my-overlay
   ```

   要创建可由群集服务或独立容器用于与在其他Docker守护进程主机上运行的其他独立容器通信的`overlay`网络，必须添加`--attachable`标志：

   ```
   $ docker network create -d overlay --attachable my-attachable-overlay
   ```

   在创建可以指定IP地址范围，子网，网关和其他选项。有关详细信息，请参阅docker network create --help
  
 - `overlay`网络流量加密（不支持windows操作系统）
   
   在`swarm`服务中的管理流量默认是通过`GCM-AES`加密算法进行加密。如果尝试对容器间的流量进行加密，在创建覆盖网络时添加`--opt encrypted`属性，Docker会在各个工作节点之间建立`IPSEC`隧道。但是通常加密解密操作需要消耗一定的性能，若将网络加密应用于生产环境，一定对该性能损耗进行评估。


 - 自定义默认`ingress`

   Docker 17.05之后的版本，才支持用户修改默认`ingress`网络。如果自动选择的子网与网络上已存在的子网冲突，或者您需要自定义其他`low-level`底层网络设置（如MTU），则此功能非常有用。

   - 创建`ingress`网络

     使用--ingress标志创建新的覆盖网络，以及要设置的自定义  选项。此示例将MTU设置为1200，将子网设置为10.11.0.0/16，并将网关设置为10.11.0.2。

     ```
     $ docker network create \
       --driver overlay \
       --ingress \
       --subnet=10.11.0.0/16 \
       --gateway=10.11.0.2 \
       --opt com.docker.network.driver.mtu=1200 \
       my-ingress
     ```
     注意：您可以对`ingress`网络重新命名，但您只能拥有一个`ingress`网络。

   - 删除`ingress`网络

     如果现有服务有发布端口，则需要先删除这些服务，然后才能删除`ingress`网络。

     ```
     $ docker network rm ingress
 
       WARNING! Before removing the routing-mesh   network, make sure all the nodes
       in your swarm run the same docker engine   version. Otherwise, removal may not
       be effective and functionality of newly created   ingress networks will be
       impaired.
       Are you sure you want to continue? [y/N]
     ```

- 自定义`docker_gwbridge`

  `docker_gwbridge`是一个虚拟网桥，将覆盖网络（包括`ingress`网络）连接到单个Docker守护程序的物理网络，它存在于Docker主机的内核中。

  ```
  $ ip addr | grep docker_gwbridge
    docker_gwbridge: <BROADCAST,MULTICAST,UP,LOWER_UP>   mtu 1500 qdisc noqueue state UP 
      inet 172.18.0.1/16 brd 172.18.255.255 scope   global docker_gwbridge
  ```
  
  1. Stop Docker service
     
     ```
     $ systemctl stop docker
     ```
  
  2. 删除`docker_gwbridge`网桥
  
     ```
     $ ip link set  docker_gwbridge down
     $ ip link del dev docker_gwbridge
     ```
  3. 启动Docker，但是不要初始化`swarm`或者加入任何`swarm`  服务网络
  
     ```
     $ systemctl start docker
     ```
  4. 使用`docker network create`命令，使用自定义设置手动  创建或重新创建`docker_gwbridge`桥。此示例使用子网  10.11.0.0/16。有关可自定义选项的完整列表，请参阅[Bridge  驱动程序选项]  (https://docs.docker.com/engine/reference/commandline/  network_create/#bridge-driver-options)。
     
     ```
     $ docker network create  \
       --subnet 10.11.0.0/16 \
       --opt    com.docker.network.bridge.name=docker_gwbridge \
       --opt com.docker.network.bridge.enable_icc=false  \
       --opt    com.docker.network.bridge.enable_ip_masquerade=true \
       docker_gwbridge
     ```
  5. 初始化或加入`swarm`服务集群。由`docker_gwbridge`网桥已经存在，初始化时Docker不再创建它。

#### 创建用于`swarm`服务的`overlay`网络

- 在`overlay`网络上，暴露服务端口号

  连接到同一覆盖网络的群集服务有效地将所有端口彼此暴露。对于可在服务外部访问的端口，必须使用`docker service create`或`docker service update`上的`-p`或`--publish`参数发布端口。

  ```
  $ docker service create 
  ```

  默认情况下，发布端口的`swarm`服务使用路由网格(`routing mesh`)来实现。如果连接到当您连接到任何swarm节点上的已发布端口（无论它是否正在运行给定服务）时，您将被透明地重定向到正在运行该服务的worker。

- `swram`服务区（`swarm service`）绕过网格路由（`routing mesh`）

  默认情况下，发布端口的`swarm`服务使用路由网格来实现负载均衡。 当您连接到任意一个`swarm`节点（工作节点和管理节点）上的已发布端口（无论该节点上是否运行了要访问的服务）时，您将被透明地路由到正在运行该服务的`worker`节点上。实际上，Docker充当您的群服务的负载均衡器（`load balancer`）。 默认情况下，使用`routing mesh`的服务以虚拟IP（VIP）模式运行。 即使在每个节点上运行的服务（通过`--mode global`）也使用路由网格。使用`routing mesh`时，无法保证哪个Docker节点响应客户端请求。要绕过路由网格，可以使用DNS循环（DNSRR）模式启动服务，方法是将`--endpoint-mode`标志设置为`dnsrr`。若使用`dnsrr`，需要在服务前运行自己的负载均衡器（常用的：有`nginx`、`HAproxy`）。通过DNS查询返回运行在`swarm`集群服务的所有节点的IP地址列表。
  
  >`routing mesh` 将外部请求路由到不同主机的容器，从而实现了外部网络对 `service` 的访问。

- 分离控制流量和数据流量
  
  默认情况下，与`swarm`管理相关的控制流量以及应用程序的数据流量都在同一网络上运行，尽管群集控制流量已加密。您可以将Docker配置为使用单独的网络接口来处理两种不同类型的流量。初始化或加入`swarm`时，每个节点（管理节点和工作节点）需要分别指定`--advertise-addr`和`--data-path-addr`。

#### 创建用于独立容器使用的`overlay`网络

- 将独立容器连接到覆盖网络

  在创建`ingress`网络时，若未指定`--attachable`（比如初始化`swarm`服务，或加入`swarm`时默认创建的`ingress`）意味着只有`swarm`服务可以使用它，独立运行的容器无法使用`ingress`。您可以将独立容器连接到使用--attachable标志创建的用户定义的覆盖网络。这使得在不同Docker守护程序上运行的独立容器能够进行通信，而无需在各个Docker守护程序主机上设置路由。


- 容器发现

  在大多数情况下，您应该连接到服务名称，该名称是负载平衡的，并由支持该服务的所有容器（“tasks”）处理。要获取支持该服务的所有任务的列表，使用`DNS lookup` 查找`tasks.<service-name>`


