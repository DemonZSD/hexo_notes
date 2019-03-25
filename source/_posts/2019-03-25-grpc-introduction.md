---
title: gRPC教程——gRPC简介
date: 2019-03-25 18:00:58
tags:
  - gRPC
categories:
  - gRPC
---


## RPC

`RPC` 远程过程调用（Remote Procedure Call，缩写为 RPC）是一个计算机通信协议，该协议允许一台主机上的应用程序调用另一台主机上的应用程序中的方法。 远程过程调用总是由客户端对服务器发出一个执行若干过程请求，并用客户端提供的参数。执行结果将返回给客户端。

`RPC`只是描绘了 `Client` 与 `Server` 之间的点对点调用流程，还需要考虑服务的高可用、负载均衡等问题。在开发 `RPC` 框架时，还应当考虑到服务的发现与注册，负载均衡，服务高可用等功能。目前市场上比较优秀的 `RPC` 框架有： `Thrift` （Facebook捐赠给Apache公司）、 `gRPC`（Google公司）， 国内优秀的 `RPC`框架有：`Dubbo` (Alibaba), `Motan` (sina) 。但是各个框架侧重点并不同，比如 `gRPC` 侧重于跨语言特性，适合于为不同语言提供通用远程服务。 `Dubbo` 侧重于高性能的远程调用以及服务发现和治理功能，适用于大型服务的微服务化拆分以及管理，对于特定语言（Java）的项目可以十分友好的透明化接入。但缺点是语言耦合度较高，跨语言支持难度较大。

下面着重对 `RPC` 代表 `gRPC` 进行介绍：

## gRPC
`gRPC` 是一种使用`protocol buffer`接口定义语言（`Interface Definition Language, IDL`）定义服务的方法。

在 gRPC 里，客户端应用可以像调用本地对象一样直接调用另一台不同的机器上服务端应用的方法，能够更容易地创建分布式应用和服务。与许多 `RPC` 系统类似，`gRPC` 也是基于以下理念：定义一个服务(`service`)，指定其能够被远程调用的方法（包含参数和返回类型）。在服务端实现这个接口，并运行一个 `gRPC` 服务器来处理客户端调用。在客户端拥有一个存根(`Stub`)能够像服务端一样的方法。

`gRPC` 由三部分组成：

 - `gRPC Stub`, 定义: 这是一个包含所有原型定义的配置文件，它还包含要提供的所有远程过程调用的声明。通过该配置文件，生成服务端和客户端通信的接口。
 - `gRPC server`, 定义：这是将为远程过程调用提供服务的实际服务器。类似于HTTP服务器
 - `gRPC client`, 定义：使用 `gRPC` 客户端访问远程 `gRPC` 服务器。这就是使用 `gRPC` 简单的原因。调用 `gRPC` 方法就像调用另一个函数一样。


![](/images/2019-03-25_180320.png)



### Protocol Buffer

 `gRPC` 不使用 `JSON` 或 `XML` （非常庞大），而是使用Google `ProtocolBuffers` 发送数据。这可以使通过网络传输的消息的大小平均减少 30％ 以上，并且在某些情况下，消息大小可以小于原始消息的 20％。这直接转换为您的系统使用比以前少 30％-80％ 的带宽。

默认情况下，`gRPC`使用协议缓冲区（`Protocol Buffers`），这是Google成熟的开放源码机制，用于序列化结构化数据（尽管它可以与其他数据格式（如JSON）一起使用）。

该协议缓冲区可以理解成**客户端**和**服务器**约定好的通信数据结构。

使用`Protocol Buffers`，首选定义一个数据结构，后续用于序列化为`proto`类型文件——以`.proto`为后缀的文本文件。`Protocol Buffer`数据被结构化为 `messages` 。每个`message`包含一系列 `key-value`对，被称为域（field）：

```
message Person {
    string name = 1;
    int32 id = 2;
    bool has_ponycopter = 3;
}

```

然后，一旦定义了`Protocol Buffer`数据结构，可以使用`protocol buffer`编译器`protoc` 将定义的`proto file`编译成各个语言的数据访问类。这些方法为每个字段（比如 `name()`、`set_name()`）提供访问器，对整个数据结构进行序列化或者解析为原始字节，或者相反操作。比如选择`C++`语言，对上述举例经过编译后，生成一个`Person`类，可以使用该类填充、序列化和检索`Person`协议缓冲区消息。

正如您将在我们的示例中看到的那样，您在普通`proto`文件中定义`grpc`服务，并将 `rpc` 方法参数和返回类型指定为协议缓冲消息：

```
syntax=''

// 定义 greeter service
service Greeter {
  // 发送 greeter
  rpc SayHello (HelloRequest) returns (HelloReply) {}
}

// (请求消息结构)  request message
message HelloRequest {
  string name = 1;
}

// (响应消息结构) response  message
message HelloReply {
  string message = 1;
}
```




`gRPC`针对不同的语言，通过插件`protoc`通过`.proto`文件生成对应语言的代码。

**`Protocol buffer` 版本**

通常，虽然您可以使用`proto2`（当前的默认协议缓冲版本），但我们建议您将 `proto3` 与 `gRPC` 一起使用，因为它允许您使用全系列的 `gRPC` 支持的语言，以及避免与 `proto2` 客户端通信时的兼容性问题`proto3`服务器，反之亦然

## RPC vs RESTful

1. RPC 可以基于TCP、UDP或者HTTP进行消息传输，而RESTful只能基于HTTP协议进行消息传输.
2. RPC 客户端和服务端紧耦合，客户端需要通过参数以及过程名称对服务端的**方法**和**过程**进行调用。而RESTful操作的对象是**资源**，RESTful对资源进行操作：增加、查找、删除等，主要是CRUD。
3. 操作的对象不一样。 `RPC` 操作的是方法和过程，它要操作的是方法对象。 `RESTful` 操作的是资源(resource)，而不是方法。
4. RPC实现长连接：RPC over TCP （性能优越，适用于高并发）。RESTful实现长连接，必须通过HTTP协议的keep-alive实现长连接，但是遇到一个问题是 request-response模式是阻塞的。


## 参考：
 - [gRPC官方文档](https://grpc.io/docs/)
 - [gRPC 官方文档中文版](https://doc.oschina.net/grpc)
 - [MicroServices on gRPC](https://technokeeda.com/programming/microservices-on-grpc/)
