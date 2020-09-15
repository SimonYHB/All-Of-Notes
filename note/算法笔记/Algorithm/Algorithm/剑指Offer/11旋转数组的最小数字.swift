//
//  11旋转数组的最小数字.swift
//  Algorithm
//
//  Created by SimonYHB on 2020/9/14.
//  Copyright © 2020 叶煌斌. All rights reserved.
//
/*
 把一个数组最开始的若干个元素搬到数组的末尾，我们称之为数组的旋转。输入一个递增排序的数组的一个旋转，输出旋转数组的最小元素。例如，数组 [3,4,5,1,2] 为 [1,2,3,4,5] 的一个旋转，该数组的最小值为1。

 示例 1：

 输入：[3,4,5,1,2]
 输出：1
 示例 2：

 输入：[2,2,2,0,1]
 输出：0
 
 */
import Foundation

func minArray(_ numbers: [Int]) -> Int {
    if numbers.isEmpty {
        return -1
    }
    
    //二分查找
    var start = 0
    var end = numbers.count-1
    var minIndex = start
    while numbers[start] >= numbers[end] {

        // 小于两个数据，且后面大于等于前面
        if (end - start) <= 1 {
            minIndex = end
            break
        }
        minIndex = (start + end) / 2
        if numbers[start] == numbers[minIndex] && numbers[end] == numbers[minIndex] {
            // 刚好三个数字相同，则在剩下的数字中顺序查找
            var min = numbers[start]
            for index in start...end-1 {
                min = min < numbers[index] ? min : numbers[index]
            }
            return min
        }
        if numbers[start] <= numbers[minIndex] {
            start = minIndex
        } else if numbers[end] >= numbers[minIndex] {
            end = minIndex
        }
    }
    return numbers[minIndex]
}
