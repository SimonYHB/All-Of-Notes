//
//  07重建二叉树.swift
//  Algorithm
//
//  Created by SimonYHB on 2020/9/13.
//  Copyright © 2020 SimonYe. All rights reserved.
//
/*
 输入某二叉树的前序遍历和中序遍历的结果，请重建该二叉树。假设输入的前序遍历和中序遍历的结果中都不含重复的数字。

  

 例如，给出

 前序遍历 preorder = [3,9,20,15,7]
 中序遍历 inorder = [9,3,15,20,7]
 返回如下的二叉树：

     3
    / \
   9  20
     /  \
    15   7
  

 限制：

 0 <= 节点个数 <= 5000

 
 */
import Foundation
/**
 * Definition for a binary tree node.
 * public class TreeNode {
 *     public var val: Int
 *     public var left: TreeNode?
 *     public var right: TreeNode?
 *     public init(_ val: Int) {
 *         self.val = val
 *         self.left = nil
 *         self.right = nil
 *     }
 * }
 */


/*
 思路1：前序遍历的第一个节点为根节点，而中序遍历的根节点左边是左子树节点，右边是右子树节点，找到根节点在中序遍历中的位置，这样就能确定左子树和右子树的节点右哪些，接着通过递归方式层层往下构建
 */
func buildTree(_ preorder: [Int], _ inorder: [Int]) -> TreeNode? {
    if preorder.count == 0 || inorder.count == 0 {
        return nil
    }
    let root = TreeNode(preorder[0])
    for (index, element) in inorder.enumerated() {
        if element == preorder[0] {
            
            root.left = buildTree(Array(preorder[1..<index+1]), Array(inorder[0..<index]))
            
            root.right = buildTree(Array(preorder[index+1..<preorder.count]), Array(inorder[index+1..<inorder.count]))
        }
    }
    return root
}


/*
 思路2：优化中序遍历查找根节点的效率，递归for循环存在重复遍历，使用map缓存inorder中每个值的所在index，后续preorder中得到的根节点就可以通过map知道在inorder中的位置，省去了遍历操作（备忘录）
    空间复杂度也可以优化，不要每次都创建新的preorder和inorder，递归时只用原来的数据，通过传递开始结束位置来实现
 */
func buildTree_v2(_ preorder: [Int], _ inorder: [Int]) -> TreeNode? {
    if preorder.count == 0 || inorder.count == 0 {
        return nil
    }
    var map = [Int: Int]()
    for (index, element) in inorder.enumerated() {
        map[element] = index
    }
    return buildTree(preorder, inorder, map: map, preStart: 0, preEnd: preorder.count-1, inStart: 0, inEnd: inorder.count-1)
}

func buildTree(_ preorder: [Int], _ inorder: [Int], map: [Int: Int], preStart: Int, preEnd: Int, inStart: Int, inEnd: Int) -> TreeNode? {
    if (preStart > preEnd) {
        return nil
    }
    let root = TreeNode(preorder[preStart])
    guard let rootIndex = map[preorder[preStart]] else {
        return nil //异常
    }
    let leftNodeCount = rootIndex - inStart
    let rightnodeCount = inEnd - rootIndex
    root.left = buildTree(preorder, inorder, map: map, preStart: preStart+1, preEnd: preStart + leftNodeCount, inStart: inStart, inEnd: inStart + leftNodeCount - 1)
    root.right = buildTree(preorder, inorder, map: map, preStart: preEnd - rightnodeCount + 1, preEnd: preEnd, inStart: rootIndex + 1, inEnd: inEnd)
    return root
}

