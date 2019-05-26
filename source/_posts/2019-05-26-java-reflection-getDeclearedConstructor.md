---
title: java反射 - getDeclaredConstructor()
keywords: 'java反射, 反射, java, getDeclaredConstructor'
date: 2019-05-26 06:58:26
tags:
  - java
  - 反射
categories:
  - java
---

### 1. 前言

在 java反射中，我们经常会遇到在**运行时**(runtime)获取类定义的构造方法。比如java 1.9之后的版本中，通过获得构造方法对象，进而去实例化一个类对象：

```java
clazz.getDeclaredConstructor().newInstance()
```

下面我们将通过两节对该方法进行介绍：

> * 源码解析
> * 示例

### 2. 源码解析

``` java
java.lang.Class.getDeclaredConstructor()
```
该方法是在 `java.lang.Class` 类中定义的方法。源码如下：

```java
public Constructor<T> getDeclaredConstructor(Class<?>... parameterTypes)
        throws NoSuchMethodException, SecurityException {
        checkMemberAccess(Member.DECLARED, Reflection.getCallerClass(), true);
        return getConstructor0(parameterTypes, Member.DECLARED);
    }

```
**方法：** `getDeclaredConstructor(Class<?>... parameterTypes)`，用于获取**类**或者**接口**的 Constructor 对象。

**参数：** `Class<?>... parameterTypes` ，表示该构造方法的参数类型数组。若类定义多个构造器对象。

**返回值：** `Constructor<T>`， 通过指定的参数列表，获取对应的构造函数对象。

**异常：**
> *  `NoSuchMethodException`, 如果对应参数类型列表的构造方法不存在，则抛出该异常。
> *  `SecurityException`, 如果该函数的**调用者**(caller)对应的类加载器与该类的类加载器不一致，并且`checkPermission` 或者 `checkPackageAccess`拒绝对该类的访问，则抛出 `SecurityException` 异常。 该异常是内部调用函数 `checkMemberAccess` 抛出。

我们来分析一下 `checkMemberAccess`， 在 `java 1.8` 版本中，对该方法的定义如下：

``` java
private void checkMemberAccess(int which, Class<?> caller, boolean                checkProxyInterfaces) {
    final SecurityManager s = System.getSecurityManager();
    if (s != null) {
        final ClassLoader ccl = ClassLoader.getClassLoader(caller);
        final ClassLoader cl = getClassLoader0();

        // 是否是公共函数
        if (which != Member.PUBLIC) {
            // 两个类加载器不一致
            if (ccl != cl) {
                // 校验 是否拥有SecurityConstants.CHECK_MEMBER_ACCESS_PERMISSION 类型的访问权限。
                s.checkPermission(SecurityConstants.CHECK_MEMBER_ACCESS_PERMISSION);
            }
        }
        /*检查是否允许ClassLoader ccl中加载的客户端在当前包访问策略下访问此类。 
        如果访问被拒绝，则抛出SecurityException。*/
        this.checkPackageAccess(ccl, checkProxyInterfaces);
    }
}
 ```
该方法的实现逻辑，首选获取 `SecurityManager`， 如果不为空，则 判断 `caller` （通过传入的 `Reflection.getCallerClass()` 获取 `caller` ） 的类加载器和该类的加载器是否相同，如果不同，则通过 `checkPermission` 进行访问权限判断。


### 3. 示例

首先定义一个 `User` 类：

```java

public class User{
    private String id;
    private String name;
    private Integer age;

    // 第一个构造函数，参数类型：String.class String.class
    public User(String id, String name){
        this.id = id;
        this.name = name;
    }
    // 第二个构造函数, 参数类型：String.class, String.class, Integer.class
    public User(String id, String name, Integer age) {
        this.id = id;
        this.name = name;
        this.age = age;
    }

    @Override
    public String toString() {
        return "User{" +
                "id='" + id + '\'' +
                ", name='" + name + '\'' +
                ", age=" + age +
                '}';
    }
    
    // 省略 get set方法
    // ...
}

```

然后定义 `main` 方法：

```java
Public class TestMain{
    User user = new User("1","Jim", 22)；
    System.out.println(user)；  // 打印 User{id='1', name='Jim', age=22}
    Class clazz = User.class; // or Class clazz = user.getClass();
    
    // 通过 public User(String id, String name) 获取构造器对象
    Constructor constructor = clazz.getDeclaredConstructor(String.class, String.class);
    // constructor.newInstance("2", "Tom", 28); 
    // 如果传参数为("2", "Tom", 28)将会报错：java.lang.IllegalArgumentException
    Object userObj = constructor.newInstance("2", "Tom");
    
    if (userObj instanceof User){
        System.out.println(userObj); // 打印 User{id='2', name='Tom', age=null
    }
}

```

