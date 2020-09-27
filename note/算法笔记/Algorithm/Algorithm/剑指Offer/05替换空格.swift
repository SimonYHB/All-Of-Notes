//
//  05替换空格.swift
//  Algorithm
//
//  Created by SimonYHB on 2020/9/13.
//  Copyright © 2020 SimonYe. All rights reserved.
//
/*
 
 请实现一个函数，把字符串 s 中的每个空格替换成"%20"。

  

 示例 1：

 输入：s = "We are happy."
 输出："We%20are%20happy."
  

 限制：

 0 <= s 的长度 <= 10000

 */

import Foundation
/*
 方法1：由于Swift不用考虑扩容，所以直接利用String的延展性替换即可，如果要考虑扩容，则先遍历一遍找到空格的个数即可得到新字符串的长度。
 
 */
func replaceSpace(_ s: String) -> String {
    var new_s = ""
    for char in s {
        if char == " " {
            new_s.append(contentsOf: "%20")
        } else {
            new_s.append(char)
        }
    }
    return new_s
}


/*
 方法2： 直接使用Swift自带函数
 */
func replaceSpace_v2(_ s: String) -> String {
    
    return s.replacingOccurrences(of: " ", with: "%20")
}
