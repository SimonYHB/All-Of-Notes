//
//  21调整数组顺序使奇数位于偶数前面.swift
//  Algorithm
//
//  Created by SimonYHB on 2020/9/27.
//  Copyright © 2020 SimonYe. All rights reserved.
//

import Foundation

/*
 输入一个整数数组，实现一个函数来调整该数组中数字的顺序，使得所有奇数位于数组的前半部分，所有偶数位于数组的后半部分。

  

 示例：

 输入：nums = [1,2,3,4]
 输出：[1,3,2,4]
 注：[3,1,2,4] 也是正确的答案之一。
  

 提示：

 1 <= nums.length <= 50000
 1 <= nums[i] <= 10000

 
 */

/*
 思路： 采用头尾指针，从头指针开始移动，遇到偶数则停下，尾指针移动，遇到奇数则交换头尾指针的值，重复上述步骤直到两指针相遇
 */
func exchange(_ nums: [Int]) -> [Int] {
    var newNums = nums
    var head = 0
    var foot = nums.count - 1
    while head < foot {
        while head < foot, newNums[head] & 1 == 1 {
            head += 1
        }
        while head < foot, newNums[foot] & 1 == 0 {
            foot -= 1
        }
        // 通过元祖来交换变量，省去了创建控件
        (newNums[head], newNums[foot]) = (newNums[foot], newNums[head])
    }
    return newNums
}
