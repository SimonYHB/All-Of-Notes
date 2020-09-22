//
//  18删除链表的节点.swift
//  Algorithm
//
//  Created by HuangBin Ye on 2020/9/22.
//  Copyright © 2020 叶煌斌. All rights reserved.
//

import Foundation

/*
 
 给定单向链表的头指针和一个要删除的节点的值，定义一个函数删除该节点。
 
 返回删除后的链表的头节点。
 
 注意：此题对比原题有改动
 
 示例 1:
 
 输入: head = [4,5,1,9], val = 5
 输出: [4,1,9]
 解释: 给定你链表中值为 5 的第二个节点，那么在调用了你的函数之后，该链表应变为 4 -> 1 -> 9.
 示例 2:
 
 输入: head = [4,5,1,9], val = 1
 输出: [4,5,9]
 解释: 给定你链表中值为 1 的第三个节点，那么在调用了你的函数之后，该链表应变为 4 -> 5 -> 9.
   
 
 说明：
 
 题目保证链表中节点的值互不相同
 */


func deleteNode(_ head: ListNode?, _ val: Int) -> ListNode? {
    // 头节点判断
    if head?.val == val {
        return head?.next
    }
    var cur = head
    while cur != nil {
        if cur?.next?.val == val {
            cur?.next = cur?.next?.next
            break;
        }
        cur = cur?.next
    }
    return head
}
