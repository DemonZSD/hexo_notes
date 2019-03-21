---
title: python_mulit_thread
date: 2019-03-21 15:56:07
tags:
  - Python
  - thread
---

### Lock
- 说明：

对共享内存（资源），进行加锁，释放锁。保证同一时间，只有一个线程对共享资源进行操作。即保证了对共享资源的原子操作。

- 使用：

```
import threading
_lock = threading.lock() # 定义锁 _local

_lock.accquire()  # 获取锁
# TODO do something
do_somthing(share_var)   # 操作共享资源
_lock.release()  #释放锁

```

- 缺点：
  
  死锁

  当有多个共享资源（比如：`R_A`, `R_B`），多个线程（比如：`T_A`, `T_B`），每个线程都需要操作共享资源。假如线程 `T_A` 已经获取了共享资源 `R_A`，`T_B` 获取了共享资源 `R_B` ， 而线程 `T_A` 等待 `T_B` 释放共享资源 `R_B` 。 同时，线程 `T_B` 等待 `T_A` 释放共享资源 `R_A` ，此时就陷入死锁状态。


### RLock

- 说明：

  RLock 其实叫做“Reentrant Lock”，就是可以重复进入的锁，也叫做“递归锁”。这种锁对比 `Lock` 有是四个特点：
  1. 谁获取谁释放。如果线程A获取锁，线程B无法释放这个锁，只有A可以释放；而 `Lock` 锁，可以被另外一个线程所释放。
  2. 同一线程可以多次获取到该锁，即可以acquire多次；
  3. 如果使用RLock，那么acquire和release必须成对出现。acquire多少次就必须release多少次，只有最后一次release才能改变RLock的状态为unlocked）
  4. 相对 `Rlock` ， `Lock` 速度更快。
- 使用：
  
  使用 `Rlock` 锁
  ```
  import threading  
  rLock = threading.RLock()  #RLock对象  
  rLock.acquire()  
  rLock.acquire() #在同一线程内，程序不会堵塞。  
  rLock.release()  
  rLock.release()  

  ```
  
  使用 `Lock` 锁：

  ```
  import threading  
  lock = threading.Lock() #Lock对象  
  lock.acquire()  
  lock.acquire()  #产生了死琐。  
  lock.release()  
  lock.release()  
  ```
  

- 缺点：
 
  
### semaphore（信号量）

- 说明：

  信号量是由操作系统管理的一个内部的数据结构，用于表示共享资源当前支持有多少并发线程进行操作。当信号量为**负值**时，那么所有想获取共享资源的线程被挂起，直到有线程释放信号量，信号量的值变成**非负值**时。

  本质上，信号量就是一个计数器，当计数器的值为 **非负值** 时， 通知其他线程，可以对共享资源进行竞争。当计数器的值为 **负值** 时，所有待获取共享资源的线程挂起状态。


- 使用：

  ```
  semaphore = threading.Semaphore(0)

  # Thread1:
  def thread1_method():
      semaphore.acquire()  # 线程1 对信号量进行获取操作
  

  # Thread2:
  def thread2_method():
    semaphore.release()  # 线程2 对信号量进行释放操作，可以提高计数器

  ```
  
  信号量的 release() 可以对计数器加 1 操作。然后通知其他的线程，如果信号量的计数器到了0，就会阻塞 acquire() 方法，直到得到另一个线程的release()操作，通知。如果信号量的计数器大于0，就会对这个值 -1 然后分配资源。
  

- 缺点：
  
  导致死锁

  有多个线程（比如：`t1` ， `t2`），竞争多个信号量（比如：`s1` , `s2`）。 假如，现在有一个线程 `t1` 先等待信号量 `s1` ，然后等待信号量 `s2` ，而线程 `t2` 会先等待信号量 `s2` ，然后再等待信号量 `s1` ，这样就可能会发生死锁，导致 `t1` 等待 `s2` ，但是 `t2` 在等待 `s1` 。


### Condition - 条件同步

- 说明：
  
  当多个线程**等待**同一个条件时，当条件发生的时候，会通知所有等待该条件的线程。比如生产者消费者里的例子：在消费者线程里，只要篮子（共享资源）不满（条件），消费者线程通知生产者线程可以操作该篮子（共享资源）；在生产者线程里，只要篮子不空（条件），生产者线程通知消费者线程可操作该篮子。

- 使用：

  ```
  import threading

  condition = threading.Condition()
  
  #  生产者
  def thread1_method():
    condition.acquire()
    # 条件判断
    if (condition_var == False)：  # 条件不满足       
        condition.wait()  # 释放锁，线程挂起，等待被其他线程唤醒
    
    # TODO do something

    condition.notify()  # 条件满足，通知其他线程
    condition.release()  # 释放资源

  # 消费者
  def thread2_method():
     
    condition.accquire()
    # 条件判断
    if (condition_var == False)：  # 条件不满足       
         condition.wait()  # 释放锁，线程挂起，等待被其他线程唤醒

    # 条件满足
    # TODO  do something

    condition.notify()  # 条件满足，通知其他线程
    condition.release()   # 释放资源

  ```
  `wait` 方法释放内部所占用的琐，同时线程被挂起，直至接收到通知被唤醒或超时（如果提供了timeout参数的话）。当线程被唤醒并重新占有琐的时候，程序才会继续执行下去。
  
  `notify` 唤醒一个挂起的线程（如果存在挂起的线程）。注意：`notify()`方法不会释放所占用的琐。需要通过 `release()` 方法释放锁。


- 缺点：
  

### Event - 事件

- 说明：
- 使用：

  ```
  import threading
  event = threading.Event()
  

  ```

- 缺点：





**参考：**

- [基于线程的并行](https://python-parallel-programmning-cookbook.readthedocs.io/zh_CN/latest/chapter2/index.html)

- [What is the difference between Lock and RLock
](https://stackoverflow.com/questions/22885775/what-is-the-difference-between-lock-and-rlock)


