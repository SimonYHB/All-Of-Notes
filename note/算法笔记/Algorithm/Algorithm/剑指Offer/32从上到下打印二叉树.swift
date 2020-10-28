//
//  32从上到下打印二叉树.swift
//  Algorithm
//
//  Created by HuangBin Ye on 2020/10/28.
//  Copyright © 2020 SimonYe. All rights reserved.
//

import Foundation

/*
 从上到下打印出二叉树的每个节点，同一层的节点按照从左到右的顺序打印。
 
   
 
 例如:
 给定二叉树: [3,9,20,null,null,15,7],
 
 3
 / \
 9  20
 /  \
 15   7
 返回：
 
 [3,9,20,15,7]
   
 
 提示：
 
 节点总数 <= 1000
 
 */

/*
 思路：从根节点开始，依次将节点将加入数组中，从头开始访问，访问时将节点的左右节点加入到该数组中，当节点数组清空时则表示遍历完了所有节点
 */
func levelOrder1(_ root: TreeNode?) -> [Int] {
    var nodeArr = [TreeNode]()
    var valArr = [Int]()
    if root != nil {
        nodeArr.append(root!)
    }
    while nodeArr.count != 0 {
        let node = nodeArr.removeFirst()
        valArr.append(node.val)
        if let leftNode = node.left {
            nodeArr.append(leftNode)
        }
        if let rightNode = node.right {
            nodeArr.append(rightNode)
        }
    }
    
    return valArr
}


/*
 从上到下按层打印二叉树，同一层的节点按从左到右的顺序打印，每一层打印到一行。
 思路：有变量来记录当前层级和下一个层级的节点数量
 */

func levelOrder2(_ root: TreeNode?) -> [[Int]] {
    var nodeArr = [TreeNode]()
    var valArr = [[Int]]()
    var printCount = 0
    var nextPrintCount = 0
    if root != nil {
        nodeArr.append(root!)
        printCount = 1
    }
    var levelArr = [Int]()
    while nodeArr.count != 0 {
        let node = nodeArr.removeFirst()
        if let leftNode = node.left {
            nodeArr.append(leftNode)
            nextPrintCount += 1
        }
        if let rightNode = node.right {
            nodeArr.append(rightNode)
            nextPrintCount += 1
        }
        levelArr.append(node.val)
        // 为0说明到了下一层级
        printCount -= 1
        if printCount == 0 {
            printCount = nextPrintCount
            valArr.append(levelArr)
            levelArr = []
            nextPrintCount = 0
        }
    }
    
    return valArr
}

/*
 请实现一个函数按照之字形顺序打印二叉树，即第一行按照从左到右的顺序打印，第二层按照从右到左的顺序打印，第三行再按照从左到右的顺序打印，其他行以此类推。
 思路：按照正常顺序层层遍历，增加一个bool来判断每层的val值是否需要反转
 */


func levelOrder(_ root: TreeNode?) -> [[Int]] {
    var nodeArr = [TreeNode]()
    var valArr = [[Int]]()
    var printCount = 0
    var nextPrintCount = 0
    if root != nil {
        nodeArr.append(root!)
        printCount = 1
    }
    var levelArr = [Int]()
    var revered = false
    while nodeArr.count != 0 {
        let node = nodeArr.removeFirst()
        if let leftNode = node.left {
            nodeArr.append(leftNode)
            nextPrintCount += 1
        }
        if let rightNode = node.right {
            nodeArr.append(rightNode)
            nextPrintCount += 1
        }
        levelArr.append(node.val)
        // 为0说明到了下一层级
        printCount -= 1
        if printCount == 0 {
            valArr.append(revered == true ? levelArr.reversed() : levelArr)
            levelArr = []
            printCount = nextPrintCount
            nextPrintCount = 0
            revered = !revered
        }
    }
    
    return valArr
}
