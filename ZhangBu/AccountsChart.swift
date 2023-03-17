//
//  NewBarView.swift
//  DemoForSharingRecord
//
//  Created by Jcwang on 2023/2/27.
//

// 自定义实现图表，以及Swift官方图表库使用案例
// https://blog.logrocket.com/building-custom-charts-swiftui/

import SwiftUI
import Charts

@available(iOS 16, *)
struct AccountsChart: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DayAccount.date, ascending: false)],
        animation: .default)
    var dayAccounts: FetchedResults<DayAccount>
    
    @State var showItemEditOrBar: Bool = true
    
    var segmentationSelection: SegmentationEnum
    var currentSelectedDate: Date
    
    var processedDayAccounts: [String: [Date: DayAccount]]
    var yearCosts: [Int: [String: [String: Double]]]
    
//    @State var selectedItemName: String?
//    @State var selectedDayAccount: DayAccount?
    
    @State var selectedDate: Date?
    
    var weekCost: Double {
        var weekCost = 0.0
        
        if let proDayAccounts = processedDayAccounts[StaticProperty.MySelfName] {
            for (date, dayAccount) in proDayAccounts {
                if date.isInSameWeek(as: currentSelectedDate) {
                    weekCost += dayAccount.wrappedRecords.map( {$0.price} ).reduce(0.0, +)
                }
            }
        }
        
        return weekCost
    }
    
    
    init(segmentationSelection: SegmentationEnum, currentSelectedDate: Date, selectedItemName: String? = nil, processedDayAccounts: [String: [Date: DayAccount]], yearCosts: [Int: [String: [String: Double]]]) {
        self.segmentationSelection = segmentationSelection
        self.currentSelectedDate = currentSelectedDate

        self.processedDayAccounts = processedDayAccounts
        self.yearCosts = yearCosts
    }
    
    var gradients: [String: LinearGradient] {
        var gradients = [String: LinearGradient]()
        for (index, name) in processedDayAccounts.keys.sorted(by: {$0 < $1}).enumerated() {
            if name == StaticProperty.MySelfName {
                gradients[name] = LinearGradient(gradient: Gradient(colors: [Color.accentColor.opacity(0.7), Color.accentColor.opacity(0.75)]), startPoint: .top, endPoint: .bottom)
            } else {
                switch index % 2 {
                case 0: gradients[name] = LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .top, endPoint: .bottom)
                default: gradients[name] = LinearGradient(gradient: Gradient(colors: [.green, .yellow]), startPoint: .top, endPoint: .bottom)
                }
            }
        }
        
        return gradients
    }
    
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            switch segmentationSelection {
            case .daySeg:
                if let tempDayAccount = processedDayAccounts[StaticProperty.MySelfName]?[currentSelectedDate] {
                    Text("日消费：¥\(tempDayAccount.wrappedRecords.map( {$0.price} ).reduce(0.0, +), specifier: "%.2F")").bold()
                        .foregroundColor(.accentColor)

                    Chart {
                        ForEach(tempDayAccount.wrappedRecords, id: \.id) { record in
                            BarMark(x: .value("item", record.wrappedItem), y: .value("price", record.price))
                                .annotation {
                                    Text("\(record.price, specifier: "%.2F")")
                                        .font(.footnote)
                                }
                                .foregroundStyle(gradients[StaticProperty.MySelfName]!)
                                .foregroundStyle(by:.value("item", StaticProperty.MySelfName))
                        }
//                        if let selectedItemName = selectedItemName {
//                            RuleMark(x: .value("Selected item", selectedItemName))
//                                .annotation(position: .top, alignment: .top) {
//                                    VStack {
//                                        Text("\(tempDayAccount.records[selectedItemName] ?? 0.0, specifier: "%.2F")")
//                                    }
//                                }
//                        }
                    }
//                    .chartForegroundStyleScale([StaticProperty.MySelfName: Color.accentColor])  // 这个是控制legend的图表颜色的
                    .chartLegend(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading) {
                            AxisGridLine(centered: false, stroke: StrokeStyle(dash: [2.5])).foregroundStyle(Color.accentColor)
                            AxisValueLabel()
                        }
                    }
                    .chartXAxis {
                        AxisMarks {
                            AxisGridLine(centered: false, stroke: StrokeStyle(dash: [2.5])).foregroundStyle(Color.accentColor)
                            AxisValueLabel()
                        }
                    }
                } else {
                    Text("日消费：¥0.00").bold()
                        .foregroundColor(.accentColor)
                }

            case .weekSeg:
                Text("第\(currentSelectedDate.weekInMonth)周消费：¥\(weekCost, specifier: "%.2F")").bold()
                    .foregroundColor(.accentColor)

                Chart(processedDayAccounts.sorted(by: {$0.key < $1.key}), id: \.key) { data in // key是名字
                    // 此处小于号表示图表中从左到右时间越来越大
                    ForEach(data.value.sorted(by: {$0.key < $1.key}), id: \.key) { dateAndDayAccount in // key是时间
                        // 每一天的消费都是一个bar
                        if currentSelectedDate.isInSameWeek(as: dateAndDayAccount.key) {
                            let cost = dateAndDayAccount.value.wrappedRecords.map( {$0.price} ).reduce(0.0, +)
                            LineMark(x: .value("Account Day", dateAndDayAccount.key, unit: .day), y: .value("Value", cost))
                                .annotation {
                                    Text("\(cost, specifier: "%.2F")")
                                        .font(.footnote)
                                }
                                .symbol(by: .value("Account Day",  data.key))
                                .symbolSize(dateAndDayAccount.key.isInSameDay(as: currentSelectedDate) ? 250 : 100)
                                .interpolationMethod(.catmullRom)
    //                            .foregroundStyle(gradients[StaticProperty.MySelfName]!)
    //                            .foregroundStyle(Color.accentColor)
                                .foregroundStyle(by:.value("Name", StaticProperty.MySelfName))
                                
                            AreaMark(
                                x: .value("Account Day",  dateAndDayAccount.key, unit: .day),
                                y: .value("Value", cost)
                            )
                                .interpolationMethod(.catmullRom)
                                // 先颜色，再foregroundStyle(by:.value这个颜色才有效，不然被下面的chartForegroundStyleScale覆盖。
                                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.accentColor.opacity(0.1), Color.accentColor.opacity(0.2)]), startPoint: .top, endPoint: .bottom))
                                .foregroundStyle(by:.value("Name", StaticProperty.MySelfName))
                        }
                    }
                }
                .chartForegroundStyleScale([StaticProperty.MySelfName: Color.accentColor])  // 这个是控制legend的图表颜色的
//                .chartLegend(position: .overlay, alignment: .top)
//                .chartPlotStyle { plotArea in
//                    plotArea
//                        .background(LinearGradient(gradient: Gradient(colors: [Color.accentColor, .red]), startPoint: .top, endPoint: .bottom))
//                }
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisGridLine(centered: false, stroke: StrokeStyle(dash: [2.5]))
                            .foregroundStyle(Color.accentColor)
                        AxisValueLabel()
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine(centered: false, stroke: StrokeStyle(dash: [2.5]))
                            .foregroundStyle(Color.accentColor)
                        AxisTick(centered: false, stroke: StrokeStyle(lineWidth: 3))
                            .foregroundStyle(Color.accentColor)
                        AxisValueLabel(format: .dateTime.day().weekday(), centered: true)
                    }
                }
            case .monthSeg:
                let currentMonthCost = yearCosts[currentSelectedDate.year]?[StaticProperty.MySelfName]?[String(currentSelectedDate.monthInYear)] ?? 0.0

                Text("月消费：¥\(currentMonthCost, specifier: "%.2F")").bold()
                    .foregroundColor(.accentColor)

                Chart(processedDayAccounts.sorted(by: {$0.key < $1.key}), id: \.key) { data in
                    // 此处小于号表示图表中从左到右时间越来越大
                    ForEach(data.value.sorted(by: {$0.key < $1.key}), id: \.key) { dateAndDayAccount in

                        // 每一天的消费都是一个bar
                        if currentSelectedDate.isInSameMonth(as: dateAndDayAccount.key) {
                            let cost = dateAndDayAccount.value.wrappedRecords.map( {$0.price} ).reduce(0.0, +)
                            
                            LineMark(x: .value("Account Day", dateAndDayAccount.key, unit: .day), y: .value("Value", cost))
                                .symbol(by: .value("Account Day",  data.key))
                                .symbolSize(currentSelectedDate.isInSameDay(as: dateAndDayAccount.key) ? 250 : 100)
//                                .interpolationMethod(.catmullRom)
//                                .foregroundStyle(gradients[StaticProperty.MySelfName]!)
//                                .foregroundStyle(Color.accentColor)
                                .foregroundStyle(by:.value("Name", StaticProperty.MySelfName))
                            
                            if let selectedDate = selectedDate, selectedDate.isInSameDay(as: dateAndDayAccount.key) {
                                RuleMark(x: .value("Account Day", dateAndDayAccount.key, unit: .day))
                                    .foregroundStyle(Color.accentColor.opacity(0.5))

                                PointMark(x: .value("Account Day", dateAndDayAccount.key, unit: .day), y: .value("Value", cost))
                                    .symbolSize(100)
                                    .foregroundStyle(Color.accentColor)
                                    .annotation(position: .bottom, alignment: .bottom) {
                                        Text("\(cost, specifier: "%.2F")")
                                            .font(.footnote)
                                    }
                                    
                            }
                        }
                    }
                }
                .chartForegroundStyleScale([StaticProperty.MySelfName: Color.accentColor])  // 这个是控制legend的图表颜色的
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisGridLine(centered: false, stroke: StrokeStyle(dash: [2.5])).foregroundStyle(Color.accentColor)
                        AxisValueLabel()
                    }
                }
                .chartXAxis {
//                    AxisMarks(values: .stride(by: .day)) { value in
//                        if value.as(Date.self)!.isFirstDayOfWeek {
//                            AxisGridLine(centered: false, stroke: StrokeStyle(dash: [2.5])).foregroundStyle(Color.accentColor)
//                            AxisValueLabel(format: .dateTime.day(), centered: true)
//                        }
//                    }
                    
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine(centered: false, stroke: StrokeStyle(dash: [2.5]))
                            .foregroundStyle(Color.accentColor)
                        AxisValueLabel(format: .dateTime.day(), centered: true)
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())

                            .onTapGesture { location in
                                let currentX = location.x - geometry[proxy.plotAreaFrame].origin.x
                                guard currentX >= 0, currentX < proxy.plotAreaSize.width else {
                                    return
                                }

                                guard let selectedDate: Date = proxy.value(atX: currentX, as: Date.self) else {
                                    
                                    return
                                }
                                
                                self.selectedDate = selectedDate
                            }
                            .gesture(
                                DragGesture()
                                    .onChanged({ value in
                                        let currentX = value.location.x - geometry[proxy.plotAreaFrame].origin.x
                                        guard currentX >= 0, currentX < proxy.plotAreaSize.width else {
                                            return
                                        }
                                        guard let selectedDate: Date = proxy.value(atX: currentX, as: Date.self) else {
                                            
                                            return
                                        }
                                        
                                        self.selectedDate = selectedDate
                                    })
                                    .onEnded({ _ in
                                        self.selectedDate = nil
                                    })
                            )
                    }
                }

            case .yearSeg:
                let currentYearCost = yearCosts[currentSelectedDate.year] ?? [String: [String: Double]]()

                Text("年消费：¥\(currentYearCost[StaticProperty.MySelfName]?.values.reduce(0.0, +) ?? 0.0, specifier: "%.2F")").bold()
                    .foregroundColor(.accentColor)

                Chart(currentYearCost.sorted(by: {$0.key < $1.key}), id: \.key) { yearCostsValue in // key是名字
                    // 此处小于号表示图表中从左到右时间越来越大
                    ForEach(yearCostsValue.value.sorted(by: {$0.key < $1.key}), id: \.key) { monthAndDayAccount in // key是月
                        // 每一年的消费都是一个bar
                        LineMark(x: .value("Account Month", monthAndDayAccount.key), y: .value("Value", monthAndDayAccount.value))
                            .annotation {
                                Text("\(monthAndDayAccount.value, specifier: "%.2F")")
                                    .font(.footnote)
                            }
                            .symbol(by: .value("Account Day",  yearCostsValue.key))
//                            .symbol() {
//                                Circle()
//                                    .fill(.red)
//                                    .frame(width: 10)
//                            }
                            .symbolSize((Int(monthAndDayAccount.key)! == currentSelectedDate.monthInYear) ? 250 : 100)
                            .interpolationMethod(.catmullRom)
//                            .foregroundStyle(gradients[StaticProperty.MySelfName]!)
//                            .foregroundStyle(Color.accentColor)
                            .foregroundStyle(by:.value("Name", StaticProperty.MySelfName))
                    }
                }
                .chartForegroundStyleScale([StaticProperty.MySelfName: Color.accentColor])  // 这个是控制legend的图表颜色的
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisGridLine(centered: false, stroke: StrokeStyle(dash: [2.5])).foregroundStyle(Color.accentColor)
                        AxisValueLabel()
                    }
                }
                .chartXAxis {
                    AxisMarks { value in

                        AxisGridLine(centered: false, stroke: StrokeStyle(dash: [2.5]))
                            .foregroundStyle(Color.accentColor)
                        AxisTick(centered: false, stroke: StrokeStyle(lineWidth: 3))
                            .foregroundStyle(Color.accentColor)
                        AxisValueLabel {
                            if let month = value.as(String.self) {
                                Text(month)
                            }
                        }
                    }
                }

            }
        }
    }
}
