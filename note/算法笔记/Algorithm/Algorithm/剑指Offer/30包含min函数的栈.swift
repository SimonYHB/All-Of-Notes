//
//  30包含min函数的栈.swift
//  Algorithm
//
//  Created by HuangBin Ye on 2020/10/21.
//  Copyright © 2020 SimonYe. All rights reserved.
//

import Foundation

/*
 定义栈的数据结构，请在该类型中实现一个能够得到栈的最小元素的 min 函数在该栈中，调用 min、push 及 pop 的时间复杂度都是 O(1)。
 
   
 
 示例:
 
 MinStack minStack = new MinStack();
 minStack.push(-2);
 minStack.push(0);
 minStack.push(-3);
 minStack.min();   --> 返回 -3.
 minStack.pop();
 minStack.top();      --> 返回 0.
 minStack.min();   --> 返回 -2.

 */

/*
 思路：使用两个数组，一个用于存储数据，一个用于辅助存储最小值
 */
class MinStack {
    private var dataStack: [Int]
    private var minStack: [Int]
    
    /** initialize your data structure here. */
    init() {
        dataStack = [Int]()
        minStack = [Int]()
    }
    
    func push(_ x: Int) {
        dataStack.append(x)
        if let min = minStack.last {
            if min >= x {
                minStack.append(x)
            }
        } else {
            minStack.append(x)
        }
        
    }
    
    func pop() {
        if dataStack.count == 0 {
            return
        }
        let num = dataStack.removeLast()
        if num == minStack.last {
            minStack.removeLast()
        }
        
    }
    
    func top() -> Int {
        return dataStack.last ?? 0
    }
    
    func min() -> Int {
        return minStack.last ?? 0
    }
}
