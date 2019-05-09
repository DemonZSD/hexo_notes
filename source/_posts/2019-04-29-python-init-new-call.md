---
title: python __init__ __new__ __call__ 方法介绍
keywords: 'weshzhu, python __init__ __new__ __call__ 方法介绍'
date: 2019-04-29 11:56:03
tags:
  - python
categories:
  - python
---


## `__init__`

`__init__()` 方法用于对象的初始化，是一个实例方法，第一个参数为 `self` 。类似于 `java` 中的构造函数，专门用于对象的初始化。

在对象实例化的过程中，实际是先创建一个对象，然后对对象进行初始化（如果没有创建好对象，就无法进行初始化）。即先调用 `__new__()` 方法，然后 `__init__()` 方法对对象进行初始化。

例如 `Foo` 类的定义如下：

```python
class Foo:
    def __init__(self):
        print("__init__ ")
        super(Foo, self).__init__()

    def __new__(cls):   
        print("__new__ ")
        return super(Foo, cls).__new__(cls)

    def __call__(self):  # 可以定义任意参数
        print('__call__ ')

```

输出顺序：

```
__init__
__new__
```
可以看到先执行的 `__new__` 创建对象方法，然后执行 `__init__` 初始化方法。

在 `__new__()`方法中，返回值 `return super(Foo, cls).__new__(cls)` ，会作为 `__init__(self)`方法参数 `self` 传递给 `__init__()` 方法，进而完成对象的初始化工作。

另外，`__init__` 方法中除了`self`之外定义的参数，都将与`__new__`方法中除`cls`参数之外的参数是必须保持一致或者等效。

```
class Foo:
    def __init__(self, name):  # 保证与 new 方法参数一致，name
        print("__init__ ")
        super(Foo, self).__init__()

    def __new__(cls, name):   # 保证与init 方法参数一致，name
        print("__new__ ")
        return super(Foo, cls).__new__(cls)

    def __call__(self):  # 可以定义任意参数
        print('__call__ ')
```


## `__new__`

`__new__()` 方法用于对象的创建，是一个静态方法，第一个参数为cls。

`__new__()` 方法在类定义中不是必须写的，如果没定义，默认会调用 `object.__new__()` 方法去创建一个对象。如果定义了，就是`override` 父类 `object` 的 `__new__()` 方法（注意：对于`Python2.x`，必须显示的继承 `object` 类；针对 `Python3.x` 类的定义默认是继承了 `object` 类，无需显示继承），然后在该方法中自定义创建对象的行为。


对于刚开始的例子，`__new__()`方法的返回值就是类的实例对象，然后再调用`__init__`方法。


如果 `__new__` 方法不返回值（或者说返回 `None`）那么 `__init__` 将不会得到调用。

例如：定义一个 `Bar` 类和 `Foo` 类，在 `Foo` 类的 `__new__` 方法中，返回的是 `Bar` 实例，因此在实例化 `Foo` 类时，创建的不是 `Foo` 类对象，而是 `Bar` 类对象

```python
# test.py
class Bar(object):
    def __repr__(self):
        return 'Bar'
 
class Foo(object):
    def __new__(cls, *args, **kwargs):
        return Bar()
 
print(str(Foo())==str(Bar()))
```

```shell
$ python test.py
True
```


## `__call__`

就是可调用对象（callable，注意是对象，不是类），我们平时自定义的函数、内置函数和类都属于可调用对象，但凡是可以把一对括号()应用到某个对象身上都可称之为可调用对象，判断对象是否为可调用对象可以用函数 `callable` 。

如果在类中实现了 `__call__` 方法，那么实例对象也将成为一个可调用对象，我们回到开始介绍的那个例子：
```
a = Foo()
print(callable(a))  # True
```
[很好的例子](https://stackoverflow.com/questions/5824881/python-call-special-method-practical-example)

```python
class Factorial:
    def __init__(self):
        self.cache = {}
    def __call__(self, n):
        if n not in self.cache:
            if n == 0:
                self.cache[n] = 1
            else:
                self.cache[n] = n * self.__call__(n-1)
        return self.cache[n]

fact = Factorial()

```
调用
```python
for i in xrange(10):
   print("{}! = {}".format(i, fact(i)))
```
