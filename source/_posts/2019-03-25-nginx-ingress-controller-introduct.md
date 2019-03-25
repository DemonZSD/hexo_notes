---
title: NGINX Ingress Controller教程
date: 2019-01-25 16:26:10
tags:
  - kubernetes
categories:
  - 运维
  - kubernetes

---

## NGINX Ingress Controller
[TOC]
### Bare-metal considerations
 - MetalLB
`MetalLB`提供了一个不仅仅只有云服务商才可提供的在`kubernetes`集群上的网络负载均衡实现。有效地允许在任何集群中使用 LoadBalancer 服务。
本教程介绍使用[ **Layer 2 configuration mode**](https://metallb.universe.tf/tutorial/layer2/) [**MetalLB**](https://metallb.universe.tf/)和`NGINX Ingress controller`在集群中有公开访问的节点。在此模式下，一个节点吸引`ingress-nginx`服务IP的所有流量。
**MetalLB:Layer2**
![MetalLB:Layer2](/images/metallb.jpg)
例如：Given the following 3-node Kubernetes cluster (the external IP is added as an example, in most bare-metal environments this value is <None>)
```
$ kubectl describe node
NAME     STATUS   ROLES    EXTERNAL-IP
host-1   Ready    master   203.0.113.1
host-2   Ready    node     203.0.113.2
host-3   Ready    node     203.0.113.3
```
依照下方`yaml`文件创建`ComfigMap`, MetalLB获得池中其中一个IP地址的所有权，并相应地更新`ingress-nginx`服务的`loadBalancer IP`字段。.
```
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 203.0.113.2-203.0.113.3
```
```
$ kubectl -n ingress-nginx get svc
NAME                   TYPE          CLUSTER-IP     EXTERNAL-IP  PORT(S)
default-http-backend   ClusterIP     10.0.64.249    <none>       80/TCP
ingress-nginx          LoadBalancer  10.0.220.217   203.0.113.3  80:30100/TCP,443:30101/TCP
```
----
 - ##### Over a NodePort Service
 在该配置下，NGINX 容器与主机网络保持隔离。因此，它可以安全地绑定到任何端口，包括标准HTTP端口80和443.但是，由于容器命名空间隔离，位于群集网络外部的客户端（例如，在公共Internet上）无法直接通过端口80和443访问Ingress。因此，必须分配`ingress-nginx service`的`Type`为`Nodeport`。
 ![Over a NodePort Service](/images/nodeport.jpg)
 例如：Given the NodePort 30100 allocated to the ingress-nginx Service
 ```
$ kubectl get svc -n ingress-nginx
NAME                   TYPE        CLUSTER-IP     PORT(S)
default-http-backend   ClusterIP   10.0.64.249    80/TCP
ingress-nginx          NodePort    10.0.220.217   80:30100/TCP,443:30101/TCP
 ```
 其中一个`Node`节点的IP地址为203.0.113.2 (`external IP`只是一个举例, 在大部分 bare-metal环境中该值是`<None>`)
```
$ kubectl describe node
NAME     STATUS   ROLES    EXTERNAL-IP
host-1   Ready    master   203.0.113.1
host-2   Ready    node     203.0.113.2
host-3   Ready    node     203.0.113.3
```
客户端可通过`http://myapp.example.com:30100`与配置`host`:`myapp.example.com`的`Ingress`进行通信，` myapp.example.com` 子域解析为203.0.113.2地址。
这种方法还有一些应该注意的其他限制
  - **Source IP address**
    Services of type NodePort perform source address translation by default。这意味着：HTTP请求的`source IP`始终是从NGINX的角度接收请求的Kubernetes节点的IP地址。
	建议通过设置`ingress-nginx Service`的`spec.externalTrafficPolicy`的属性域为`local`（[例如](https://github.com/kubernetes/ingress-nginx/blob/nginx-0.19.0/deploy/provider/aws/service-nlb.yaml#L12-L14)），来保留`source IP`
	```yaml
	kind: Service
	apiVersion: v1
	metadata:
	  name: ingress-nginx
	  namespace: ingress-nginx
	  ...
	spec:
	  # this setting is t make sure the source IP address is preserved.
	  externalTrafficPolicy: Local
	  type: LoadBalancer
	  ...
	  ports:
	  - name: http
		port: 80
		targetPort: http
	  ...
	```
	例如一个集群中有三个`Node`，(`external IP`只是一个举例, 在大部分 bare-metal环境中该值是`<None>`)
	```
	$ kubectl describe node
	NAME     STATUS   ROLES    EXTERNAL-IP
	host-1   Ready    master   203.0.113.1
	host-2   Ready    node     203.0.113.2
	host-3   Ready    node     203.0.113.3
	```
	nginx-ingress-controller的Deployment 有两个副本集`replicas`
	```
	$ kubectl get pod -o wide -n ingress-nginx
	NAME                                       READY   STATUS    IP           NODE
	default-http-backend-7c5bc89cc9-p86md      1/1     Running   172.17.1.1   host-2
	nginx-ingress-controller-cf9ff8c96-8vvf8   1/1     Running   172.17.0.3   host-3
	nginx-ingress-controller-cf9ff8c96-pxsds   1/1     Running   172.17.1.4   host-2
	```
	到`host-2`和`host-3`的请求将被转发到 `NGINX`并且原始的客户端IP将被保留，但是请求到`host-1`的`Node`的请求将被丢弃，因为在该`Node`上没有`NGINX`副本集。
	
  - **Ingress status**
    因为`NodePort`类型的`Service`没有按定义分配`LoadBalancerIP`，`NGINX Ingress controller`不会更新`Ingress`对象的状态。
	```
	$ kubectl get ingress
    NAME           HOSTS               ADDRESS   PORTS
    test-ingress   myapp.example.com             80
	```
	尽管没有负载均衡器为`NGINX Ingress Controller`提供公共IP地址，但可以通过设置`ingress-nginx Service`的`externalIPs`字段来强制所有管理的Ingress对象的状态更新。
	例如：一个集群中有三个`Node`，(`external IP`只是一个举例, 在大部分 bare-metal环境中该值是`<None>`)
	```
	$ kubectl describe node
	NAME     STATUS   ROLES    EXTERNAL-IP
	host-1   Ready    master   203.0.113.1
	host-2   Ready    node     203.0.113.2
	host-3   Ready    node     203.0.113.3
	```
	可以编辑`ingress-nginx Service` 添加如下代码片段到到属性域`spec`中：
	```
	...
	spec:
	  externalIPs:
	  - 203.0.113.1
	  - 203.0.113.2
	  - 203.0.113.3
	...
	```
	如此，将会在`Ingress`对象上生效：
	```
	$ kubectl get ingress -o wide
	NAME           HOSTS               ADDRESS                               PORTS
	test-ingress   myapp.example.com   203.0.113.1,203.0.113.2,203.0.113.3   80
	```
  - **Redirects**
  > As NGINX is not aware of the port translation operated by the NodePort Service, backend applications are responsible for generating redirect URLs that take into account the URL used by external clients, including the NodePort.
   
    由于NGINX不知道NodePort服务运营的端口转换，后端应用程序负责生成考虑外部客户端（包括NodePort）使用的URL的重定向URL。
	举例：Redirects generated by NGINX, for instance HTTP to HTTPS or domain to www.domain, are generated without NodePort:
	```
	$ curl -D- http://myapp.example.com:30100
	HTTP/1.1 308 Permanent Redirect
	Server: nginx/1.15.2
	Location: https://myapp.example.com/  #-> missing NodePort in HTTPS redirect
	```
----
 - ##### Via the host network
   在没有可用的外部负载均衡器的设置中，但不能使用`NodePorts`。还有一种方法就是，通过设置`ingress-nginx`的Pods使用**主机网络**，而不是专用的网络命名空间(`network namespace`)。该方案的好处就是，在没有额外的`NodePort Service`提供的外部网络转换情况下，`NGINX Ingress controller`可以直接绑定k8s的`Node`网络接口的端口80或443。
   这可以通过配置Pods属性域`template.spec`的`hostNetwork`选项来实现：
   ```
   template:
	  spec:
		hostNetwork: true
   ```
   注意：
   启用此选项会将所有系统守护进程暴露给任何网络接口上的`NGINX Ingress Controller`，包括主机的环回地址。请仔细评估这可能对您系统的安全性产生的影响。
   例如：`nginx-ingress-controller`Deployment有两个副本集，`NGINX` PodsN继承其主机的IP地址，而不是内部 Pod IP
   ```
   $ kubectl get pod -o wide -n ingress-nginx
	NAME                                       READY   STATUS    IP            NODE
	default-http-backend-7c5bc89cc9-p86md      1/1     Running   172.17.1.1    host-2
	nginx-ingress-controller-5b4cf5fc6-7lg6c   1/1     Running   203.0.113.3   host-3
	nginx-ingress-controller-5b4cf5fc6-lzrls   1/1     Running   203.0.113.2   host-2
   ```
   该部署方式的主要限制是：每个群集节点上只能安排一个`NGINX Ingress Controller` Pod，这是因为在同一网络接口上多次绑定同一个端口在技术上是不可能的。举例：因此方式导致的 Pods 不可调度，
   ```
   $ kubectl -n ingress-nginx describe pod <unschedulable-nginx-ingress-controller-pod>
	...
	Events:
	  Type     Reason            From               Message
	  ----     ------            ----               -------
	  Warning  FailedScheduling  default-scheduler  0/3 nodes are available: 3 node(s) didn't have free ports for the requested pod ports.
   ```
   确保仅创建可调度Pod的一种方法是将`NGINX Ingress Controller`部署为`DaemonSet`而不是传统的`Deployment`。
   ![hostnetwork](/images/hostnetwork.jpg)
   与NodePorts一样，这种方法有一些怪癖，重要的是要注意
     - **DNS resolution**
     如果Pods配置了`hostNetwork: true`属性，则不使用内部DNS解析器(`kube-dns`或`CoreDns`)，除非Pods的`spec.dnsPolicy`配置了`ClusterFirstWithHostNet`属性。
	 
     - **Ingress status**
     由于在使用主机网络的配置中没有服务公开NGINX Ingress控制器，因此标准云设置中使用的默认--publish-service标志不适用，并且所有Ingress对象的状态保持空白。
	 ```
	 $ kubectl get ingress
	NAME           HOSTS               ADDRESS   PORTS
	test-ingress   myapp.example.com             80
	 ```
	 相反，由于`bare-metal`Node通常没有`Extral IP`，因此必须启用`--report-node-internal-ip-address`，它将所有Ingress对象的状态设置为运行`NGINX Ingress Controller`的所有节点的内部IP地址。
	 Given a nginx-ingress-controller DaemonSet composed of 2 replicas
	 ```
	 $ kubectl -n ingress-nginx get pod -o wide
	NAME                                       READY   STATUS    IP            NODE
	default-http-backend-7c5bc89cc9-p86md      1/1     Running   172.17.1.1    host-2
	nginx-ingress-controller-5b4cf5fc6-7lg6c   1/1     Running   203.0.113.3   host-3
	nginx-ingress-controller-5b4cf5fc6-lzrls   1/1     Running   203.0.113.2   host-2
	 ```
	 控制器将其管理的所有Ingress对象的状态设置为以下值：
	 ```
	 $ kubectl get ingress -o wide
	NAME           HOSTS               ADDRESS                   PORTS
	test-ingress   myapp.example.com   203.0.113.2,203.0.113.3   80
	 ```
 - ##### Using a self-provisioned edge
   与云环境类似，该部署方式需要边缘网络组件（edge network component ）为Kubernetes集群提供公共入口点。该边缘组件可以是硬件（例如供应商设备）或软件（例如HAproxy），并且通常由运营团队在Kubernetes范围之外进行管理。
   此类部署基于上面在Over NodePort服务中描述的NodePort服务构建，但有一个显着区别：外部客户端不直接访问集群节点，只有边缘组件才能访问集群节点。这特别适用于没有节点具有公共IP地址的私有Kubernetes集群。
   边缘网络外部，唯一的先决条件是专用一个公共IP地址，将所有HTTP流量转发到Kubernetes节点和/或主节点。 TCP端口80和443上的传入流量将转发到目标节点上的相应HTTP和HTTPS NodePort，如下图所示：
   ![Using a self-provisioned edge](/images/user_edge.jpg)
   根据官方Kubernetes文档的“服务”页面，`externalIPs`选项使kube-proxy将发送到任意IP地址和服务端口的流量路由到该服务的`endpoints`。这些IP地址必须属于目标节点(target node)。
   > 例如：一个集群中有三个`Node`，(`external IP`只是一个举例, 在大部分 bare-metal环境中该值是`<None>`)
    ```
	$ kubectl describe node
	NAME     STATUS   ROLES    EXTERNAL-IP
	host-1   Ready    master   203.0.113.1
	host-2   Ready    node     203.0.113.2
	host-3   Ready    node     203.0.113.3
    ```
   and the following ingress-nginx NodePort Service
   ```
   $ kubectl -n ingress-nginx get svc
   NAME                   TYPE        CLUSTER-IP     PORT(S)
   ingress-nginx          NodePort    10.0.220.217   80:30100/TCP,443:30101/TCP
   ```
   我们可以在`Service`的`spec.externalIPs`属性域中设置**externalIPs**, 则**NGINX**通过`NodePort`和`Service Port`变的可达：
   ```
   spec:
	  externalIPs:
	  - 203.0.113.2
	  - 203.0.113.3
   ```
   ```
   $ curl -D- http://myapp.example.com:30100
   HTTP/1.1 200 OK
   Server: nginx/1.15.2
   $ curl -D- http://myapp.example.com
   HTTP/1.1 200 OK
   Server: nginx/1.15.2
   ```
   我们假设 `myapp.example.com` 域名解析成IP地址：203.0.113.2 和 203.0.113.3。



