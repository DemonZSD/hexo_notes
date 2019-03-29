---
title: gRPC教程—— gRPC 简单实现Server和Client
date: 2019-03-27 16:36:54
keywords: weshzhu, weshzhu blogs, gRPC, gRPC Python, python, gRPC client, gRPC server, gRPC tutorial
description: python实现简单 gRPC Server和Client
tags:
  - gRPC
categories:
  - gRPC
---

### 前言
> 在[上篇教程](http://www.weshzhu.com/2019/03/26/grpc-introduction/) 简述了 `RPC` 和 `gRPC` 的概念，初步了解了 `gRPC` 的工作原理，这篇文章将使用 Python 语言对 `gRPC` 进行简单的实现。可以加深对 `gRPC` 概念的理解。

本教程实验环境

 - OS: Centos7.4
 - Python: 2.7

### 安装grocio工具

假设已经安装了 `virtualenv` 工具，具体安装教程见 [ virtualenv 16.4.3 documentation](https://virtualenv.pypa.io/en/stable/installation/)。

首先，创建 python 独立运行环境：

```
$ mkdir grpc_tutorial 
$ cd grpc_tutorial
$ virtualenv venv
$ source venv/bin/activate
$ mkdir -p demo/client demo/server demo/protos demo/generate_src
$ touch requirements.txt
```

然后，安装编译工具： `grpcio` 和 `grpcio-tools`：

将如下内容添加到文本文件 requirements.txt 中，

```
grpcio
grpcio-tools
```

使用 pip 安装

```
pip install -r requirements.txt
```

完整的 gRPC service 包含三部分：
 
 - Proto File: 包含当前包的所有服务的定义。将用于生成 `gRPC` 服务器和客户端使用的`Stubs`。
 
 - gRPC Server: gRPC 服务，用于接收客户端发来的 request , 类似于HTTP Server
 
 - gRPC Client: gRPC 客户端，分布于各个主机中，用于访问远程 gRPC 服务器。从本质上讲，这使得 gRPC 调用就像在同一代码库本身中调用本机函数。


### 编写 Proto 文件

为 `gRPC` 服务创建一个 `proto` 文件：`digestor.proto`

```
syntax = 'proto3';

// You can ignore these for now
//option java_multiple_files = true;
//option java_package = "example-digestor.resource.grpc.digestor";
//option java_outer_classname = "DigestorProto";
//option objc_class_prefix = "DIGEST";

package digestor;

service Digestor{
    // 定义一个 gRPC 服务方法， 在此也可以定义多个方法
    // rpc DoSomething(ClassType1) returns (ClassType2) {};
    rpc GetDigestor(DigestMessage) returns (DigestedMessage) {};
}


message DigestMessage{
    string ToDigest = 1;
}

message DigestedMessage{
    string Digested = 1;
    bool WasDigest = 2;
}

```

下面对上述 `proto file`进行详解:  

该文件的第一行 `syntax = "proto3"` 声明了 `proto` 类型和方言。

以上被注释的代码是Java的包定义，我们也需要为java生成存根（因为gRPC提供了多语言实现）。最后一行声明了gRPC包的名称。

```
// You can ignore these for now
//option java_multiple_files = true;
//option java_package = "example-digestor.resource.grpc.digestor";
//option java_outer_classname = "DigestorProto";
//option objc_class_prefix = "DIGEST";
package digestor;
```


下述代码声明了名称为 `Digestor` 的 `gRPC` 服务，该服务提供了一个方法 `GetDigest` 用于接收 `DigestMessage` 类型的消息，返回 `DigestedMessage` 类型的消息。也可以声明多个服务方法，用于处理不同的业务逻辑。

对`GetDigest` 方法要使用的数据类型 `DigestMessage` 和 `DigestedMessage` 进行定义。其中 `DigestMessage` 数据结构包含了一个 `string` 类型的变量 `ToDigest`。 `DigestedMessage` 数据结构包含了 `string` 类型的变量 `Digested` 和 `bool` 类型的变量 `WasDigested` 。数字 `1` 和 `2` 表示了变量的顺序。


```
service Digestor{
    rpc GetDigest(DigestMessage) returns (DigestedMessage) {};
}
message DigestMessage{
 string ToDigest=1;
}
 
message DigestedMessage{
 string Digested=1;
 bool WasDigested=2;
}
```


### 生成 Stubs 

通过 `proto` 文件 `digestor.proto` 生成 `gRPC Stubs`

```
$ cd demo/protos
$ python -m grpc_tools.protoc --proto_path=. ./digestor.proto --grpc_python_out=../generate_src --python_out=../generate_src
```

该命令可以在目录 `generate_src` 生成两个文件：`digestor_pb2.py` 和 `digestor_pb2_grpc.py `。 后续编写 **服务端** 和 **客户端** 代码时，需要用到生成的 `Stubs`。

`--proto_path`： 指定要搜索 proto 文件的目录。可指定多个目录, 目录将按顺序搜索。如果没有给出，则默认当前工作目录。
`--python_out`: 生成的 python 源码。 在此例子中，生成的源码为 `digestor_pb2.py`
`--grpc_python_out`: 生成的 python 源码。 在此例子中，生成的源码为 `digestor_pb2_grpc.py`

具体 `grpc_tools.protoc` 参数，请使用 `python -m grpc_tools.protoc --help` 查看


### 编写 gRPC 服务端代码

创建一个 `digester_server.py` 文件：

```
#! /usr/bin/env python
# -*- coding:utf-8 -*-
# @Author: weshzhu
# @Date: 2019-03-27 14-29
# @FUNCTION: 
from concurrent.futures import ThreadPoolExecutor
import grpc
import time
import hashlib
from demo.generate_src import digestor_pb2
from demo.generate_src import digestor_pb2_grpc


class DigestorServicer(digestor_pb2_grpc.DigestorServicer):
    """
    gRPC server for Digestor Service
    digestor_pb2_grpc.DigestorServicer 类 根据 `digestor.proto` 文件声明的 `service Digestor`生成
    """
    def __init__(self, *args, **kwargs):
        self.server_port = 5001

    def GetDigestor(self, request, context):
        """
        重写digestor_pb2_grpc.DigestorServicer 方法 GetDigestor
        :param request: 接收 请求参数
        :param context: 上下文
        :return: DigestedMessage类型
        """
        tobeDigested = request.ToDigest
        hasher = hashlib.sha256()
        hasher.update(tobeDigested.encode())
        digested = hasher.hexdigest()
        print digested
        # result 即为 digestor.proto 文件声明的DigestedMessage 类型
        # 保证变量名称(Digested, WasDigest)与 DigestedMessage 声明的一致
        result = {'Digested': digested, 'WasDigest': True}
        return digestor_pb2.DigestedMessage(**result)

    def start_server(self):
        """
        start gRPC server and receive the clients witch will connect to it
        :return:
        """
        # 实例化 server 对象，接收指定大小的线程池
        digestor_server = grpc.server(ThreadPoolExecutor(max_workers=5))

        # 将服务添加到 server 对象中
        digestor_pb2_grpc.add_DigestorServicer_to_server(DigestorServicer(), digestor_server)

        # 绑定 server 到 端口号
        digestor_server.add_insecure_port('[::]:{port}'.format(port=self.server_port))
        # start the server
        digestor_server.start()
        print ('Digestor Server running ...')
        try:
            # need an infinite loop since the above
            # code is non blocking, and if I don't do this
            # the program will exit
            while True:
                time.sleep(60 * 60 * 60)
        except KeyboardInterrupt:
            digestor_server.stop(0)
            print('Digestor Server Stopped ...')


if __name__ == '__main__':
    curr_server = DigestorServicer()
    curr_server.start_server()


```

执行 `digester_server.py` 脚本，启动 gRPC 服务



### 编写 gRPC 客户端代码

在 demo/client中编写客户端脚本 `digestor_client.py` ，内容如下：

```
#! /usr/bin/env python
# -*- coding:utf-8 -*-
# @Author: zsd
# @Email: zsd498537806@gmail.com
# @Date: 2019-03-27 15-17
# @FUNCTION: 
import grpc
from demo.generate_src import digestor_pb2_grpc
from demo.generate_src import digestor_pb2


class DigestorClient(object):
    def __init__(self):
        self.server_host = 'localhost'
        self.server_port = 5001

        # 初始化一个 channel 用于建立client 和 server 之间的通信管道
        self.channel = grpc.insecure_channel(
            '{ip}:{port}'.format(ip=self.server_host, port=self.server_port))

        # 绑定 client 到 gRPC server 的 channel
        self.stub = digestor_pb2_grpc.DigestorStub(self.channel)

    def get_digest(self, message):
        # 实例化 DigestMessage 对象
        to_digest_message = digestor_pb2.DigestMessage(ToDigest=message)
        return self.stub.GetDigestor(to_digest_message)

```

该客户端在初始化函数中，建立了从 客户端 到 服务端 的连接， 直接执行 `get_digest` 方法即可调用 `gRPC` 服务端的方法 `GetDigestor`。


### 测试

在不同的 Terminal 分别执行执行 `digestor_server` 和 `digestor_client`

server 端
```
$ python

>>> from demo.server import digestor_server
>>> Digestor_server = digestor_server.DigestorServicer()
>>> digestor_server = digestor_server.DigestorServicer()
>>> digestor_server.start_server()
Digestor Server running ...
532eaabd9574880dbf76b9b8cc00832c20a6ec113d682299550d7a6e0f345e25
```

client端

```
$ python
>>> from demo.client.digestor_client import DigestorClient
>>> digestor_client = DigestorClient()
>>> digestor_client.get_digest('Test')
Digested: "532eaabd9574880dbf76b9b8cc00832c20a6ec113d682299550d7a6e0f345e25"
WasDigest: true
```

可以看到，服务端接收客户端的请求数据，并将处理结果返回给客户端。对于客户端来说，仅仅调用本地的 `get_digest` 方法。

本文涉及的源码请访问 [github-grpc_tutorial](https://github.com/DemonZSD/grpc_tutorial)

### 总结

使用 `Simple gRPC` 有以下不足：
 - 在数据包过大时，会对 client 和 server 端造成压力。
 - 服务端接收数据包时，在数据包完全接收完成后，才能响应给客户端，并无法一边接收客户端的请求数据，一边响应给客户端。

后续章节将继续介绍 [基于 Stream 的 gRPC](https://segmentfault.com/a/1190000016503114)。



### 参考链接

 - [Writing your first gRPC service in Python](https://technokeeda.com/programming/grpc-python-tutorial/)
 - [官方文档](https://grpc.io/docs/guides/)


