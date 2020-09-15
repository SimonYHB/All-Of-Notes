//
//  10斐波那契数列.swift
//  Algorithm
//
//  Created by SimonYHB on 2020/9/14.
//  Copyright © 2020 叶煌斌. All rights reserved.
//
/*
 写一个函数，输入 n ，求斐波那契（Fibonacci）数列的第 n 项。斐波那契数列的定义如下：

 F(0) = 0,   F(1) = 1
 F(N) = F(N - 1) + F(N - 2), 其中 N > 1.
 斐波那契数列由 0 和 1 开始，之后的斐波那契数就是由之前的两数相加而得出。

 答案需要取模 1e9+7（1000000007），如计算初始结果为：1000000008，请返回 1。

  

 示例 1：

 输入：n = 2
 输出：1
 示例 2：

 输入：n = 5
 输出：5
  

 提示：

 0 <= n <= 100
 
 */
import Foundation

/*
 思路1：动态规划，依次列出0到n的所有值
 */
func fib(_ n: Int) -> Int {
    if n == 0 {return 0}
    if n == 1 {return 1}
    var dp = Array(repeating: 0, count: n+1)
    dp[1] = 1
    for i in 2...n {
        dp[i] = (dp[i-1] + dp[i-2]) % 1000000007
    }
    return dp[n]
}

/*
 思路2：单纯使用递归复杂度太高，利用备忘录的形式记录，减少重复计算
 */
fileprivate var dic: [Int: Int] = [:]
func fib_v2(_ n: Int) -> Int {
    if let value = dic[n] {
        return value
    }
    if n <= 0 {return 0}
    if n == 1 {return 1}
    let value = (fib_v2(n-1) + fib_v2(n-2)) % 1000000007
    dic[n] = value
    return value
}

