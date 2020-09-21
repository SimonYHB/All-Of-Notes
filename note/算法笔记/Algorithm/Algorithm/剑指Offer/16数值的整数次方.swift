//
//  16数值的整数次方.swift
//  Algorithm
//
//  Created by HuangBin Ye on 2020/9/21.
//  Copyright © 2020 叶煌斌. All rights reserved.
//

import Foundation

/*
 实现函数double Power(double base, int exponent)，求base的exponent次方。不得使用库函数，同时不需要考虑大数问题。
 
   
 
 示例 1:
 
 输入: 2.00000, 10
 输出: 1024.00000
 示例 2:
 
 输入: 2.10000, 3
 输出: 9.26100
 示例 3:
 
 输入: 2.00000, -2
 输出: 0.25000
 解释: 2-2 = 1/22 = 1/4 = 0.25
   
 
 说明:
 
 -100.0 < x < 100.0
 n 是 32 位有符号整数，其数值范围是 [−231, 231 − 1] 。
 
 
 */

/*
 思路：题目比较全单，主要是需要考虑所有情况，包括x和n的取值范围，另外还可以对乘法做优化。
 */
func myPow(_ x: Double, _ n: Int) -> Double {
    if x == 0 { return 0 }
    if n == 0 { return 1}
    if n == 1 { return x}
    var x_value = x
    var n_value = n
    if n < 0 {
        n_value = -n_value
        x_value = 1/x_value
    }
    var res: Double = 1
    while n_value > 0 {
        // 判断是奇数还是偶数，奇数就先乘1个到res中
        if (n_value & 1 == 1) {
            res = x_value * res
        }
        // 将乘数翻倍，相当于右移1位
        x_value = x_value * x_value
        // 依次右移，所有数值的最高位肯定是1，所以最后剩下的一定是1
        n_value >>= 1
    }
    return res
}
