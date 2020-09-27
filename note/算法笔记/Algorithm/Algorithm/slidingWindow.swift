//
//  slidingWindow.swift
//  Algorithm
//
//  Created by HuangBin Ye on 2020/8/18.
//  Copyright © 2020 SimonYe. All rights reserved.
//

import Foundation



class Solution {
//    3. 无重复字符的最长子串
    func lengthOfLongestSubstring(_ s: String) -> Int {
        var left = 0
        var length = 0
        var record = [Character : Int]()
        let chars = Array(s)

        for (index, character) in chars.enumerated() {
            
            guard let posInValue = record[character] else {
                // 说明是第一次采集到，继续向右输入
                record[character] = 1
                length = max(length, index - left + 1)
                continue
            }
            
            record[character] = posInValue + 1
            // 有重复则收缩左窗口
            while record[character]! > 1 {
                let c = chars[left]
                left = left + 1
                record[c] = record[c]! - 1
            }
           
            length = max(length, index - left + 1)
        }
        
        return length
    }
    
    
    
//    func lengthOfLongestSubstring(_ s: String) -> Int {
//        var left = 0
//        var length = 0
//        var record = [Character : Int]()
//        let chars = s.enumerated()
//        for (index, character) in chars {
//            // 判断记录中是否有该字符
//            if let posInRecord = record[character] {
//                // 重复出现在记录的右边才是有效的
//                left = max(left, posInRecord)
//            }
//            // 更新记录，下一个字符的开始
//            record[character] = index + 1
//            length = max(length, index - left + 1)
//        }
//
//        return length
//    }
}


