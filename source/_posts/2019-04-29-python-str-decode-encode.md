---
title: python str 和 unicode 区别
keywords: 'python str 和 unicode 区别, python str, python string, string encode, string decode, unicode, unicode str,weshzhu, weshzhu blogs'
date: 2019-04-29 08:47:14
tags:
  python
categories:
  python
---


## Python 字符串

> 环境：python2.7
>
> 工具：chardet (安装：pip install chardet)


在 `Python` 中，字符串的表示有两种， `str` 和 `unicode`  继承于 `basestring`。字符串的编码统一为 `unicode` ，这样的好处就是方便跨平台。而 `str` 其实是**字节串**，是 `unicode` 经过编码(`utf-8|gbk|ISO-8859-9| IBM855`等)后的字节组成的序列。在内存中的存储实质上还是 `unicode` 。

### str 

str 类型是以 **字节码** 存储的。根据原始文件读取或者从控制台输入自动决定该用何编码格式。

举例：
- 比如在文件中定义：
  若是显示指定编码格式，比如从网页中获取的内容（比如一行文字），网页的编码格式为 `GB2312`。则读取到 `python` 中后字符串编码格式与来源保持一致。

  开发过程中，新建 python 脚本，通常情况下，我们会指定编码格式，即：文件顶部声明该文件的编码格式为 `utf-8` 。在 `test.py` 中，定义一个变量：`s1 = '中国'`，那么该变量`s1`是根据该`test.py`文件的编码格式对`中国`进行编码。我们在 `test.py` 顶部声明该文件的编码格式为 `utf-8`：

  编辑 `test.py` 文件内容
  ```python
  # -*- coding:utf-8 -*-
  import chardet
  s1 = '中国'  #此处str类型的编码格式为 utf-8
  s2 = 'china'
  
  print(chardet.detect(s1))
  print(chardet.detect(s2))
  ```
  打印查看输出编码格式
  ```shell
  $ python test.py
  {'confidence': 0.7525, 'language': '', 'encoding': 'utf-8'}
  {'confidence': 1.0, 'language': '', 'encoding': 'ascii'}
  ```

- 在控制台：
  
  在 **windows** 中，对于可以使用 `ASCII` 编码进行表示的，优先使用 `ASCII` 编码：
  
  ```
  $ python
  Python 2.7.15 (v2.7.15:ca079a3ea3, Apr 30 2018, 16:30:26) [MSC v.1500 64   bit (AMD64)] on win32
  Type "help", "copyright", "credits" or "license" for more information.
  >>> import chardet
  >>> chardet.detect(str('china'))  # 查看编码格式
  {'confidence': 1.0, 'language': '', 'encoding': 'ascii'}
  
  ```

  对于无法使用 `ASCII` 编码进行表示的特殊字符（比如：汉字）进行编码。若无指定编码格式，选取最优编码格式进行编码，比如下面案例对字符串 `中国` 的编码格式是 `ISO-8859-9`。
  ```
  >>> chardet.detect(str('china中'))
  {'confidence': 0.35335532970260736, 'language': 'Turkish', 'encoding':   'ISO-8859-9'}
  ```

  在 **linux** 系统中，控制台输入默认都是 `utf-8` 的编码格式。
  
  ```
  $ python
  Python 2.7.5 (default, Oct 30 2018, 23:45:53)
  [GCC 4.8.5 20150623 (Red Hat 4.8.5-36)] on linux2
  Type "help", "copyright", "credits" or "license" for more information.
  >>> import chardet
  >>> chardet.detect(str('中国'))
  {'confidence': 0.7525, 'language': '', 'encoding': 'utf-8'}
  >>> chardet.detect(str('中国aaa'))
  {'confidence': 0.7525, 'language': '', 'encoding': 'utf-8'}
  ```


### unicode

`unicode` 是真正意义上的字符串， `Python2.x` 中所有的字符串加载到内存中，均是以 `unicode` 存储的，以 Unicode 表示的字符串 `u'...'` 。`unicode` 针对各国语言进行编码，解决了国际字符之间的相互转换问题。最常用的是用两个字节表示一个字符（如果要用到非常偏僻的字符，就需要4个字节）。
在 Python2.x 版本中，默认的编码格式为 `ascii`
```
$ import os
$ os.sys.getdefaultencoding()
'ascii'
```
这就导致了在python2.x中，

在 Python3.x 中，默认的编码格式均为 `utf-8`。
```
$ import os
$ os.sys.getdefaultencoding()
'utf-8'
```

`ASCII` 编码和 `Unicode` 编码的区别： `ASCII` 编码是1个字节，表示范围有限（最多能表示256个字符——英文字符、数字、标点符号），而 `Unicode` 编码通常是2个字节，可以表示所有国际字符（中文、俄罗斯文、日文等等）。

只要是 `unicode` 编码的字符串，都可以转换成任意语言的编码。这就是通过 `basestring` 中的 `encode()`方法进行转换。
```
# 将 unicode 的字符串 编码为 utf-8
$ u'ABC'.encode('utf-8')
'ABC'

# 将 unicode 的字符串 编码为 utf-8
$ u'中文'.encode('utf-8')
'\xe4\xb8\xad\xe6\x96\x87'   # 该字符就是 utf-8 编码格式下的字符

```

反过来，将各国语言编码成 `unicode`， 则使用 `decode('GBK|ut-8')` 方法。

```
# 将 utf-8编码的字符串 'abc' 解码为 unicode
$ 'abc'.decode('utf-8')
u'abc'

# 将 utf-8编码的字符串 '中文' 解码为 unicode
$ '\xe4\xb8\xad\xe6\x96\x87'.decode('utf-8')
u'\u4e2d\u6587'   # 该字符为将 utf-8 编码的字符 转换为 unicode 编码下的字符

$ print u'\u4e2d\u6587'
中文
```



