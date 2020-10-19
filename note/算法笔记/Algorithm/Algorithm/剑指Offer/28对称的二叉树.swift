//
//  28对称的二叉树.swift
//  Algorithm
//
//  Created by SimonYHB on 2020/10/19.
//  Copyright © 2020 SimonYe. All rights reserved.
//

import Foundation

/*
 请实现一个函数，用来判断一棵二叉树是不是对称的。如果一棵二叉树和它的镜像一样，那么它是对称的。

 例如，二叉树 [1,2,2,3,4,4,3] 是对称的。

     1
    / \
   2   2
  / \ / \
 3  4 4  3
 但是下面这个 [1,2,2,null,3,null,3] 则不是镜像对称的:

     1
    / \
   2   2
    \   \
    3    3

  

 示例 1：

 输入：root = [1,2,2,3,4,4,3]
 输出：true
 示例 2：

 输入：root = [1,2,2,null,3,null,3]
 输出：false
  

 限制：

 0 <= 节点个数 <= 1000
 */

/*
 递归判断两个节点的左右节点是否对称
 */
func isSymmetric(_ root: TreeNode?) -> Bool {
    if root?.left?.val == root?.right?.val {
        return isSymmetric2(root?.left, root?.right)
    }
    return false
}

func isSymmetric2(_ node1: TreeNode?, _ node2: TreeNode?) -> Bool {

    if node1?.left?.val == node2?.right?.val && node1?.right?.val == node2?.left?.val {
        if node1?.left != nil && node1?.right != nil {
            
            return isSymmetric2(node1?.left, node2?.right) && isSymmetric2(node1?.right, node2?.left)
        }
        if node1?.left == nil && node1?.right != nil {
            return isSymmetric2(node1?.right, node2?.left)
        }
        if node1?.left != nil && node1?.right == nil {
            return isSymmetric2(node1?.left, node2?.right)
        }
        return true
    }
    return false
    
}
