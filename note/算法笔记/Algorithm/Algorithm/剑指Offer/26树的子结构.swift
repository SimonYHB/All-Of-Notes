//
//  26树的子结构.swift
//  Algorithm
//
//  Created by HuangBin Ye on 2020/10/16.
//  Copyright © 2020 SimonYe. All rights reserved.
//

import Foundation

/*
 输入两棵二叉树A和B，判断B是不是A的子结构。(约定空树不是任意一个树的子结构)
 
 B是A的子结构， 即 A中有出现和B相同的结构和节点值。
 
 例如:
 给定的树 A:
 
           3
         / \
       4   5
     / \
   1   2
 给定的树 B：
 
       4
     /
   1
 返回 true，因为 B 与 A 的一个子树拥有相同的结构和节点值。
 
 示例 1：
 
 输入：A = [1,2,3], B = [3,1]
 输出：false
 示例 2：
 
 输入：A = [3,4,5,1,2], B = [4,1]
 输出：true
 限制：
 
 0 <= 节点个数 <= 10000
 
 */


/*
 思路：先在A中找到B的头节点，接着遍历B的子节点是否存在于A
 */
func isSubStructure(_ A: TreeNode?, _ B: TreeNode?) -> Bool {
    if A == nil {
        return false
    }
    var result = false
    if A?.val == B?.val {
        // 命中头结点
        result = isEqualeSubNode(A, B)
    }
    if !result {
        result = isSubStructure(A?.left, B) || isSubStructure(A?.right, B)
    }
    return result
}

func isEqualeSubNode(_ nodeA: TreeNode?, _ nodeB: TreeNode?) -> Bool {
    if nodeB == nil {
        return true
    } else if nodeA == nil || nodeA?.val != nodeB?.val {
        return false
    } else {
        return isEqualeSubNode(nodeA?.left, nodeB?.left) && isEqualeSubNode(nodeA?.right, nodeB?.right)
    }
}
