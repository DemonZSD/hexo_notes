---
title: Java并发编程：Callable、Future和FutureTask 
keywords: 'weshzhu, weshzhu blogs, Java并发编程, Callable, Future'
date: 2019-05-09 05:50:00
description:
tags:
  - java
  - 并发
  - 转载
categories:
  - java
---


在前面的文章中我们讲述了创建线程的2种方式，一种是直接继承Thread，另外一种就是实现Runnable接口。
这2种方式都有一个缺陷就是：在执行完任务之后无法获取执行结果。
如果需要获取执行结果，就必须通过共享变量或者使用线程通信的方式来达到效果，这样使用起来就比较麻烦。
而自从Java 1.5开始，就提供了Callable和Future，通过它们可以在任务执行完毕之后得到任务执行结果。
今天我们就来讨论一下Callable、Future和FutureTask三个类的使用方法。以下是本文的目录大纲：
 - Callable与Runnable
 - Future
 - FutureTask
 - 使用示例

## `Callable` 与 `Runnable`

- `Runnable`

`java.lang.Runnable` 是一个接口，在该接口中，声明了一个 `call()` 方法。

```
@FunctionalInterface
public interface Runnable {
    /**
     * When an object implementing interface <code>Runnable</code> is used
     * to create a thread, starting the thread causes the object's
     * <code>run</code> method to be called in that separately executing
     * thread.
     * <p>
     * The general contract of the method <code>run</code> is that it may
     * take any action whatsoever.
     *
     * @see     java.lang.Thread#run()
     */
    public abstract void run();
}
```

由于 run 方法返回 void 类型，所以在执行任务之后无法返回执行的结果。

- `Callable`

`Callable` 存在于 `java.util.concurrent.Callable` 。它是一个接口，在它里面也只声明了一个 call() 方法。

```
@FunctionalInterface
public interface Callable<V> {
    /**
     * Computes a result, or throws an exception if unable to do so.
     *
     * @return computed result
     * @throws Exception if unable to compute a result
     */
    V call() throws Exception;
}
```

可以看到，它是一个 泛型接口。call 返回的类型， 就是传递进来的泛型的类型。
那么怎么使用`Callable`呢？一般情况下是配合`ExecutorService`来使用的，在`ExecutorService`接口中声明了若干个`submit`方法的重载版本：
```
<T> Future<T> submit(Callable<T> task);
<T> Future<T> submit(Runnable task, T result);
Future<?> submit(Runnable task);
```
1. 第一个`submit`方法里面的参数类型就是`Callable`。
2. 暂时只需要知道`Callable`一般是和`ExecutorService`配合来使用的，具体的使用方法讲在后面讲述。
3. 一般情况下我们使用第一个`submit`方法和第三个`submit`方法，第二个`submit`方法很少使用。

## `Future`

`Future` 就是对于具体的 `Runnable` 或者 `Callable` 任务的执行结果进行取消、查询是否完成、获取结果。必要时可以通过 `get` 方法获取执行结果，该方法会阻塞直到任务返回结果。

`Future` 类位于 `java.util.concurrent` 包下，它是一个接口：

```
public interface Future<V> {

    boolean cancel(boolean mayInterruptIfRunning);

    boolean isCancelled();

    boolean isDone();

    V get() throws InterruptedException, ExecutionException;

    V get(long timeout, TimeUnit unit)
        throws InterruptedException, ExecutionException, TimeoutException;
}
```

在`Future`接口中声明了5个方法，下面依次解释每个方法的作用：

 - `cancel()` 方法用来取消任务，如果取消任务成功则返回 `true` ，如果取消任务失败则返回 `false` 。参数 `mayInterruptIfRunning` 表示是否允许取消正在执行却没有执行完毕的任务，如果设置 `true` ，则表示可以取消正在执行过程中的任务。如果任务已经完成，则无论 `mayInterruptIfRunning` 为 `true` 还是 `false` ，此方法肯定返回 `false` ，即如果取消已经完成的任务会返回 `false` ；如果任务正在执行，若 `mayInterruptIfRunning` 设置为 `true` ，则返回 `true` ，若 `mayInterruptIfRunning` 设置为 `false` ，则返回 `false` ；如果任务还没有执行，则无论 `mayInterruptIfRunning` 为 `true` 还是 `false` ，肯定返回 `true` 。
 - `isCancelled()` 方法表示任务是否被取消成功，如果在任务正常完成前被取消成功，则返回 `true`。
 - `isDone` 方法表示任务是否已经完成，若任务完成，则返回 `true` ；
 - `get()` 方法用来获取执行结果，这个方法会产生阻塞，会一直等到任务执行完毕才返回；
 - `get(long timeout, TimeUnit unit)` 用来获取执行结果，如果在指定时间内，还没获取到结果，就直接返回 `null` 。


也就是说Future提供了三种功能：

1. 判断任务是否完成；
2. 能够中断任务；
3. 能够获取任务执行结果。

因为 `Future` 只是一个接口，所以是无法直接用来创建对象使用的，因此就有了下面的`FutureTask`。

## `FutureTask`

我们先来看一下`FutureTask`的实现：
```
public class FutureTask<V> implements RunnableFuture<V>
```

可以看到 `FutureTask` 实现了 `RunnableFuture`，我们再看一下 `RunnableFuture` 的实现：

```
public interface RunnableFuture<V> extends Runnable, Future<V> {
    /**
     * Sets this Future to the result of its computation
     * unless it has been cancelled.
     */
    void run();
}
```

可以看出，`RunnableFuture` 接口继承了 `Runnable` 和 `Future`  接口，而 `FutureTask` 类是 RunnableFuture 唯一的实现类。所以它既可以作为 Runnable 被线程执行，又可以作为 Future 得到 Callable 的返回值。

FutureTask 提供了两个构造函数：

```
public FutureTask(Callable<V> callable) {
    if (callable == null)
        throw new NullPointerException();
    this.callable = callable;
    this.state = NEW;       // ensure visibility of callable
}

public FutureTask(Runnable runnable, V result) {
    this.callable = Executors.callable(runnable, result);
    this.state = NEW;       // ensure visibility of callable
}
```

## 使用示例

1. 使用 Callable 和 Future 获取执行结果
   
   ```
   class Task implements Callable<Integer>{
        @Override
        public Integer call() throws Exception {
            System.out.println("子线程在进行计算");
            Thread.sleep(3000);
            int sum = 0;
            for(int i=0;i<100;i++)
                sum += i;
            return sum;
        }
   }

   public class Test {
        public static void main(String[] args) {
            ExecutorService executor = Executors.newCachedThreadPool();
            Task task = new Task();

            // 将 task 放入
            Future<Integer> result = executor.submit(task);
            executor.shutdown();
            
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e1) {
                e1.printStackTrace();
            }
            
            System.out.println("主线程在执行任务");
            
            try {
                System.out.println("task运行结果"+result.get());
            } catch (InterruptedException e) {
                e.printStackTrace();
            } catch (ExecutionException e) {
                e.printStackTrace();
            }
            
            System.out.println("所有任务执行完毕");
        }
    }
   ```

2. 使用 Callable 和 FutureTask 获取执行结果
   
   ```
   // 任务必须实现 Callable 接口，并重写 call() 方法
   class Task implements Callable<Integer>{
        @Override
        public Integer call() throws Exception {
            System.out.println("子线程在进行计算");
            Thread.sleep(3000);
            int sum = 0;
            for(int i=0;i<100;i++)
                sum += i;
            return sum;
        }
   }
  
   public class Test {
        public static void main(String[] args) {
            //第一种方式
            ExecutorService executor = Executors.newCachedThreadPool();
            Task task = new Task();
            FutureTask<Integer> futureTask = new FutureTask<Integer>(task); // 创建一个
            executor.submit(futureTask);
            executor.shutdown();
                
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e1) {
                e1.printStackTrace();
            }
                
            System.out.println("主线程在执行任务");
                
            try {
                System.out.println("task运行结果"+futureTask.get());
            } catch (InterruptedException e) {
                e.printStackTrace();
            } catch (ExecutionException e) {
                e.printStackTrace();
            }
                
            System.out.println("所有任务执行完毕");
        }
        }

   ```
本文转载自：[Java并发编程：Callable、Future和FutureTask](https://www.cnblogs.com/dolphin0520/p/3949310.html)

