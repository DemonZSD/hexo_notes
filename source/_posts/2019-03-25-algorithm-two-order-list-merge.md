---
title: 合并两个有序数组——java实现
date: 2019-03-25 14:03:49
tags:
  - 算法
categories:
  - 常见算法
---
### 合并有序数组

将两个有序数组合并成一个数组


```
/**
 * @function 合并两个有序数组arr1[] arr2[]
 * @author PC
 *
 */
public class MergeOrderList {
	public static void merge(int [] arr1,int [] arr2){
		int len1 = arr1.length;//数组1长度
		int len2 = arr2.length;//数组2长度
		int len = len1 + len2;//合并后数组长度
		int arr[] = new int[len];//合并后的数组
		int j = len1-1;
		int i = len2-1;
		len--;
		while(i>=0&&j>=0){//从后向前比较
			if(arr2[i]>arr1[j]){//将第二个数组的最后第i个元素放入arr中
				arr[len--] = arr2[i];
				i--;//“指针”后移一位
			}else if(arr2[i]<=arr1[j]){//将第一个数组的最后第i个元素放入arr中
				arr[len--] = arr1[j];
				j--;//“指针”后移一位
			}
		}
		if(i>j){//将剩余的数组1或者数组2的元素全部追加到数组arr
			while(i>=0){
				arr[len--] = arr2[i--];
			}
		}else{
			while(j>=0){
				arr[len--] = arr1[j--];
			}
		}
		for (int k = 0; k < arr.length; k++) {
			System.out.print(arr[k]+" ");
		}
	}
	public static void main(String[] args) {
		int arr1[] = {1,4,5,7,10,11,15};
		int arr2[] = {2,3,6,8,9,13,14,17};
		merge(arr1,arr2);
	}
}

```
