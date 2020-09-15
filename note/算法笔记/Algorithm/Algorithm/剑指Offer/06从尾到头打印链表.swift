//
//  06从尾到头打印链表.swift
//  Algorithm
//
//  Created by SimonYHB on 2020/9/13.
//  Copyright © 2020 叶煌斌. All rights reserved.
//
/*
 输入一个链表的头节点，从尾到头反过来返回每个节点的值（用数组返回）。

  

 示例 1：

 输入：head = [1,3,2]
 输出：[2,3,1]
  

 限制：

 0 <= 链表长度 <= 10000

 */
import Foundation
/**
 * Definition for singly-linked list.
 * public class ListNode {
 *     public var val: Int
 *     public var next: ListNode?
 *     public init(_ val: Int) {
 *         self.val = val
 *         self.next = nil
 *     }
 * }
 */

/*
 遍历链表，先将值存起来再倒叙输出
 */
func reversePrint(_ head: ListNode?) -> [Int] {
    var values: [Int] = []
    var node = head
    while node != nil {
        values.append(node?.val ?? 0)
        node = node?.next
    }
    return values.reversed()
}

