//
//  33二叉搜索树的后续遍历序列.swift
//  Algorithm
//
//  Created by HuangBin Ye on 2020/10/29.
//  Copyright © 2020 SimonYe. All rights reserved.
//

import Foundation


/*
 输入一个整数数组，判断该数组是不是某二叉搜索树的后序遍历结果。如果是则返回 true，否则返回 false。假设输入的数组的任意两个数字都互不相同。
 
   
 
 参考以下这颗二叉搜索树：
 
 5
 / \
 2   6
 / \
 1   3
 示例 1：
 
 输入: [1,6,3,2,5]
 输出: false
 示例 2：
 
 输入: [1,3,2,6,5]
 输出: true
 
 */

/*
 思路：利用二叉搜索树的特征进行判断，左子节点小于父节点，右子节点大于父节点。由于是后续遍历，则可知父节点在序列的末尾，按顺序将比对序列和父节点的大小，找出第一个比父节点大的数，即为右子节点，如果右子节点都满足比父节点大，则符合条件。
 */
func verifyPostorder(_ postorder: [Int]) -> Bool {
    if postorder.count <= 1 { return true}
    let root = postorder.last!
    var index = 0
    var lefts = [Int]()
    var rights = [Int]()
    // 确定左子树节点
    for i in 0..<postorder.count-1 {
        if postorder[i] < root{
            lefts.append(postorder[i])
        } else {
            index = i
            break
        }
    }
    // 全部加入到了左子节点
    if lefts.count == postorder.count-1 {
        return verifyPostorder(lefts)
    }
    // 判断剩余节点是否符合右子树节点的条件
    for j in index..<postorder.count-1 {
        if postorder[j] >= root {
            rights.append(postorder[j])
        } else {
            return false
        }
        
    }
    return verifyPostorder(lefts) && verifyPostorder(rights)
}
