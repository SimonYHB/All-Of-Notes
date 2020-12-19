//
//  38字符串的排列.swift
//  Algorithm
//
//  Created by SimonYHB on 2020/12/12.
//  Copyright © 2020 SimonYe. All rights reserved.
//

import Foundation

/*
 输入一个字符串，打印出该字符串中字符的所有排列。

  

 你可以以任意顺序返回这个字符串数组，但里面不能有重复元素。

  

 示例:

 输入：s = "abc"
 输出：["abc","acb","bac","bca","cab","cba"]
  

 限制：

 1 <= s 的长度 <= 8

 */

// 思路： 回溯算法，固定位置依次交换字符，并且保证向同字符只在同一位置出现一次
func permutation(_ s: String) -> [String] {
    
    var result = [String]()
    // 用于记录当前字符是否被使用
    var visited = Array.init(repeating: false, count: s.count);
    // 将字符串排序拆成数组，如果有相同的字符其位置会相邻
    let s_arr = s.sorted()
    // 用于记录临时值
    var tempStr = ""
    
    permutation_backtrack(s_arr, &visited, &result, &tempStr)
    
    return result
}

func permutation_backtrack(_ s_arr: [Character], _ visited: inout [Bool], _ result: inout [String], _ tempStr: inout String) {
    // 字符串数相等时加入数组
    if tempStr.count == s_arr.count {
        result.append(tempStr)
    }
    
    for i in 0..<s_arr.count {
        // 过滤已被使用的字符
        if visited[i] == true {
            continue
        }
        // 过滤重复值
        if i > 0 && s_arr[i] == s_arr[i-1] && visited[i-1] == true {
            continue
        }
        // 标记当前字符被选择
        visited[i] = true
        tempStr.append("\(s_arr[i])")
        
        // 下一个位置的选择
        permutation_backtrack(s_arr, &visited, &result, &tempStr)
        
        // 撤销当前字符选择
        visited[i] = false
        tempStr.removeLast()
    }
    
}
