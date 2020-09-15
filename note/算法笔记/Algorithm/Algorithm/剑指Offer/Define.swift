//
//  Define.swift
//  Algorithm
//
//  Created by SimonYHB on 2020/9/13.
//  Copyright © 2020 叶煌斌. All rights reserved.
//

import Foundation

// 单链表的节点
public class ListNode {
    public var val: Int
    public var next: ListNode?
    public init(_ val: Int) {
        self.val = val
        self.next = nil
    }
}

// 二叉树节点
public class TreeNode {
    public var val: Int
    public var left: TreeNode?
    public var right: TreeNode?
    public init(_ val: Int) {
        self.val = val
        self.left = nil
        self.right = nil
    }
}
