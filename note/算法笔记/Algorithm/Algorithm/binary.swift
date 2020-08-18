//
//  binary.swift
//  Algorithm
//
//  Created by HuangBin Ye on 2020/8/18.
//  Copyright © 2020 叶煌斌. All rights reserved.
//

import Foundation




// 二分查找
func binary_search(nums: [Int], target: Int) -> Int {
    var left = 0, right = nums.count - 1
    while left <= right {
        let mid = left + (right - left) / 2
        let midValue = nums[mid]
        if midValue == target {
            return mid
        } else if midValue < target {
            left = mid + 1
        } else if midValue > target {
            right = mid - 1
        }
    }
    return -1;
}

// 左侧边界
func left_bound(nums: [Int], target: Int) -> Int {
    var left = 0, right = nums.count - 1
    while left <= right {
        let mid = left + (right - left) / 2
        let midValue = nums[mid]
        if midValue == target {
            left = mid + 1
        } else if midValue < target {
            left = mid + 1
        } else if midValue > target {
            right = mid - 1
        }
    }
    // 越界处理
    if left >= nums.count || nums[left] != target {
        return -1
    }
    return left;
}


// 右侧边界
func right_bound(nums: [Int], target: Int) -> Int {
    var left = 0, right = nums.count - 1
    while left <= right {
        let mid = left + (right - left) / 2
        let midValue = nums[mid]
        if midValue == target {
            left = mid + 1
        } else if midValue < target {
            left = mid + 1
        } else if midValue > target {
            right = mid - 1
        }
    }
    if right < 0 || nums[right] != target {
        return -1
    }
    return right;
}

