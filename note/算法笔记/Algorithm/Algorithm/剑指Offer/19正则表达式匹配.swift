//
//  19正则表达式匹配.swift
//  Algorithm
//
//  Created by HuangBin Ye on 2020/9/23.
//  Copyright © 2020 SimonYe. All rights reserved.
//

import Foundation

/*
 请实现一个函数用来匹配包含'. '和'*'的正则表达式。模式中的字符'.'表示任意一个字符，而'*'表示它前面的字符可以出现任意次（含0次）。在本题中，匹配是指字符串的所有字符匹配整个模式。例如，字符串"aaa"与模式"a.a"和"ab*ac*a"匹配，但与"aa.a"和"ab*a"均不匹配。
 
 示例 1:
 
 输入:
 s = "aa"
 p = "a"
 输出: false
 解释: "a" 无法匹配 "aa" 整个字符串。
 示例 2:
 
 输入:
 s = "aa"
 p = "a*"
 输出: true
 解释: 因为 '*' 代表可以匹配零个或多个前面的那一个元素, 在这里前面的元素就是 'a'。因此，字符串 "aa" 可被视为 'a' 重复了一次。
 示例 3:
 
 输入:
 s = "ab"
 p = ".*"
 输出: true
 解释: ".*" 表示可匹配零个或多个（'*'）任意字符（'.'）。
 示例 4:
 
 输入:
 s = "aab"
 p = "c*a*b"
 输出: true
 解释: 因为 '*' 表示零个或多个，这里 'c' 为 0 个, 'a' 被重复一次。因此可以匹配字符串 "aab"。
 示例 5:
 
 输入:
 s = "mississippi"
 p = "mis*is*p*."
 输出: false
 s 可能为空，且只包含从 a-z 的小写字母。
 p 可能为空，且只包含从 a-z 的小写字母以及字符 . 和 *，无连续的 '*'。

 */
/*
 动态规划
 */
fileprivate var visited: [String: Bool] = [:]
func isMatch(_ s: String, _ p: String) -> Bool {
    let s_arr = Array(s)
    let p_arr = Array(p)
    return isMatch_dp(s_arr, 0, p_arr, 0)
}


func isMatch_dp(_ s: [Character], _ s_index: Int, _ p: [Character], _ p_index: Int) -> Bool {
    let s_count = s.count
    let p_count = p.count
    // base case（初始条件）
    // p匹配完了，如果s也刚好匹配完则返回true
    if p_index == p_count {
        return s_index == s_count
    }
    // s匹配完了，判断p剩下的是否是 a* 这种形式，如果是则可以匹配到空串，也是匹配成功
    if s_count == s_index {
        if (p_count - p_index) % 2 == 1 {
            return false
        }
        var index = p_index
        while index != p_count {
            if p[index + 1] != "*" {
                return false
            }
            index += 2
        }
        return true
    }
    // 使用备忘录消除重复访问
    let key = String(format: "%d - %d", s_index, p_index)
    if visited[key] != nil { return visited[key]!}
    
    // 核心逻辑(转移方程)
    var result = false
    // 判断两个字符是否相同，或者p为.
    if (p[p_index] == s[s_index] || p[p_index] == ".") {
        // p的下一位如果是*，则会出现匹配完和未匹配完两种情况
        if (p_index < p_count - 1 && p[p_index + 1] == "*") {
            result = isMatch_dp(s, s_index, p, p_index+2) //*只匹配当前一次
                || isMatch_dp(s, s_index+1, p, p_index)  //*往后继续匹配
        } else {
            //说明是正常的两个字符匹配，则各自+1往后匹配
            result = isMatch_dp(s, s_index+1, p, p_index+1)
        }
        
    } else {
        // 只有在p的下一位为*才可能满足，否则说明不匹配
        if (p_index < p_count - 1 && p[p_index + 1] == "*") {
            // 将p中*之后的字符继续与s当前字符匹配
            result = isMatch_dp(s, s_index, p, p_index+2)
        } else {
            return false
        }
    }
    
 
    
    visited[key] = result
    
    return result
}
