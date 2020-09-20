//
//  14剪绳子.swift
//  Algorithm
//
//  Created by SimonYHB on 2020/9/20.
//  Copyright © 2020 叶煌斌. All rights reserved.
//

import Foundation

/*
 给你一根长度为 n 的绳子，请把绳子剪成整数长度的 m 段（m、n都是整数，n>1并且m>1），每段绳子的长度记为 k[0],k[1]...k[m-1] 。请问 k[0]*k[1]*...*k[m-1] 可能的最大乘积是多少？例如，当绳子的长度是8时，我们把它剪成长度分别为2、3、3的三段，此时得到的最大乘积是18。

 示例 1：

 输入: 2
 输出: 1
 解释: 2 = 1 + 1, 1 × 1 = 1
 示例 2:

 输入: 10
 输出: 36
 解释: 10 = 3 + 3 + 4, 3 × 3 × 4 = 36
 提示：

 2 <= n <= 58


 */

/*
 思路1：动态规划，列出所有可能，用备忘录消除重复步骤。可以发现超过4之后，剪成小段的值都比不剪大，所以特殊处理<3的长度，当总长度大于3时，剪成的<3的长度就不再进行分割，以此作为条件向上求值
 */
fileprivate var memset: [Int: Int] = [:]
func cuttingRope_v1(_ n: Int) -> Int {
    if n <= 1 { return n }
    if n == 2 { return 1 }
    if n == 3 { return 2 }
    var maxResult = 0
    var results = Array(repeating: 0, count: n+1)
    results[1] = 1
    results[2] = 2
    results[3] = 3
    for length in 4...n {
        maxResult = 0
        for left in 1...length/2 {
            let result = results[left] * results[length - left]
            if maxResult < result {
                maxResult = result
            }
            results[length] = maxResult
        }
    }
    return maxResult
    
}

/*
思路1：贪心算法， 相比于动态规划，贪心算法相当于是一个分支，不去求所有值。我们观察题目可知，当总长度>5时，尽可能多的剪长度为3的会使值最大，当剩下长度为4时再剪成2*2
*/

func cuttingRope(_ n: Int) -> Int {
    if n == 2 { return 1}
    if n == 3 { return 2}
    var threeCount = n / 3
    var threeRetain = n % 3
    // 当余1时，回退一个3，将余值凑成4
    if threeRetain == 1 {
        threeCount = threeCount - 1
        threeRetain = 4
    }

    return  Int(pow(Double(3), Double(threeCount))) * (threeRetain == 0 ? 1 : threeRetain)
}
