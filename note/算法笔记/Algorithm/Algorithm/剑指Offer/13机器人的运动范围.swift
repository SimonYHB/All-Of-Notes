//
//  13机器人的运动范围.swift
//  Algorithm
//
//  Created by SimonYHB on 2020/9/17.
//  Copyright © 2020 叶煌斌. All rights reserved.
//
/*
 地上有一个m行n列的方格，从坐标 [0,0] 到坐标 [m-1,n-1] 。一个机器人从坐标 [0, 0] 的格子开始移动，它每次可以向左、右、上、下移动一格（不能移动到方格外），也不能进入行坐标和列坐标的数位之和大于k的格子。例如，当k为18时，机器人能够进入方格 [35, 37] ，因为3+5+3+7=18。但它不能进入方格 [35, 38]，因为3+5+3+8=19。请问该机器人能够到达多少个格子？

  

 示例 1：

 输入：m = 2, n = 3, k = 1
 输出：3
 示例 2：

 输入：m = 3, n = 1, k = 0
 输出：1
 提示：

 1 <= n,m <= 100
 0 <= k <= 20

 
 */
import Foundation
/*
 思路1：与12矩阵中的路径解法类似，使用dfs，列出所有方向的可能值，并使用备忘录记录走过的值
 也可以采用BFS广度优先搜索，先从行开始+1直到不满足要求，再从列开始
 */
func movingCount(_ m: Int, _ n: Int, _ k: Int) -> Int {
    var visited = Array(repeating: Array(repeating: false, count: n), count: m)
    let count = movingCount_dfs(m, n, k, 0, 0, &visited)
    return count
}



func movingCount_dfs(_ m: Int, _ n: Int, _ k: Int, _ row: Int, _ col: Int, _ visited: inout [[Bool]]) -> Int {
    var count = 0
    /*
     判断条件：
     1. 未越界
     2. 未访问过
     3. 满足相加小于等于k
     */
    if (row < m && row >= 0 && col < n && col >= 0
        && !visited[row][col]
        && numCharSum(row) + numCharSum(col) <= k) {
        visited[row][col] = true
        count = 1 + movingCount_dfs(m, n, k, row+1, col, &visited)
            + movingCount_dfs(m, n, k, row-1, col, &visited)
            + movingCount_dfs(m, n, k, row, col+1, &visited)
            + movingCount_dfs(m, n, k, row, col-1, &visited)
    }

    
    return count
}


func numCharSum(_ num:Int) -> Int {
    var sum = 0
    var num = num
    while num > 0 {
        sum += num % 10
        num = num/10
    }
    return sum
}

