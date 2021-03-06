---
title: java 内存模型
keywords: 'java memory model, java内存模型'
date: 2019-05-30 06:17:16
tags:
  - java
categories:
  - java
---

## 前言

深入理解java 内存模型，对于开发高效率代码，分析解决潜在bug有莫大的帮助。下面我们将对 java 内存概念模型做一个详细的介绍，注意该模型只是概念模型，具体的实现各个虚拟机厂商有一定的差异性，但都遵循《java虚拟机规范》中的规定。

## java 内存模型概览

![](/images/331425-20160623115846235-947282498.png)

对于上图，总体介绍一下各个内存的功能以及对于程序来说在运行时参与的角色。

- 堆：所有线程所共享的内存区域，所有的对象实例，数组都在堆上分配。
- 栈：为线程所私有的存储区域，分为**jvm栈**和**本地方法栈**（Native Method Stack）。**jvm栈**用于存储线程所使用的局部变量表，操作数栈，方法出口等；**本地方法栈**用于存储虚拟机使用的Native方法服务。
- 方法区：所有线程共享（但线程安全），用于存储已被虚拟机加载的类信息，常量，静态变量等。方法区也包含运行时常量池。
- 程序计数器：标记字节码指令执行顺序。

## 堆 （Heap）

java 堆，是被所有线程共享的存储区域，是jvm内存中最大的一块。所有的对象实例和数组均存储在java 堆中。而指向对象实例的引用则存储在栈中。当然，随着JIT编译器的发展，这一现象也不是“绝对”的。java堆是垃圾回收器（GC）管理的主要区域。从内存回收的角度看，目前的垃圾回收算法采用的是**分代收集算法** 。因此，将java堆分成：新生代，老年代和永久代。

- 新生代：又分为：`Eden Space` , `From Space` 和 `ToSpace`。新创建的对象，存储在新生代`Eden Space`和 其中一个 `Survivor` 区域（有可能是 `From Space` 也有可能是 `ToSpace` ）。在程序中大部分的对象在快速使用后，指向它的引用消失，那么对象变成不可达的对象，这部分对象很快就会被GC回收。而存活的时间比较长的对象，则通过复制的方式转移到另外一个 `Survivor`区域。经过数次的GC后，还有一部分"活着"的对象，则复制到老生代区域。
![](/images/20190530141333.png)


- 老年代：存活了一段时间的对象。这些对象早早就被创建了，而且一直活了下来。我们把这些 存活时间较长 的对象放在一起，它们的特点是 存活对象多，垃圾少 。称为这片区域为： 老年代；
- 永久代：永久存在的对象。比如一些静态文件，这些对象的特点是不需要垃圾回收，永远存活。形象点描述这块区域为：永久代 。（不过在 Java 8 里已经把 永久代 删除了，把这块内存空间给了 元空间。）

- 抛出异常：
  
  `OutOfMemoryError`， 如果在堆中没有内存完成实例对象的分配，并且堆也无法再扩展（通过-Xmx和-Xms扩展）时，将会抛出OutOfMemoryError异常。


## 栈

### jvm栈

![](/images/20190528182223.png)

虚拟机栈（Java Virtual Machine Stacks），是线程私有的存储区域，生命周期同线程。如上图的线程1 和 线程2 。下面将详细介绍一下虚拟机栈。

假如上图线程1，执行方法 A,B和C，方法调用情况： A -> B -> C。每个方法被执行的时候，都会同时创建相应的栈帧，然后压入栈。然后执行时按后进先出的方式出栈调度。栈帧的作用就是存储方法所需要的一些资源：方法内部的局部变量，操作数栈（通过栈存储指令需要操作的数据），方法执行完后返回的地址。

- 抛出异常：
  
  `StackOverflowError`:如果线程请求的栈深度大于虚拟机所允许的深度，将抛出`StackOverflowError`异常。

  `OutOfMemoryError`: 如果虚拟机栈可以动态扩展（当前大部分的Java虚拟机都可动态扩展，只不过Java虚拟机规范中也允许固定长度的虚拟机栈），当扩展时无法申请到足够的内存时会抛出`OutOfMemoryError`异常。

### 本地方法栈

JVM栈是为 java方法执行服务的，而本地方法(Native Method Stacks)栈是为 jvm中内置的 **本地方法** 执行服务的。在我们看JDK源码时，经常会遇到类似下方的native方法。
```java
public static native void arraycopy(Object src,  int  srcPos,
                                        Object dest, int destPos,
                                        int length);
```

本地方法在执行时是在本地方法栈中执行的。

## 方法区
方法区（Method Area），与java堆一样，也是各个线程共享的存储区域。但是对于多线程来说，该区域是线程安全的。该内存主要是存储：类信息（类全路径名，类访问修饰符等），类类型，常量池等。

### 运行时常量池

运行时常量池是方法区的一部分，Class文件除了有类，接口的描述信息外，还有一项信息是常量池，用于存放编译期生成的各种字面量和符号引用。当然存放在常量池中的内容也不一定在编译器产生，运行期间也可能将新的常量放入池中。常量池是为了避免频繁的创建和销毁对象而影响系统性能，其实现了对象的共享。比如字符串常亮，在程序编译阶段就已经把所有的字符串常量存放到常量池中。

```
String s1 = new String('12345')
```
对于上面的代码，会有两个字符串被创建，一个是 `new String('12345')`，该字符串存放在 堆中，作为一个字符串对象。另一个是`'12345'` ，存放在常量池中。如果再新建一个对象`String s2 = new String('12345')` ，那么只创建一个 `new String('12345')` 存放在堆中。因字符串常量池中已经存在了 `12345` 那么，不会再去创建。



## 程序计数器

程序计数器，在jvm内存中，只占用很小一部分内存。程序经过编译成字节码后，存储到class文件。当一个线程执行时，加载程序的字节码。而程序计数器则是用来记录字节码行号的指示器。字节码解释器的工作 就是通过改变这个计数器的值来选择下一条执行的字节码指令。在多线程中，CPU轮流执行线程，为保证各个线程切换后恢复到上次的执行位置，则每个线程都需要一个独立的程序计数器。这样才能保证程序之间的协调运作。

