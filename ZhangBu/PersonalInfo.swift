//
//  PersonalInfo.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/12.
//

import Foundation

// 多人共享，可以知道目前是哪一位
struct PersonalInfo {
    var name: String
    var createDate: Date
    
    mutating func modify(with newName: String) {
        self.name = newName
    }
}

