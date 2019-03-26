---
title: Fabric2.4 Tutorial
date: 2019-03-26 09:26:59
tags:
  - Fabric
  - Python
categories:
  - 运维
  - Fabric
---

## Network

### SSH连接网关
#### 背景

出于安全考虑，服务器经常会加一道防火墙，从而阻止从互联网直接访问服务器。如果需要连接防火墙内部的网络，通常是通过中间主机（被称为“跳转机”、“堡垒机”、“网关或代理”、“弹跳”）

网关需要与网关系统建立初始/外部SSH连接，然后使用该连接作为到最终/内部主机的“真实”连接的传输。

则可以通过 `ssh gatewayhost`去真正连接 `ssh internalhost `，这适用于长时间运行的会话。但在频繁进行时，会成为负担。


Fabric中有两种网关解决方案，可以反映OpenSSH客户端的功能：`ProxyJump`（更容易，更少开销，可以嵌套）; `ProxyCommand` （更多开销，不能嵌套，有时更灵活）。两者都支持通常的配置源：Fabric自己的配置框架，SSH配置文件或运行时参数

##### `ProxyJump`

这种类型的网关使用SSH协议的direct-tcpip通道类型 - 一种轻量级方法，用于请求网关的sshd开启一个到远程服务器的连接。

`paramiko.channel.Channel` 实例实现了Python的 `socket` API，因此可用于代替几乎任何Python代码的实际操作系统套接字。

`ProxyJump`类型的网关，使用简单：

```
from fabric import Connection

c = Connection('internalhost', gateway=Connection('gatewayhost'))
```

该 `gateway` 连接(`Connection('gatewayhost')`)，需要配置 gatewayhost的登录用户名，端口号等等。


##### `ProxyCommand`

传统的OpenSSH命令行客户端长期提供了一个`ProxyCommand`指令（请参阅[man ssh_config](http://man.openbsd.org/ssh_config)），该指令通过任意本地子进程管理内部连接的输入和输出。

与 `ProxyJump`类型的网关相比，这种方式增加了开销（额外的子进程），并且无法轻松嵌套。在数据传输中，它允许使用`SOCKS`代理或者自定义过滤等高级功能，相对来说更加灵活。

`ProxyCommand`子进程通常是另一个ssh命令，例如`ssh -W ％h：％p gatewayhost`;或者（在缺少`-W`选项的SSH版本上）广泛使用的`netcat`，通过`ssh gatewayhost nc ％h％p`。

Fabric支持ProxyCommand接受gatewaykwarg中的命令字符串对象 Connection; 这用于paramiko.proxy.ProxyCommand在连接时填充 对象。



#### 其他问题

如果您不确定使用哪两种方法：使用`ProxyJump`方式。它性能更好，在本地系统上使用更少的资源，并且具有更易于使用的API。

> **警告**
> 
> 同时请求两种类型的网关到相同的主机（即，以`Connection`作为`gateway`的`kwarg`或`config`参数，并且加载包含配置文件`ProxyCommand`）将导致异常。

---

## Configuration

### 基础

Fabric配置系统，主要依赖于Invoke功能（`invoke.config.Config`），严格来说是`invoke.config.Config`的子类 `fabric.config.Config`。

俩类的主要区别：
- 配置文件命名全部以fabric.\*，而不是原来的invoke.\*，  比如：`/etc/fabric.yml` 取代 `/etc/invoke.yml`, `~/.fabric.py` 取代 `~/.invoke.py`
- Fabric在`invoke.config.Config`基础上，新增了其他的配置属性，比如：SSH默认连接端口为22
- Fabric有加载SSH配置文件的特殊机制。并将根据每个`Connection`，自动创建或更新配置子树。并使用该特定主机的加载ssh配置。
- Fabric提供一个Framework或者进行管理per-host或者per-host-connection配置。
  - 该功能，将会补充所述的ssh配置加载的功能。我们预计大多数用户倾向于通过SSH配置文件来进行配置。




### 配置默认值

#### 重写Invoke-level

- `run.replace_env: True`，在远程服务器执行的shell命令，将不会继承当前线程的环境变量。
  
  处于安全考虑：默认情况下远程泄漏本地环境数据是不推荐的。

#### 扩展Invoke-level

`runners.remote`:在Invoke中，`runner`拥有单独键：`local`(mapping to `Local`)，Fabric添加新的键`remote`（mapping to `Remote`）

#### Fabric自定义默认值

> **注意**
> 
> 大部分所有的设置（settings）也适用于`Connection`


> **警告**
> 大部分的设置也可以通过ssh_config_files进行配置，这些值优先于通过核心配置进行配置的值，

- `connect_kwargs`:

  关键字参数，这是许多与ssh相关的选项的主要配置向量，例如选择私钥、切换ssh代理的转发等。默认值：`{}`。

- `forward_agent`:

  是否尝试将本地ssh身份验证代理转发到远程端。默认： `False`

- `gateway`:

  用作 `Connection` 对象的 `gateway` 属性的默认值，默认：`None`

- `load_ssh_configs`:

  是否自动搜索SSH配置文件，当值为`False`，不自动加载配置文件。默认：`True`

- `port`:

  TCP端口号，用于`Connection`对象的连接，默认:22

- `inline_ssh_env`:

  Boolean用作`Connection`的`inline-ssh-env`参数值的全局默认值；有关详细信息，请参阅其文档。默认值：false。

- `ssh_config_path`:
  
  运行时（Runtime）SSH配置路径，默认：None

- `timeouts`:

  - `connection`：连接超时，以秒为单位；默认：`None`，表示永远没有`timeout/block`。

- `user`:
  
  指定通过ssh连接的用户名，默认值使用本地主机的用户名


### 加载并使用ssh_config文件

#### 加载哪些文件

**Fabric** 使用 **Paramiko** 的`SSH config`文件，加载并解析 `ssh_config`格式的文件

 - 已经被解析的 `SSHConfig` 对象，将会通过 `ssh_config` 关键字参数传给 `Config.__init__`。如果给定该值，则不再加载其他任何配置文件。
 - 运行时文件路径，通过`configuration `中的`ssh_config_path`进行设置，该路径将被`SSHConfig`对象加载。
   
   - 同 `fab` CLI 命令中的 `--ssh-config`

 - 如果 `Config.__init__` 没有运行时配置（包括对象或者路径），其会自动按顺序去搜索并加载 `~/.ssh/config and/`或 `/etc/ssh/ssh_config`
 - 如果上述都没有产生SSH配置数据，则空 `SSHConfig` 是最终结果

 - 无论对象是如何生成的，它都以 `Config.base_ssh_config` 形式公开。

##### Connection使用ssh_config文件

`Connection`对象将其配置的SSH数据（通过 `lookup` 获得）的每个主机“views”公开为`Connection.ssh_config`。 `Connection` 本身引用这些值，如以下小节所述，通常作为相应配置键或参数的简单默认值(例如：`port`, `forward_agent`)


除非另有说明，否则这些值会覆盖相同键的常规配置值，但可能会被 `Connection.__ init__` 参数覆盖。

比如：`~/.fabric.yaml`

```
user: foo
```

如果没有任何其他配置，`Connection（'myhost'）`将作为 `foo` 用户连接。

如果我们还有其他配置：`~/.ssh/config`

```
Host *
    User bar
```
`Connection（'myhost'）`将作为 `bar` 用户连接。

可见，`SSH config` 优先于`Fabric config`

然而，`Connection（'myhost', user='biz'）`，将用`biz`用户进行连接。

> **注意**
> 
> 以下部分使用`ssh_config`键的大写版本以便更轻松地与`man ssh_config`进行关联，但实际的`SSHConfig`数据结构规范化为小写键，因为SSH配置文件在技术上不区分大小写。


##### Connection参数

- `Hostname` ：替换 `host` 的原始值（保留为`.original_host`。）
- `Port`：提供 `port`  config 选项/参数的默认值。
- `User`：提供 `user` config 选项/参数的默认值。
- `ConnectTimeout` ：设置`timeouts.connect` config 选项/超时参数的默认值。


##### 代理(Proxying)

- `ProxyCommand` : 为`gateway`提供默认字符串值
- `ProxyJump` : 为`gateway`提供默认`Connection`对象
  - 嵌套式`ProxyJump`，即`user1@hop1.host，user2@hop2.host，...`，将导致一系列适当的嵌套`gateway`值 - 就好像用户手动指定了`Connecton(...，gateway) = Connection('user1@hop1.host'，gateway = Connection('user2@hop2.host'，gateway = ...)))`。

> **注意**
> 
> 如果为给定主机指定了两者，则`ProxyJump`将覆盖`ProxyCommand`。这与OpenSSH略有不同，OpenSSH指令的加载顺序决定了哪一个获胜。我们这样做（将配置视为字典结构）需要额外的工作。

##### 认证（Authentication）

- `ForwardAgent`: 控制`forward_agent`参数行为
- `IdentityFile`: 追加 `connect_kwargs`字段 `key_filename`，类似于 `--identity`

#### 禁用`ssh_config`加载

需要更严格控制其环境配置方式的用户可能希望禁用系统/用户级SSH配置文件的自动加载；这可以防止难以预料的错误，例如新用户的 `~/.ssh/config` 覆盖在常规配置层次结构中设置的值。

为此，只需将顶级配置选项 `load_ssh_configs` 设置为`False`即可。

> **注意**
> 更改此设置不会禁用运行时级别（`runtime-level`）配置文件的加载，如果用户明确指定加载哪个文件，我们则认为他们知道他们要干什么。


---

## connection

```
class fabric.connection.Connection(host, user=None, port=None, config=None, gateway=None, forward_agent=None, connect_timeout=None, connect_kwargs=None, inline_ssh_env=None)¶
```
用于与ssh守护进程的连接，包含shell命令和文件传输。

### 基础

该类继承自`Invoke.context`，在该`context`中，可以进行命令、任务（task）操作。该类封装了Paramiko `SSHClient`实例，通过该类生成的`sshclient`和`channel`实例执行的高级操作。

> **注意**
> 
> 特定于SSH的选项——例如指定密钥（private key）和密码口令（passphrases）、timeouts、禁用SSH代理等，可通过构造函数的`connect_kwargs`参数指定，由paramiko直接处理。
> 
> 
>     c = connection(host='localhost',user='root', connect_kwargs={'passwrd':'123456'}




### 生命周期

`Connection`有`create, connect/open, do work, disconnect/close`生命周期。

- `Instantiation `持久影响对象连接参数。但并不真正建立连接。
  - 可选的构造方式：[upgrading piecemeal from Fabric 1](http://www.fabfile.org/upgrading.html#from-v1) `from_v1(env)`
- `run`、`get` 等方法会自动触发`connection`的`open`，用户也可手动执行`open`
- `Connection`无需手动关闭。大部分情况下连接的关闭操作交给Paramiko的**垃圾回收钩子**或者python自带的关闭序列。当然也有特殊情况（当退出时，session挂起），此时需要手动进行关闭(close)。

  这可以通过手动调用`Close`或借助`with`用作ContextManager来完成：
  
  ```
  with Connection('host') as c:
    c.run('command')
    c.put('file')
  ```

> Note
> 
> 该类将`invoke.context.Context.run`方法重新绑定到`local`方法，远程命令和本地命令均可执行。

### Configuration

大部分的`Connection`参数，遵循[` Invoke-style configuration`](http://docs.fabfile.org/en/2.4/concepts/configuration.html)和[`SSH Config`](http://docs.fabfile.org/en/2.4/concepts/configuration.html#connection-ssh-config)。例如连接到远程机器` admin@myhost`，可以使用下述方法进行连接：
- 使用`build-in`配置机制，比如` /etc/fabric.yml, ~/.fabric.json`，`user: admin` ( 或`{"user": "admin"}`)。这样，`Connection('myhost')`就可以通过用户为`admin`进行连接。
- 在任何适用的`Host`开头（`Host myhost`、`Host *`等）中隐式使用包含`User admin`的SSH Config配置文件。`Connection('myhost')` 将默认使用用户名为`admin`的用户进行连接。
- 利用主机参数简写，例如`Connection('admin@myhost')`
- 显示指定连接参数: `Connection('myhost', user='admin')`

```
__init__(host, user=None, port=None, config=None, gateway=None, forward_agent=None, connect_timeout=None, connect_kwargs=None, inline_ssh_env=None)
```
创建服务器连接对象。

#### 构建函数参数说明
- **`host(str)`**
  连接服务器的主机名或者IP地址，也可以是主机IP地址，端口号，用户名组合的简写形式：
  `user@host`, `host:port`, 或` user@host:port`
  > 注意
  >
  > 如果`host`与SSH Config配置文件中`Host`项相匹配，并且`Host`项包含`Hostname`属性，则`Connection`对象认为host与Hostname值相等。
  > 
  > 在所有情况下，主机的原始值都会保留为原始主机属性。
  > s
  > 给定SSH config文件内容如下：
  >
  >      Host myalias
  >          Hostname realhostname
  > 使用 `Connection(host='myalias')`调用，将返回一个对象：`host`值为`realhostname`，`original_host`值为`myalias`

- **`user(str)`**
  远程服务器登录用户名，默认值为`config.user`
- **`port(int)`**
  远程服务器的ssh端口号，默认值为`config.port`
- **`config(object)`**
  配置对象，该对象类型为`Config`或`invoke.config.Config`(类型转换为`Config`)

- **`gateway(object)`**
  用作此连接的代理或网关的对象。
  该参数可接受值：
   - 另一个`Connection`对象(`ProxyJump`类型网关)
   - shell命令字符串（` ProxyCommand`类型网关）
  默认值为：`None`，

- **`forward_agent(boolean)`**
  是否开启SSH代理转发，默认值为:`config.forward_agent`

- **`connect_timeout(int)`**
  连接超时时间（秒）

#### 类属性

- **`connect_kwargs(dict)`**

   `connect_kwargs`中的键值对将会被`SSHClient.connect`逐个解析。例如：
   ```
   c = Connection(
       host="hostname",
       user="admin",
       connect_kwargs={
           "key_filename": "/home/myuser/.ssh/private.key",config.connect_kwargs
       },
   )
   ```
  **默认值：`config.connect_kwargs.`**
- **`inline_ssh_env(boolean)`**

  是否将“内置”环境变量作为前缀发送到命令字符串前面（`export VARNAME=value && mycommand here`），而不是通过`SSH` 协议提交该命令。如果远程服务器具有受限的`acceptenv`设置，则需要执行此操作。

  **默认值：` False`**




#### Raise


#### 方法

- `close()`:
  
  关闭与远程服务器的SSH连接，如果连接已完毕，则该方法什么也不做。

- `forward_local()`:
  
  打开一个通道（tunnel）建立`local_port `到服务器环境的连接。

  例如，假设您想连接到一个远程 PostgreSQL 数据库，该数据库被锁定，只能通过运行它的操作系统访问。您可以通过ssh访问此服务器，因此可以临时使本地系统上的端口5432与服务器上的端口5432类似：
  ```
  import psycopg2
  from fabric import Connection

  with Connection('my-db-server').forward_local(5432):
    db = psycopg2.connect(
        # 通过本地端口5432区连接数据库，通过本地端口5432的数据会转发到
        # `my-db-server`服务器，然后在`my-db-server`服务器上真正的通过
        # 端口号5432去连接数据库
        host='localhost', port=5432, database='mydb'
        # 我们为什么用 localhost 而不是 IP 地址或者主机名呢？其实这个取决于我
        # 们之前是如何限制 PostgreSQL 只有本机才能访问。如果只允许 lookback 接口访问
        # 的话，那么自然就只有 localhost 或者 IP 为 127.0.0.1 才能访问了，而# 不能用真实 IP 或者主机名。
    )
    # Do things with 'db' here
  ```

  该方法类似于OpenSSH命令中的`ssh -L `

  - 参数：
    
    `local_port (int) `:

    本地监听端口号

    `remote_port (int) `:

    远程服务器端口号，默认同`local_port`

    `local_host (str) `:

    要侦听的本地主机名/接口。默认值：localhost

    `remote_host (str) `:

    为转发的远程端口提供服务的远程主机名。默认值：localhost（即`Connection`所连接的主机）


  - 返回值：无
    
    此方法仅用作影响本地操作系统状态的上下文管理器。
  

- `forward_remote()`: 
  
  该方法对应SSH的 forward remote，`$ ssh -R <local port>:<remote host>:<remote port> <SSH hostname>`
  - 参数
    - `remote_port（int）` - 要监听的远程端口号。

    - `local_port（int）`- 本地端口号。默认值与`remote_port`相同。

    - `local_host （str）`–转发连接所使用的本地主机名/接口。默认值：localhost。

    - `remote_host （str）`–转发连接时要监听的远程接口地址。默认值：127.0.0.1（即仅侦听`localhost`）。


  

- *classmethod* `from_v1(env, **kwargs)`:

  使用Fabric 1版本的 `env`参数值。
  
  `env`: Fabric 1版本的 `env`变量

  `kwargs`: 除了env之外，所有的关键字参数都是直接传递到主构造函数中。

  > 注意
  >
  > `kwargs`中的参数会覆盖`env`相同的参数值。

- `get(*args, **kwargs)`:
  
  将远程文件下载到本地文件系统或`file-like`对象

- `is_connected()`：
  
  连接是否open

- `local(*args, **kwargs)`:
  
  在本地机器上执行shell命令

- `open()`:
  
  启动与此对象绑定到的主机/端口的ssh连接。



- `open_gateway()`:

  从gateway中获取`socket-like `对象。

  返回值：

  如果`gateway`是一个`Connection`，则返回` paramiko.channel.Channel`；如果`gateway`是一个字符串，则返回[`ProxyCommand`](http://docs.paramiko.org/en/latest/api/proxy.html#paramiko.proxy.ProxyCommand)对象

- `put(*args, **kwargs)`:
  
  上传文件或者`file-like`对象到远程服务器

- `run(command, **kwargs)`:

  在远程服务器上执行shell命令，该方法是对[` invoke.runners.Runner.run`](http://docs.pyinvoke.org/en/latest/api/runners.html#invoke.runners.Runner.run)的封装，具体实现可参考` invoke.runners.Runner.run`的API文档


- `sftp()`:
  
  返回一个`SFTPClient`对象

  如果多次调用，则会记住第一个结果；因此，任何给定的`Connection`实例都将只具有一个`sftp client`，并且状态（如chdir管理的状态）将被保留。

- `sudo(command, **kwargs)`:
  
  在远程服务器上执行sudo命令


