//
//  24反转链表.swift
//  Algorithm
//
//  Created by HuangBin Ye on 2020/10/15.
//  Copyright © 2020 SimonYe. All rights reserved.
//

import Foundation


/*
 定义一个函数，输入一个链表的头节点，反转该链表并输出反转后链表的头节点。
 
   
 
 示例:
 
 输入: 1->2->3->4->5->NULL
 输出: 5->4->3->2->1->NULL
   
 
 限制：
 
 0 <= 节点个数 <= 5000

 */

/*
 思路：采用双指针，分别记录上个节点信息和当前要处理的节点，除此之外还要保存当前节点的next指针
 */
func reverseList(_ head: ListNode?) -> ListNode? {
    if head == nil || head?.next == nil {
        return head
    }
    var node = head
    var preNode: ListNode? = nil
    var nextNode: ListNode? = nil
    while node != nil {
        // 记录下个节点信息
        nextNode = node?.next
        // 将当前节点的next指向其上一个节点
        node?.next = preNode
        // 将当前节点当作上个节点
        preNode = node
        // 更新到下一个节点
        node = nextNode
    }
    return preNode
}
