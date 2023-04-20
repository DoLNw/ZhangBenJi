//
//  SomeClass.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/22.
//

import Foundation
import SwiftUI

// 设置的一些彩蛋
var supriseString = ["诚妈": "周林芬", "忠忠": "王建忠", "王嘉诚": "王嘉诚", "杰哥": "沈杰", "翔哥": "王瀚翔", "苏航": "苏航", "VIGA": "王佳维", "陈胜": "陈胜", "WTT": "王婷婷", "张姐": "张婉卿", "都哥": "季建都", "新程": "沈新程", "么哥": "幺寒旭"]


// 未解锁人脸时，遮挡的View需要用这两个参数
var fullWidth: CGFloat = UIScreen.main.bounds.width
var fullHeight: CGFloat = UIScreen.main.bounds.height


// 给选择日、周、月、年使用。在ListAndChart中使用
enum SegmentationEnum: String, CaseIterable {
    case daySeg = "日"
    case weekSeg = "周"
    case monthSeg = "月"
    case yearSeg = "年"
}


// 当前键盘是在金额，还是物品名称键盘上，在AddDayAccountView和AccountList中使用
enum FocusedField {
    case itemField, amountField
}


// 当前是List，还是图表界面，在ContentView界面中使用
enum ShowingView: String, Codable, CaseIterable {
    case accountsList, accountsChart
    
    mutating func toggle() {
        switch self {
        case .accountsList:
            self = .accountsChart
        case .accountsChart:
            self = .accountsList
        }
    }
}

struct MonthCostAndIncome {
    var cost: Double
    var income: Double
}

