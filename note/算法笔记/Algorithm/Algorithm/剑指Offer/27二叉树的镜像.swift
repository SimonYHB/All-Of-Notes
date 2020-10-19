//
//  27二叉树的镜像.swift
//  Algorithm
//
//  Created by SimonYHB on 2020/10/19.
//  Copyright © 2020 SimonYe. All rights reserved.
//

import Foundation

/*
 请完成一个函数，输入一个二叉树，该函数输出它的镜像。

 例如输入：

      4
    /   \
   2     7
  / \   / \
 1   3 6   9
 镜像输出：

      4
    /   \
   7     2
  / \   / \
 9   6 3   1

  

 示例 1：

 输入：root = [4,2,7,1,3,6,9]
 输出：[4,7,2,9,6,3,1]
  

 限制：

 0 <= 节点个数 <= 1000

 */

/*
 思路：递归交换左右子节点
 */
func mirrorTree(_ root: TreeNode?) -> TreeNode? {
    if root == nil { return nil}
    if root?.left == nil && root?.right == nil {
        return root
    }
    let temp = root?.left
    root?.left = mirrorTree(root?.right)
    root?.right = mirrorTree(temp)
    return root
}
