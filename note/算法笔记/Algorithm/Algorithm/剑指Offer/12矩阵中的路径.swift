//
//  12矩阵中的路径.swift
//  Algorithm
//
//  Created by SimonYHB on 2020/9/17.
//  Copyright © 2020 SimonYe. All rights reserved.
//
/*
 请设计一个函数，用来判断在一个矩阵中是否存在一条包含某字符串所有字符的路径。路径可以从矩阵中的任意一格开始，每一步可以在矩阵中向左、右、上、下移动一格。如果一条路径经过了矩阵的某一格，那么该路径不能再次进入该格子。例如，在下面的3×4的矩阵中包含一条字符串“bfce”的路径（路径中的字母用加粗标出）。

 [["a","b","c","e"],
 ["s","f","c","s"],
 ["a","d","e","e"]]

 但矩阵中不包含字符串“abfb”的路径，因为字符串的第一个字符b占据了矩阵中的第一行第二个格子之后，路径不能再次进入这个格子。

  

 示例 1：

 输入：board = [["A","B","C","E"],["S","F","C","S"],["A","D","E","E"]], word = "ABCCED"
 输出：true
 示例 2：

 输入：board = [["a","b"],["c","d"]], word = "abcd"
 输出：false
 提示：

 1 <= board.length <= 200
 1 <= board[i].length <= 200


 
 */
import Foundation

/*
 DFS(回溯算法)
 思路：假设当前位置为(row,col),则下一步为 (row,col-1)、(row,col+1)、(row-1,col)、(row+1、col)，访问所有路径比对与目标字符是否相同
 另外走过的格子不能再走，所以需要一个大小相同的数组来记录每个格子是否走过
 */
func exist(_ board: [[Character]], _ word: String) -> Bool {
    if (board.count <= 0 || board[0].count <= 0) {
        return false
    }
    // 可以以任意位置开始，所以列出所有元素
    let rows = board.count
    let cols = board[0].count
    var visited = Array(repeating: Array(repeating: false, count: board[0].count), count: board.count)
    let words = Array(word)
    for i in 0..<rows {
        for j in 0..<cols {
            
            if (exist_dfs(board, words, &visited, rows, cols, i, j, 0)) {
                return true
            }
        }
    }

    return false
}

func exist_dfs(_ borad: [[Character]], _ words: [Character],_ visit: inout [[Bool]],_ rows: Int,_ cols: Int,_ row: Int,_ col: Int,_ index: Int) -> Bool {
    // 1.要比较的字符位置超过了字符串的长度，则说明已全部命中，返回true
    if (index >= words.count) {
        return true
    }
    // 2.数据越界则返回false
    if row >= rows || col >= cols || row < 0 || col < 0 {
        return false
    }
    // 3.当前位置已被访问过则不能再访问，返回false
    if visit[row][col] {
        return false
    }
    // 4.当前位置的字符与目标字符不相同，返回false
    if words[index] != borad[row][col] {
        return false
    }
    
    //5.当前位置相同，则往4个方向比较下一个字符
    visit[row][col] = true
    let nextIndex = index + 1
    if (exist_dfs(borad, words, &visit, rows, cols, row+1, col, nextIndex)
        || exist_dfs(borad, words, &visit, rows, cols, row-1, col, nextIndex)
        || exist_dfs(borad, words, &visit, rows, cols, row, col+1, nextIndex)
        || exist_dfs(borad, words, &visit, rows, cols, row, col-1, nextIndex)) {
            return true
    }
    // 6.如果后面没有命中，则说明此条路径不符合，将visit重置为没访问过
    visit[row][col] = false
    return false
}




