//
//  25合并两个排序的链表.swift
//  Algorithm
//
//  Created by HuangBin Ye on 2020/10/16.
//  Copyright © 2020 SimonYe. All rights reserved.
//

import Foundation
/*
 输入两个递增排序的链表，合并这两个链表并使新链表中的节点仍然是递增排序的。
 
 示例1：
 
 输入：1->2->4, 1->3->4
 输出：1->1->2->3->4->4
 限制：
 
 0 <= 链表长度 <= 1000
 
 */

/*
 思路：依次递归比较两个链表中节点的大小，直到出现Nil
 */
func mergeTwoLists(_ l1: ListNode?, _ l2: ListNode?) -> ListNode? {
    guard let l1 = l1 else {
        return l2
    }
    guard let l2 = l2 else {
        return l1
    }

    var newLHead: ListNode? = nil
    if l1.val < l2.val {
        newLHead = l1
        newLHead?.next = mergeTwoLists(l1.next, l2)
    } else {
        newLHead = l2
        newLHead?.next = mergeTwoLists(l1, l2.next)
    }

    return newLHead
}
