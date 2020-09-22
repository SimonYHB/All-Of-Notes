//
//  17打印从1到最大的n位数.swift
//  Algorithm
//
//  Created by HuangBin Ye on 2020/9/22.
//  Copyright © 2020 叶煌斌. All rights reserved.
//

import Foundation

/*
 输入数字 n，按顺序打印出从 1 到最大的 n 位十进制数。比如输入 3，则打印出 1、2、3 一直到最大的 3 位数 999。
 
 示例 1:
 
 输入: n = 1
 输出: [1,2,3,4,5,6,7,8,9]
   
 
 说明：
 
 用返回一个整数列表来代替打印
 n 为正整数
 
 */

func printNumbers(_ n: Int) -> [Int] {
    var arr: [Int] = []
    var max = 1
    for _ in 1...n {
        max *= 10
    }
    for num in 1..<max {
        arr.append(num)
    }
    return arr
}
