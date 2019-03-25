---
title: 精通Oracle SQL（第二版）读书笔记   -  第一章 SQL核心
date: 2016-12-05 13:52:54
tags:
  - Oracle
categoriesi:
  - Oracle
---


racle SQL（第二版）读书笔记
## 第一章 SQL核心
### 数据库接口
> 1.数据库接口:
> Oracle数据库的本地接口界面是**OCI**,**OCI** 将由 **Oracle内核**传递而来的查询语句发送到数据库。其他语言对应的接口：*Oracle JDBC-OCI、ODD.Net、Oracle 预编译器、Oracle ODBC以及Oracle C++ 调用接口OCCI驱动*。

### SQL*Plus
>配置：$ORACLE_HOME/network/admin/tnsnames.ora 文件中登记想要连接的数据库。


### 常用命令：
> * sqlplus /nolog: 启动sqlplus但不显示登录到数据库后的提示。

> * help index： 显示可用的命令

> * help set： 用来定制工作环境最基本的命令，但退出sqlplus或者关闭时，这些设置命令不会被保存。可在login.sql文件中修改sqlplus环境设置。

### 在login.sql文件中修改配置

> 在sql* plus启动时默认读取的两个文件，1.**$ORACLE_HOME/sqlplus/admin** 目录下的 **glogin.sql**和**login.sql** 文件。其中，**login.sql**中所有命令的优先级比glogin.sql高。Oracle log之后，启动sqlplus和在sqlplus中运行connect都会同时读取这两个文件。

### 执行命令
>在sql* plus中执行的是两种命令：**sql语句** 和 **SQL * Plus命令**

>SQL语句用**；** 和 **/** 结束输入

 -  1.  可在命令后和另起一行使用；
 -  2.  /只能在下行中被识别。
>sqlplus缓冲区
>sqlplus执行 *.sql 文件方式：1.直接输入 *.sql,2.输入@或者START *，可以省略后缀。

### 五大核心SQL语句(SELECT, INSERT, UPDATE, DELETE, MERGE)
#### 1. SELECT 语句
##### Oracle基于查询成本的优化器(Cost-Based Optimizer,CBO)用来产生实际的执行计划。
##### - select语句
> 处理过程中首先处理的是**From**子句，多个**From**则每个步骤想象成一个临时数据集，每经过一个**FROM**，则进行一步筛选，得最终结果数据集。

##### - From子句
> 子句可以包含表、视图、物化视图、分区或者子分区。处理联结时：交叉联结（笛卡尔乘积）、内联结、外联结。

##### - HAVING子句
> 将分组汇总后的查询结果限定为只满足该条件的数据行。GROUP BY 和 HAVING 子句的位置可以互换，但是一般情况下GROUP BY 放在前面。

##### - ORDER BY子句
> Oracle必须在其他所有子句都执行完毕之后按指定的列进行排序结果集。

#### 2. INSERT 语句
##### Insert语句可以向表、分区或者视图中添加行，可单表或者多表插入。
	INSERT ALL WHEN 条件1 THEN INTO table1
			   WHEN 条件2 THEN INTO table2
			   WHEN 条件3 THEN INTO table3
				...
			   SELECT ** FROM table4;
> 当指定**ALL**时，这个语句就会执行无条件的多表插入，可以用**FIRST**替换，此时指定按照**WHEN**子句在语句中的顺序进行判断	。

#### 3. UPDATE 语句		

##### 该语法由 **UPDATE、SET、WHERE** 组成	

#### 4. DELETE 语句

##### 由 DELETE、WHERE、FROM 组成

#### 5. MERGE 语句

##### MERGE 语句可以按条件获取要更新或者插入到表中的数据行，然后从 1 个或者多个源头对表进行更新或插入行。


