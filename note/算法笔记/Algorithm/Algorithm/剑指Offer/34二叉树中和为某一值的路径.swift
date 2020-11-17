//
//  34二叉树中和为某一值的路径.swift
//  Algorithm
//
//  Created by HuangBin Ye on 2020/11/17.
//  Copyright © 2020 SimonYe. All rights reserved.
//

import Foundation

/*
 输入一棵二叉树和一个整数，打印出二叉树中节点值的和为输入整数的所有路径。从树的根节点开始往下一直到叶节点所经过的节点形成一条路径。

  

 示例:
 给定如下二叉树，以及目标和 sum = 22，

               5
              / \
             4   8
            /   / \
           11  13  4
          /  \    / \
         7    2  5   1
 返回:

 [
    [5,4,11,2],
    [5,8,4,5]
 ]
 */

/*
 思路： 递归添加节点，当时子节点且累加到目标值时加入路径
 */
func pathSum(_ root: TreeNode?, _ sum: Int) -> [[Int]] {
    var results = [[Int]]()
    var path = [Int]()
    pathSum_recur(root, sum, &path, &results)
    return results
}

func pathSum_recur(_ root: TreeNode?, _ remain: Int, _ path: inout [Int], _ result: inout [[Int]]) {
    guard let rootValue = root?.val else { return }
    path.append(rootValue)
    let res = remain - rootValue
    if res == 0 && root?.left == nil && root?.right == nil  {
       result.append(path)
    } else {
       pathSum_recur(root?.left, res, &path, &result)
       pathSum_recur(root?.right, res, &path, &result)
    }
    
    path.removeLast()
}
