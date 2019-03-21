---
title: docker存储原理——介绍
date: 2019-03-21 08:46:02
tags:
  - docker
  - storage
categories:
  - docker
---

Docker数据存储
---

>在Docker中，有两种方式对数据进行存储：`docker volume`(存储卷) 和 `docker storage driver`（存储驱动），本文主要介绍`docker storage driver`存储驱动。

准备工作：

OS: centos 7.4 (kernel version > 3.10.514 )

Docker: docker-ce 18.03.1 ( [docker-ce安装教程](http://www.weshzhu.com/2019/01/03/binary-install-docker-ce-on-centos7/))


#### Docker 数据存储

在了解`Docker storage driver`之前，我们先了解一下Docker如何存储容器数据和镜像数据。在Docker中数据分为镜像数据和容器数据，容器数据又包含容器可写层和`docker volume`存储。镜像数据是一种静态数据，存储了提供容器运行的程序、配置文件等。容器数据可以理解为动态 + 静态的数据（阅读本文后，可能有比较直观的理解），供容器运行使用。

![](./container-layers.jpg)

如上图所示，容器层（high-level）是非常小的层，允许程序对该层读写操作；镜像层(low-level)包含了大部分的数据，并且是只读的。在镜像未启动时均是以镜像层存储在host主机上（存储路径：`/var/lib/docker/<storage-driver>/`）。以该镜像为基础，通过`docker run`启动一个或多个容器后，针对每个启动的容器会增加一层——可读写层（容器层）。

 - 镜像层
   Docker镜像是由一系列的层（`layer`）构成，镜像的每个`layer`对应这个Dockerfile中的每条指令
   
   ```
   FROM ubuntu:15.04
   COPY . /app
   RUN mkdir -p /app/conf/
   CMD python /app/app.py
   ```

   通过`docker build -t `命令构建镜像：
  
   ```
   $ docker build -t my-ubuntu:test -f Dockerfile .
     
     Sending build context to Docker daemon  3.584kB
     Step 1/4 : FROM ubuntu:15.04
     ---> d1b55fd07600
     Step 2/4 : COPY . /app
     ---> 6e3fe23e82f3
     Step 3/4 : RUN mkdir -p /app/conf/
     ---> Running in 3a9b550d957b
     Removing intermediate container 3a9b550d957b
     ---> 038a1543c273
     Step 4/4 : CMD python /app/app.py
     ---> Running in 9b56a922b87f
     Removing intermediate container 9b56a922b87f
     ---> 58866642a2af
     Successfully built 58866642a2af
     Successfully tagged my-ubuntu:test
   ```
   查看镜像是否存在：

   ```
   $ docker images
     REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
     my-ubuntu           test                58866642a2af        5 minutes ago       131MB
     ubuntu              15.04               d1b55fd07600        2 years ago         131MB
   ```

   查看镜像构建详情：

   ```
   $ docker history 58866642a2af
     
     IMAGE               CREATED             CREATED BY                                      SIZE                COMMENT
   58866642a2af        49 seconds ago      /bin/sh -c #(nop)     CMD ["/bin/sh" "-c" "pyth…   0B                  
   038a1543c273        51 seconds ago      /bin/sh -c mkdir -p    /app/conf/                  0B                  
   6e3fe23e82f3        53 seconds ago      /bin/sh -c #(nop)    COPY dir:3f69c750361eacc36…   101B                
   d1b55fd07600        2 years ago         /bin/sh -c #(nop)    CMD ["/bin/bash"]             0B                  
   <missing>           2 years ago         /bin/sh -c sed -i    's/^#\s*\(deb.*universe\)$…   1.88kB              
   <missing>           2 years ago         /bin/sh -c echo    '#!/bin/sh' > /usr/sbin/poli…   701B                
   <missing>           2 years ago         /bin/sh -c #(nop)    ADD file:3f4708cf445dc1b53…   131MB
   ```

   我们看到`58866642a2af` `038a1543c273` `6e3fe23e82f3` 是刚刚创建的层，对应着Dockerfile文件中的每条指令。`d1b55fd07600`是基础镜像的层，而`missing`则是以往他人在其他主机上构建的层，可以忽视。
   
   当您使用`docker pull`从`registry`（镜像仓库）中下拉镜像时，每个镜像层都会单独下拉，并存储在Docker所在host的文件系统中，Linux主机上通常是`/var/lib/docker`。您可以在此示例中看到这些镜像层被拉出：

   ```
   $ docker pull ubuntu:15.04
     15.04: Pulling from library/ubuntu
     9502adfba7f1: Pull complete 
     4332ffb06e4b: Pull complete 
     2f937cc07b5f: Pull complete 
     a3ed95caeb02: Pull complete 
     Digest:      sha256:2fb27e433b3ecccea2a14e794875b086711f5d49953ef173d8a03e8707f1510   f
     Status: Downloaded newer image for ubuntu:15.04
   ```

   下拉的镜像层存储在`/var/lib/docker/<storage-driver>/`目录中，本例使用的存储驱动是`overlay2`，Docker version > 1.10的版本，每层的目录名称与图层ID不对应。

   ```
   $ ls -l /var/lib/docker/overlay2/
     drwx------. 4 root root     55 Jan 12 10:19    1e72c036bc24730abff4e3eed803c5d9c3ba67d61cc4dc0da62e880a5b23d7a9
     drwx------. 4 root root     55 Jan 12 10:14      1fd044fc33c05db1b7fddf37992788befb6e5bd5dfa6ab0f4a72f281d68b5d8c
     drwx------. 4 root root     55 Jan 12 10:20      2205c9e9efbd435b968dba2beb2390e2ddc49b5cd4efedae5a6a08a5a6d2634b
     drwx------. 4 root root     55 Jan 12 10:18      25e720a5f2d95330556d5f99268217045654002d0c47cc77342342c2ba4af226
     drwx------. 4 root root     55 Jan 12 10:18      277b95e43bbeb2f13ec6b7dd636b774d5e9ea56bad1414c6f1fe6c3178970172
   ```

 - 容器层
   
   容器和镜像之间的主要区别在于顶部可写层，所有对容器的操作：对文件的修改和添加，都是在可写层进行操作的（写时复制CoW策略），`low-level`的镜像层不会更改。若将启动的容器进行删除，那么所有的操作将不被保留。
   若以同一个镜像启动多个容器，则底层的镜像层是公共的层，为所有容器共用，对应每个容器有各自的可写层。对容器文件的修改保存均在容器层。对于不同的容器，容器层的数据不可共享，若想共享数据，可采用`docker volume`存储。针对该存储方案，由于内容较多，将单独作为一个章节进行介绍。
   ![](./sharing-layers.jpg)
   

   当启动一个容器，启动容器时，会在容器层的顶部添加一个体积比较小的可写容器层。容器对文件系统所做的任何更改都存储在此处。Docker的host主机文件系统中对应的容器层存储路径`/var/lib/docker/containers`

   ```
   $ ls -l /var/lib/docker/containers
   drwx------. 4 root root 165 Jan 12 10:25    025030ca0a6d5383346d4cf5471108e5cfad22d74c3411a606baf3a902c99a28
   drwx------. 4 root root 165 Jan 12 10:26    0a19a162a971fb9364907e9d2e8d39baf47d588d9e18fc6c47f16f4bca56d569
   drwx------. 4 root root 237 Jan 12 10:25    1058890a8138eafaf5b7d84d3d708c0169fcba024e27697c01952465d0fdb78a
   drwx------. 4 root root 165 Jan 12 10:25    152da522924bf4ebebf960c3f93897f7d582f53ba98239922bf56baec7876eea
   drwx------. 4 root root 165 Jan 12 10:25    1ee87d5bc8e9a58d137cbe3f98e5fd85c7ac360e03de77d69e5fa27d315fb509   
   ```

#### 写时复制（CoW）策略

写时复制（CoW）是一种共享和复制文件的策略。如果要读取或要修改的文件或目录存在于镜像中的`low-level`层（镜像层），若对该文件进行读访问，则它只需使用镜像层中的现有文件。 如果第一次添加或修改此文件时（比如：构建镜像或运行容器时），文件将被复制到该容器层（可写层）并进行修改。容器未更改的任何文件都不会复制到此可写层，意味着可写层尽可能小。这种策略保证了容器文件系统以及I/O操作的最小化。

对于aufs，overlay和overlay2存储驱动，写时复制操作遵循以下顺序：

1. 在镜像层中搜索要修改的文件。该过程从最新层开始，一次一层地向下移动到基础镜像层。找到结果后，会将它们复制到缓存中以加快将来的操作。
2. `copy_up`对找到的文件的第一个副本执行操作，以将文件复制到容器的可写层。
3. 对此文件副本进行任何修改，将保存在容器层，后续的操作将值针对该副本进行，对于镜像层的该文件对于容器来说，是不可见的。







