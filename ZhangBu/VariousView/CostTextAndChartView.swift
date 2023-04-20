//
//  CostTextAndChartView.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/30.
//

import SwiftUI

struct CostTextAndChartView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    
    
    
    // 修改时，当前时间要变成那个record的时间。然后显示界面，显示currentSelectedDate相关日、周、月、年的相关金额
    let currentSelectedDate: Date
    
    
    // 选择，选择查看的是日、周、月、年
    var segmentationSelection: SegmentationEnum
    
    
    // 名字，日期，DayAccount
    var processedDayAccounts: [String: [Date: DayAccount]]
    // 年份，姓名，月份，该月份总和
    var yearCosts: [Int: [String: [String: MonthCostAndIncome]]]
    var weekCost: MonthCostAndIncome {
        var weekCost = MonthCostAndIncome(cost: 0.00, income: 0.00)
        
        if let proDayAccounts = processedDayAccounts[StaticProperty.MySelfName] {
            for (date, dayAccount) in proDayAccounts {
                if date.isInSameWeek(as: currentSelectedDate) {
                    weekCost.cost += dayAccount.wrappedRecords.filter({!$0.costOrIncome}).map( {$0.price} ).reduce(0.0, +)
                    weekCost.income += dayAccount.wrappedRecords.filter({$0.costOrIncome}).map( {$0.price} ).reduce(0.0, +)
                }
            }
        }
        
        return weekCost
    }
    
    
    // 显示标签图，用AppStorage没有动画了，还是不加了
//    @AppStorage(StaticProperty.USERDEFAULTS_SHOWPROPERTITY) var showTagPro = false
    @State var showTagPro = false
    @State var showEngelCoe = false
    
    
    var body: some View {
        VStack {
            HStack {
                switch segmentationSelection {
                case .daySeg:
                    if let tempDayAccount = processedDayAccounts[StaticProperty.MySelfName]?[currentSelectedDate] {
                        Text("日消费：¥\(tempDayAccount.wrappedRecords.filter({!$0.costOrIncome}).map( {$0.price} ).reduce(0.0, +), specifier: "%.2F")，收入：¥\(tempDayAccount.wrappedRecords.filter({$0.costOrIncome}).map( {$0.price} ).reduce(0.0, +), specifier: "%.2F")")
                            .bold()
                            .foregroundColor(.accentColor)
                    } else {
                        Text("日消费：¥0.00，收入¥0.00").bold()
                            .foregroundColor(.accentColor)
                    }
                
                case .weekSeg:
                    Text("第\(currentSelectedDate.weekInMonth)周消费：¥\(weekCost.cost, specifier: "%.2F")，收入：¥\(weekCost.income, specifier: "%.2F")").bold()
                        .foregroundColor(.accentColor)
                case .monthSeg:
                    let currentMonthCost = yearCosts[currentSelectedDate.year]?[StaticProperty.MySelfName]?[String(currentSelectedDate.monthInYear)]?.cost ?? 0.0
                    let currentMonthIncome = yearCosts[currentSelectedDate.year]?[StaticProperty.MySelfName]?[String(currentSelectedDate.monthInYear)]?.income ?? 0.0

                    Text("月消费：¥\(currentMonthCost, specifier: "%.2F")，收入：¥\(currentMonthIncome, specifier: "%.2F")").bold()
                        .foregroundColor(.accentColor)
                case .yearSeg:
                    let currentYearCost = yearCosts[currentSelectedDate.year] ?? [String: [String: MonthCostAndIncome]]()
                    
                    Text("年消费：¥\(currentYearCost[StaticProperty.MySelfName]?.values.map({$0.cost}).reduce(0.0, +) ?? 0.0, specifier: "%.2F")，收入：¥\(currentYearCost[StaticProperty.MySelfName]?.values.map({$0.income}).reduce(0.0, +) ?? 0.0, specifier: "%.2F")")
                        .bold()
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
                
                if entitlementManager.hasVariousChartsFunc {
                    if #available(iOS 16.0, *) {
                        Button {
                            withAnimation {
                                showTagPro.toggle()
                            }
                        } label: {
//                            if showTagPro {
//                                Label("", systemImage: "chart.pie.fill")
//                                    .font(.title2)
//                            } else {
//                                Label("", systemImage: "chart.pie")
//                                    .font(.title2)
//                            }
                            if showTagPro {
                                Label("", systemImage: "square.fill")
                                    .font(.title2)
                            } else {
                                Label("", systemImage: "square.tophalf.filled")
                                    .font(.title2)
                            }
                        }
                    }
                    
                    Button {
                        withAnimation {
                            showEngelCoe.toggle()
                        }
                    } label: {
                        if showEngelCoe {
                            Label("", systemImage: "circle.fill")
                                .font(.title2)
                        } else {
                            Label("", systemImage: "circle.tophalf.filled")
                                .font(.title2)
                        }
                    }
                }
            }
            .padding([.leading], 18)
            .padding([.trailing], 8)
            
            
            if #available(iOS 16.0, *) {
                if showTagPro {
                    OneDimensionalBar(currentSelectedDate: currentSelectedDate, currentSegment: segmentationSelection)
                }
            }
            
            if showEngelCoe {
                CircleProgressView(currentSelectedDate: currentSelectedDate, currentSegment: segmentationSelection)
            }
        }
    }
}
