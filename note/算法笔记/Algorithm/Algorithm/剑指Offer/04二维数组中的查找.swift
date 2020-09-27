//
//  04二维数组中的查找.swift
//  Algorithm
//
//  Created by SimonYHB on 2020/9/12.
//  Copyright © 2020 SimonYe. All rights reserved.
//
/*
 在一个 n * m 的二维数组中，每一行都按照从左到右递增的顺序排序，每一列都按照从上到下递增的顺序排序。请完成一个函数，输入这样的一个二维数组和一个整数，判断数组中是否含有该整数。

 
 示例:

 现有矩阵 matrix 如下：

 [
   [1,   4,  7, 11, 15],
   [2,   5,  8, 12, 19],
   [3,   6,  9, 16, 22],
   [10, 13, 14, 17, 24],
   [18, 21, 23, 26, 30]
 ]
 给定 target = 5，返回 true。

 给定 target = 20，返回 false。

  

 限制：

 0 <= n <= 1000

 0 <= m <= 1000



 来源：力扣（LeetCode）
 链接：https://leetcode-cn.com/problems/er-wei-shu-zu-zhong-de-cha-zhao-lcof
 著作权归领扣网络所有。商业转载请联系官方授权，非商业转载请注明出处。
 
 
 */
import Foundation

/*
 思路1： 由于从左到右递增，从上到下递增，所以先比较大小，判断在哪一列，再判断哪一行
 */

func findNumberIn2DArray(_ matrix: [[Int]], _ target: Int) -> Bool {
    var result = false
    if matrix.count > 0 {
        //判断输入数据是否合规
        let maxColumns = matrix[0].count
        for row in matrix {
            if maxColumns != row.count {
                return result
            }
        }
        //列和行的查找
        var rowIndex = 0, columnIndex = maxColumns - 1
          while rowIndex < matrix.count && columnIndex >= 0 {
              let object = matrix[rowIndex][columnIndex]
              if object == target {
                  result = true
                  break
              } else if object > target {
                  columnIndex = columnIndex - 1
              } else {
                  rowIndex = rowIndex + 1
              }
          }
    }
    
  
  
    return result
}


/*
思路2： 直接使用Swift的高阶函数
*/

func findNumberIn2DArray_v2(_ matrix: [[Int]], _ target: Int) -> Bool {
     return matrix.flatMap({$0}).contains(target)
}

