//
//  22链表中倒数第k个节点  .swift
//  Algorithm
//
//  Created by SimonYHB on 2020/9/27.
//  Copyright © 2020 SimonYe. All rights reserved.
//

import Foundation

/*
 输入一个链表，输出该链表中倒数第k个节点。为了符合大多数人的习惯，本题从1开始计数，即链表的尾节点是倒数第1个节点。例如，一个链表有6个节点，从头节点开始，它们的值依次是1、2、3、4、5、6。这个链表的倒数第3个节点是值为4的节点。

  

 示例：

 给定一个链表: 1->2->3->4->5, 和 k = 2.

 返回链表 4->5.

 */

/*
 思路：采用双指针，先让第一个指针向前走k-1步，保持两个指针之前的距离为k-1，接着两个指针一起走，直到第一个指针到达尾巴，此时第二个指针的位置就是倒数第k个节点
 */
func getKthFromEnd(_ head: ListNode?, _ k: Int) -> ListNode? {
    if head == nil || k == 0 {
         return nil
    }
    var first = head
    var second = head
    for _ in 1..<k {
        first = first?.next
        if first == nil {
            // 说明节点总数小于k
            return nil
        }
    }
    while first?.next != nil {
        first = first?.next
        second = second?.next
    }
    
    return second
}
