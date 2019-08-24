---
title: 计算数组中的最大值或者最小值
keywords: 'weshzhu, weshzhu blogs, 计算最大值，最大值，计算最小值，最小值'
date: 2019-07-03 08:06:38
tags:
  - java
  - 计算最小值
categories:
  - 常见算法
---

# 计算数组中的最小值（或最大值）

### 使用递归计算

```java
public static int calcMinimalWithRecursive(int [] values){
    if(values==null || values.length < 1){
        throw new java.lang.IllegalArgumentException("the calc values length must be one or more");
    }else if(values.length == 1){
        return values[0];
    }else if(values.length == 2){  // 出栈，跳出递归
        return Math.min(values[0], values[1]);
    }else{
        return Math.min(
                calcMinimalWithRecursive(Arrays.copyOfRange(values, 0, values.length-1 )),
                values[values.length-1]);
    }
}

public static void main(String[] args) {
    int [] values = {-1,-3,2,4,5,-10,12};
    System.out.println(calcMinimalWithRecursive(values));  // 输出 -10
}

```

### 使用`loop`循环计算

```java
public static int calcMinimalWithNormal(int [] values){
    int min = Integer.MAX_VALUE;  // 预设个最小值
    if(values==null || values.length < 1){
        throw new java.lang.IllegalArgumentException("values's size > 1");
    }else if(values.length == 1){
        return values[0];
    }else if(values.length == 2) {
        return Math.min(values[0], values[1]);
    }else{
        for (int i=0; i< values.length;i++){ // 遍历，获取每次的最小值。
            min = Math.min(min,values[i]);
        }
    }
    return min;
}


public static void main(String[] args) {
    int [] values = {-1,-3,2,4,5,-10,12};
    System.out.println(calcMinimalWithNormal(values));  // 输出 -10
}

```


