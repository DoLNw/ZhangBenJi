//
//  NewBarView.swift
//  DemoForSharingRecord
//
//  Created by Jcwang on 2023/2/27.
//

// 自定义实现图表，以及Swift官方图表库使用案例
// https://blog.logrocket.com/building-custom-charts-swiftui/

// 此处表格，互动表格，柱状图，折线图等等都使用了


import SwiftUI
import Charts

//let incomeColor: Color = Color(hex: "FFB5AF")


@available(iOS 16, *)
struct AccountsChart: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    
    
    let selectedChangeGenerator = UISelectionFeedbackGenerator()
    
    
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DayAccount.date, ascending: false)],
        animation: .default)
    var dayAccounts: FetchedResults<DayAccount>
    
    var processedDayAccounts: [String: [Date: DayAccount]]
    var yearCosts: [Int: [String: [String: MonthCostAndIncome]]]
    
    
    
    // 日、周、月、年
    var segmentationSelection: SegmentationEnum
    // 当前DatePicker选择的date
    var currentSelectedDate: Date
    
    
    
    // 给互动图表的时候使用，触摸了之后选择了改日期的数据，那么进行展示
    @State var selectedDate: Date?
//    @State var selectedLineText: String {
//
//    }
    
    
    
    init(segmentationSelection: SegmentationEnum, currentSelectedDate: Date, selectedItemName: String? = nil, processedDayAccounts: [String: [Date: DayAccount]], yearCosts: [Int: [String: [String: MonthCostAndIncome]]]) {
        self.segmentationSelection = segmentationSelection
        self.currentSelectedDate = currentSelectedDate

        self.processedDayAccounts = processedDayAccounts
        self.yearCosts = yearCosts
    }
    
    
    
    // 本来想的是给不同的用户，不同的线条颜色
    var gradients: [String: LinearGradient] {
        var gradients = [String: LinearGradient]()
        for (index, name) in processedDayAccounts.keys.sorted(by: {$0 < $1}).enumerated() {
            if name == StaticProperty.MySelfName {
                gradients[name] = LinearGradient(gradient: Gradient(colors: [Color.accentColor.opacity(0.7), Color.accentColor.opacity(0.75)]), startPoint: .top, endPoint: .bottom)
            } else {
                switch index % 2 {
                case 0: gradients[name] = LinearGradient(gradient: Gradient(colors: [.blue, Color.incomeColor]), startPoint: .top, endPoint: .bottom)
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
                    Chart {
                        ForEach(tempDayAccount.wrappedRecords, id: \.id) { record in
                            BarMark(
                                x: .value("item", record.wrappedItem),
                                yStart: .value("price", 0),
                                yEnd: .value("price", record.costOrIncome ? record.price * -1 : record.price)
                            )
                            .annotation(position: .top, alignment: .top) {
                                    Text("\(record.costOrIncome ? "+" : "-")\(record.price, specifier: "%.2F")")
                                        .font(.footnote)
                                }
                                .foregroundStyle(gradients[StaticProperty.MySelfName]!)
                                .foregroundStyle(by:.value("item", StaticProperty.MySelfName))
                        }
                    }
                    .chartLegend(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading) {
                            AxisGridLine(centered: false, stroke: StrokeStyle(dash: [2.5])).foregroundStyle(Color.accentColor)
//                            AxisValueLabel()
                        }
                    }
                    .chartXAxis {
                        AxisMarks {
                            AxisGridLine(centered: false, stroke: StrokeStyle(dash: [2.5])).foregroundStyle(Color.accentColor)
                            AxisValueLabel()
                        }
                    }
                } else {
                    Chart {
                        ForEach([Record](), id: \.id) { record in
                            BarMark(x: .value("item", record.wrappedItem), y: .value("price", record.price))
                                .annotation {
                                    Text("\(record.price, specifier: "%.2F")")
                                        .font(.footnote)
                                }
                                .foregroundStyle(gradients[StaticProperty.MySelfName]!)
                                .foregroundStyle(by:.value("item", StaticProperty.MySelfName))
                        }
                    }
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
                }
                
                
            case .weekSeg:
                Chart(processedDayAccounts.sorted(by: {$0.key < $1.key}), id: \.key) { data in // key是名字
                    // 此处小于号表示图表中从左到右时间越来越大
                    ForEach(data.value.sorted(by: {$0.key < $1.key}), id: \.key) { dateAndDayAccount in // key是时间
                        // 每一天的消费都是一个bar
                        if currentSelectedDate.isInSameWeek(as: dateAndDayAccount.key) {
                            let cost = dateAndDayAccount.value.wrappedRecords.filter({!$0.costOrIncome}).map({$0.price}).reduce(0.0, +)
                            let income = dateAndDayAccount.value.wrappedRecords.filter({$0.costOrIncome}).map({$0.price}).reduce(0.0, +)
                            
                            if let selectedDate = selectedDate, selectedDate.isInSameDay(as: dateAndDayAccount.key) && (cost != 0 || income != 0) {
                                RuleMark(x: .value("Account Week", dateAndDayAccount.key, unit: .day))
//                                        .foregroundStyle(by: .value("Name", "\(StaticProperty.MySelfName)-入"))
                                    .foregroundStyle(Color.accentColor.opacity(0.5))
                                    .annotation(position: .overlay, alignment: .centerFirstTextBaseline) {
                                        Text("消费：\(cost, specifier: "%.2F")\n收入：\(income, specifier: "%.2F")")
                                    }
                            }
                            
                            if cost != 0 {
                                LineMark(x: .value("Account Week", dateAndDayAccount.key, unit: .day), y: .value("Value", cost))
                                .foregroundStyle(by: .value("Name", "\(StaticProperty.MySelfName)-出"))
                                //                                    .symbol(by: .value("Name", "\(StaticProperty.MySelfName)-出"))
//                                        .symbolSize(dateAndDayAccount.key.isInSameDay(as: currentSelectedDate) ? 250 : 100)
//                                        .symbol {
//                                            Circle()
////                                                .strokeBorder(Color.accentColor, lineWidth: 3)
//                                                .fill(Color.accentColor)
//                                                .frame(width: 10)
//                                        }
                                    .interpolationMethod(.catmullRom)
                                    .lineStyle(.init(lineWidth: 3))
                                
                                
                                PointMark(x: .value("Account Week", dateAndDayAccount.key, unit: .day), y: .value("Value", cost))
                                    .foregroundStyle(by: .value("Name", "\(StaticProperty.MySelfName)-出"))
//                                        .annotation(position: .overlay, alignment: .bottom, spacing: 10) {
//                                            Text("\(cost, specifier: "%.2F")")
//                                                .font(.footnote)
//                                        }
                                    .symbol {
                                        Circle()
                                            .fill(Color.accentColor)
                                            .frame(width: 10)
                                            .shadow(radius: 3, x: 3, y: 3)
                                    }
                            }
                            
                            
                            if income != 0.0 {
                                LineMark(x: .value("Account Week", dateAndDayAccount.key, unit: .day), y: .value("Value", income))
                                    .foregroundStyle(by: .value("Name", "\(StaticProperty.MySelfName)-入"))
//                                        .symbolSize(dateAndDayAccount.key.isInSameDay(as: currentSelectedDate) ? 250 : 100)
//                                        .symbol {
//                                            Circle()
//                                                .fill(Color.incomeColor)
//                                                .frame(width: 10)
//                                        }
                                    .interpolationMethod(.catmullRom)
                                    .lineStyle(.init(lineWidth: 3))
                                
                                PointMark(x: .value("Account Week", dateAndDayAccount.key, unit: .day), y: .value("Value", income))
                                    .foregroundStyle(by: .value("Name", "\(StaticProperty.MySelfName)-入"))
//                                        .annotation(position: .overlay, alignment: .bottom, spacing: 10) {
//                                            Text("\(cost, specifier: "%.2F")")
//                                                .font(.footnote)
//                                        }
                                    .symbol {
                                        Circle()
                                            .fill(Color.incomeColor)
                                            .frame(width: 10)
                                            .shadow(radius: 3, x: 3, y: 3)
                                    }
                            }
                        }
                    }
                }
                .chartForegroundStyleScale(["\(StaticProperty.MySelfName)-出": Color.accentColor, "\(StaticProperty.MySelfName)-入": Color.incomeColor]) // 这个是控制legend的图表颜色的
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
                                
                                // 增加触感
                                if !selectedDate.isInSameDay(as: self.selectedDate) {
                                    selectedChangeGenerator.selectionChanged()
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
                                        
                                        // 增加触感
                                        if !selectedDate.isInSameDay(as: self.selectedDate) {
                                            selectedChangeGenerator.selectionChanged()
                                        }
                                        
                                        self.selectedDate = selectedDate
                                    })
                                    .onEnded({ _ in
                                        self.selectedDate = nil
                                    })
                            )
                    }
                }
                
                
            case .monthSeg:
                Chart(processedDayAccounts.sorted(by: {$0.key < $1.key}), id: \.key) { data in
                    // 此处小于号表示图表中从左到右时间越来越大
                    ForEach(data.value.sorted(by: {$0.key < $1.key}), id: \.key) { dateAndDayAccount in
                        if currentSelectedDate.isInSameMonth(as: dateAndDayAccount.key) {
                            let cost = dateAndDayAccount.value.wrappedRecords.filter({!$0.costOrIncome}).map({$0.price}).reduce(0.0, +)
                            let income = dateAndDayAccount.value.wrappedRecords.filter({$0.costOrIncome}).map({$0.price}).reduce(0.0, +)

                            // 每一天的消费都是一个line
                            if let selectedDate = selectedDate, selectedDate.isInSameDay(as: dateAndDayAccount.key) && (cost != 0 || income != 0) {
                                RuleMark(x: .value("Account Week", dateAndDayAccount.key, unit: .day))
                                    .foregroundStyle(Color.accentColor.opacity(0.5))
                                    .annotation(position: .overlay, alignment: .centerFirstTextBaseline) {
                                        Text("消费：\(cost, specifier: "%.2F")\n收入：\(income, specifier: "%.2F")")
                                    }
                            }
    //
                            if cost != 0 {
                                LineMark(x: .value("Account Week", dateAndDayAccount.key, unit: .day), y: .value("Value", cost))
                                .foregroundStyle(by: .value("Name", "\(StaticProperty.MySelfName)-出"))
                                //                                    .symbol(by: .value("Name", "\(StaticProperty.MySelfName)-出"))
    //                                .symbolSize(dateAndDayAccount.key.isInSameDay(as: currentSelectedDate) ? 250 : 100)
    //                                .symbol {
    //                                    Circle()
    ////                                                .strokeBorder(Color.accentColor, lineWidth: 3)
    //                                        .fill(Color.accentColor)
    //                                        .frame(width: 10)
    //                                }
//                                    .interpolationMethod(.catmullRom)
//                                    .lineStyle(.init(lineWidth: 3))


                                PointMark(x: .value("Account Week", dateAndDayAccount.key, unit: .day), y: .value("Value", cost))
                                    .foregroundStyle(by: .value("Name", "\(StaticProperty.MySelfName)-出"))
    //                                        .annotation(position: .overlay, alignment: .bottom, spacing: 10) {
    //                                            Text("\(cost, specifier: "%.2F")")
    //                                                .font(.footnote)
    //                                        }
                                    .symbol {
                                        Circle()
                                            .fill(Color.accentColor)
                                            .frame(width: 10)
                                            .shadow(radius: 3, x: 3, y: 3)
                                    }
                            }
                            
                            if income != 0.0 {
                                LineMark(x: .value("Account Week", dateAndDayAccount.key, unit: .day), y: .value("Value", income))
                                    .foregroundStyle(by: .value("Name", "\(StaticProperty.MySelfName)-入"))
//                                    .symbolSize(dateAndDayAccount.key.isInSameDay(as: currentSelectedDate) ? 250 : 100)
//                                    .symbol {
//                                        Circle()
//                                            .fill(Color.incomeColor)
//                                            .frame(width: 10)
//                                    }
//                                    .interpolationMethod(.catmullRom)
//                                    .lineStyle(.init(lineWidth: 3))

                                PointMark(x: .value("Account Week", dateAndDayAccount.key, unit: .day), y: .value("Value", income))
                                    .foregroundStyle(by: .value("Name", "\(StaticProperty.MySelfName)-入"))
    //                                        .annotation(position: .overlay, alignment: .bottom, spacing: 10) {
    //                                            Text("\(cost, specifier: "%.2F")")
    //                                                .font(.footnote)
    //                                        }
                                    .symbol {
                                        Circle()
                                            .fill(Color.incomeColor)
                                            .frame(width: 10)
                                            .shadow(radius: 3, x: 3, y: 3)
                                    }
                            }
                        }
                        
//
//
                       
                        
                        
                    }
                }
                .chartForegroundStyleScale(["\(StaticProperty.MySelfName)-出": Color.accentColor, "\(StaticProperty.MySelfName)-入": Color.incomeColor])  // 这个是控制legend的图表颜色的
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisGridLine(centered: false, stroke: StrokeStyle(dash: [2.5])).foregroundStyle(Color.accentColor)
                        AxisValueLabel()
                    }
                }
                .chartXAxis {
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

                                // 增加触感
                                if !selectedDate.isInSameDay(as: self.selectedDate) {
                                    selectedChangeGenerator.selectionChanged()
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

                                        // 增加触感
                                        if !selectedDate.isInSameDay(as: self.selectedDate) {
                                            selectedChangeGenerator.selectionChanged()
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
                let currentYearCost = yearCosts[currentSelectedDate.year] ?? [String: [String: MonthCostAndIncome]]()

                Chart(currentYearCost.sorted(by: {$0.key < $1.key}), id: \.key) { yearCostsValue in // key是名字
                    // 此处小于号表示图表中从左到右时间越来越大
                    ForEach(yearCostsValue.value.sorted(by: {$0.key < $1.key}), id: \.key) { monthAndDayAccount in // key是月
                        // 每一个月的消费都是一个point
                        if monthAndDayAccount.value.cost != 0.0 {
                            LineMark(x: .value("Account Month", monthAndDayAccount.key), y: .value("Value", monthAndDayAccount.value.cost))
                                .foregroundStyle(by: .value("Name", "\(StaticProperty.MySelfName)-出")) // 告诉收入与支出是分开的线
                                .interpolationMethod(.catmullRom)

                                .lineStyle(.init(lineWidth: 3))

                            PointMark(x: .value("Account Month", monthAndDayAccount.key), y: .value("Value", monthAndDayAccount.value.cost))
                            //                        .symbol(by: .value("Name", "\(StaticProperty.MySelfName)-出"))
                                .symbolSize(100)
                                .foregroundStyle(by: .value("Name", "\(StaticProperty.MySelfName)-出")) // 告诉收入与支出不是一样的颜色
                                .annotation(position: .overlay, alignment: .bottom, spacing: 10) {
                                    Text("\(monthAndDayAccount.value.cost, specifier: "%.2F")")
                                        .font(.footnote)
                                }
                        }

                        if monthAndDayAccount.value.income != 0.0 {
                            // 每一个月的收入都是一个point
                            LineMark(x: .value("Account Month", monthAndDayAccount.key), y: .value("Value", monthAndDayAccount.value.income))
                                .foregroundStyle(by:.value("Name", "\(StaticProperty.MySelfName)-入"))
                                .interpolationMethod(.catmullRom)
                                .lineStyle(.init(lineWidth: 3))

                            PointMark(x: .value("Account Month", monthAndDayAccount.key), y: .value("Value", monthAndDayAccount.value.income))
                            //                        .symbol(by: .value("Name", "\(StaticProperty.MySelfName)-入"))
                                .symbolSize(100)
                                .foregroundStyle(by:.value("Name", "\(StaticProperty.MySelfName)-入"))
                                .annotation(position: .overlay, alignment: .bottom, spacing: 10) {
                                    Text("\(monthAndDayAccount.value.income, specifier: "%.2F")")
                                        .font(.footnote)
                                }
                        }
                    }
                }
                .chartForegroundStyleScale(["\(StaticProperty.MySelfName)-出": Color.accentColor, "\(StaticProperty.MySelfName)-入": Color.incomeColor])  // 这个是控制legend的图表颜色的
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
        .padding([.top, .bottom], 20)
        .padding([.leading, .trailing], 10)
        .background {
            RoundedRectangle(cornerRadius: 10)
//                .fill(Color(.systemFill))
//                .fill(.gray)
                .fill(Color(UIColor.systemBackground))
                .padding([.top, .bottom], 10)
                .shadow(color: .accentColor.opacity(0.4), radius: 5, x: 2, y: 2)
        }
            
            
        
        
        
//        VStack(alignment: .leading) {
//            switch segmentationSelection {
//            case .daySeg:
//                if let tempDayAccount = processedDayAccounts[StaticProperty.MySelfName]?[currentSelectedDate] {
//                    Chart {
//                        ForEach(tempDayAccount.wrappedRecords, id: \.id) { record in
//                            BarMark(
//                                x: .value("item", record.wrappedItem),
//                                yStart: .value("price", 0),
//                                yEnd: .value("price", record.costOrIncome ? record.price * -1 : record.price)
//                            )
//                            .annotation(position: .top, alignment: .top) {
//                                    Text("\(record.costOrIncome ? "+" : "-")\(record.price, specifier: "%.2F")")
//                                        .font(.footnote)
//                                }
//                                .foregroundStyle(gradients[StaticProperty.MySelfName]!)
//                                .foregroundStyle(by:.value("item", StaticProperty.MySelfName))
//                        }
//                    }
//                    .chartLegend(.hidden)
//                    .chartYAxis {
//                        AxisMarks(position: .leading) {
//                            AxisGridLine(centered: false, stroke: StrokeStyle(dash: [2.5])).foregroundStyle(Color.accentColor)
////                            AxisValueLabel()
//                        }
//                    }
//                    .chartXAxis {
//                        AxisMarks {
//                            AxisGridLine(centered: false, stroke: StrokeStyle(dash: [2.5])).foregroundStyle(Color.accentColor)
//                            AxisValueLabel()
//                        }
//                    }
//                } else {
//                    Chart {
//                        ForEach([Record](), id: \.id) { record in
//                            BarMark(x: .value("item", record.wrappedItem), y: .value("price", record.price))
//                                .annotation {
//                                    Text("\(record.price, specifier: "%.2F")")
//                                        .font(.footnote)
//                                }
//                                .foregroundStyle(gradients[StaticProperty.MySelfName]!)
//                                .foregroundStyle(by:.value("item", StaticProperty.MySelfName))
//                        }
//                    }
//                    .chartLegend(.hidden)
//                    .chartYAxis {
//                        AxisMarks(position: .leading) {
//                            AxisGridLine(centered: false, stroke: StrokeStyle(dash: [2.5])).foregroundStyle(Color.accentColor)
//                            AxisValueLabel()
//                        }
//                    }
//                    .chartXAxis {
//                        AxisMarks {
//                            AxisGridLine(centered: false, stroke: StrokeStyle(dash: [2.5])).foregroundStyle(Color.accentColor)
//                            AxisValueLabel()
//                        }
//                    }
//                }
//
//
//
//            case .weekSeg:
//                Chart(processedDayAccounts.sorted(by: {$0.key < $1.key}), id: \.key) { data in // key是名字
//                    // 此处小于号表示图表中从左到右时间越来越大
//                    ForEach(data.value.sorted(by: {$0.key < $1.key}), id: \.key) { dateAndDayAccount in // key是时间
//                        // 每一天的消费都是一个bar
//                        if currentSelectedDate.isInSameWeek(as: dateAndDayAccount.key) {
//                            let cost = dateAndDayAccount.value.wrappedRecords.filter({!$0.costOrIncome}).map({$0.price}).reduce(0.0, +)
//                            let income = dateAndDayAccount.value.wrappedRecords.filter({$0.costOrIncome}).map({$0.price}).reduce(0.0, +)
//
//                            if cost != 0.0 {
//                                LineMark(x: .value("Account Day", dateAndDayAccount.key, unit: .day), y: .value("Value", cost))
////                                    .annotation(position: .top, alignment: .top) {
////                                        Text("\(cost, specifier: "%.2F")")
////                                            .font(.footnote)
////                                    }
//                                    .symbol(by: .value("Account Day",  data.key))
//                                    .symbolSize(dateAndDayAccount.key.isInSameDay(as: currentSelectedDate) ? 250 : 100)
//                                    .interpolationMethod(.catmullRom)
//                                    .foregroundStyle(by:.value("Name", "\(StaticProperty.MySelfName)-出"))
//                                    .lineStyle(.init(lineWidth: 3))
//
//                                if let selectedDate = selectedDate, selectedDate.isInSameDay(as: dateAndDayAccount.key) {
//                                    RuleMark(x: .value("Account Day", dateAndDayAccount.key, unit: .day))
//                                        .foregroundStyle(Color.accentColor.opacity(0.5))
//
//                                    PointMark(x: .value("Account Day", dateAndDayAccount.key, unit: .day), y: .value("Value", cost))
//                                        .symbol {
//                                            Circle()
//                                                .fill(Color.accentColor)
//                                                .frame(width: 15)
//                                                .shadow(radius: 3, x: 3, y: 3)
//                                        }
////                                        .foregroundStyle(Color.accentColor)
//                                        .annotation(position: .overlay, alignment: .bottom, spacing: 10) {
//                                            Text("\(cost, specifier: "%.2F")")
//                                                .font(.footnote)
//                                        }
//                                }
//                            }
//
//
//                            if income != 0.0 {
//                                LineMark(x: .value("Account Day", dateAndDayAccount.key, unit: .day), y: .value("Value", income))
////                                    .annotation(position: .top, alignment: .top) {
////                                        Text("\(income, specifier: "%.2F")")
////                                            .font(.footnote)
////                                    }
//                                    .symbol(by: .value("Account Day",  data.key))
//                                    .symbolSize(dateAndDayAccount.key.isInSameDay(as: currentSelectedDate) ? 250 : 100)
//                                    .interpolationMethod(.catmullRom)
//                                    .foregroundStyle(by:.value("Name", "\(StaticProperty.MySelfName)-入"))
//                                    .lineStyle(.init(lineWidth: 3))
//
//                                if let selectedDate = selectedDate, selectedDate.isInSameDay(as: dateAndDayAccount.key) {
////                                    RuleMark(x: .value("Account Day", dateAndDayAccount.key, unit: .day))
////                                        .foregroundStyle(Color.accentColor.opacity(0.5))
//
//                                    PointMark(x: .value("Account Day", dateAndDayAccount.key, unit: .day), y: .value("Value", income))
//                                        .symbol {
//                                            Circle()
//                                                .fill(Color.incomeColor)
//                                                .frame(width: 15)
//                                                .shadow(radius: 3, x: 3, y: 3)
//                                        }
////                                        .foregroundStyle(Color.incomeColor)
////                                        .annotation(position: .overlay, alignment: .bottom, spacing: 10) {
////                                            Text("\(income, specifier: "%.2F")")
////                                                .font(.footnote)
////                                        }
//                                }
//                            }
//
//
//
////                            AreaMark(
////                                x: .value("Account Day",  dateAndDayAccount.key, unit: .day),
////                                y: .value("Value", cost)
////                            )
////                                .interpolationMethod(.catmullRom)
////                                // 先颜色，再foregroundStyle(by:.value这个颜色才有效，不然被下面的chartForegroundStyleScale覆盖。
////                                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.accentColor.opacity(0.1), Color.accentColor.opacity(0.2)]), startPoint: .top, endPoint: .bottom))
////                                .foregroundStyle(by:.value("Name", StaticProperty.MySelfName))
//                        }
//                    }
//                }
//                .chartForegroundStyleScale(["\(StaticProperty.MySelfName)-出": Color.accentColor, "\(StaticProperty.MySelfName)-入": Color.incomeColor]) // 这个是控制legend的图表颜色的
////                .chartLegend(position: .overlay, alignment: .top)
////                .chartPlotStyle { plotArea in
////                    plotArea
////                        .background(LinearGradient(gradient: Gradient(colors: [Color.accentColor, .red]), startPoint: .top, endPoint: .bottom))
////                }
//                .chartYAxis {
//                    AxisMarks(position: .leading) {
//                        AxisGridLine(centered: false, stroke: StrokeStyle(dash: [2.5]))
//                            .foregroundStyle(Color.accentColor)
//                        AxisValueLabel()
//                    }
//                }
//                .chartXAxis {
//                    AxisMarks(values: .stride(by: .day)) { value in
//                        AxisGridLine(centered: false, stroke: StrokeStyle(dash: [2.5]))
//                            .foregroundStyle(Color.accentColor)
//                        AxisTick(centered: false, stroke: StrokeStyle(lineWidth: 3))
//                            .foregroundStyle(Color.accentColor)
//                        AxisValueLabel(format: .dateTime.day().weekday(), centered: true)
//                    }
//                }
//                .chartOverlay { proxy in
//                    GeometryReader { geometry in
//                        Rectangle()
//                            .fill(Color.clear)
//                            .contentShape(Rectangle())
//
//                            .onTapGesture { location in
//                                let currentX = location.x - geometry[proxy.plotAreaFrame].origin.x
//                                guard currentX >= 0, currentX < proxy.plotAreaSize.width else {
//                                    return
//                                }
//
//                                guard let selectedDate: Date = proxy.value(atX: currentX, as: Date.self) else {
//
//                                    return
//                                }
//
//                                // 增加触感
//                                if !selectedDate.isInSameDay(as: self.selectedDate) {
//                                    selectedChangeGenerator.selectionChanged()
//                                }
//
//                                self.selectedDate = selectedDate
//                            }
//                            .gesture(
//                                DragGesture()
//                                    .onChanged({ value in
//                                        let currentX = value.location.x - geometry[proxy.plotAreaFrame].origin.x
//                                        guard currentX >= 0, currentX < proxy.plotAreaSize.width else {
//                                            return
//                                        }
//                                        guard let selectedDate: Date = proxy.value(atX: currentX, as: Date.self) else {
//
//                                            return
//                                        }
//
//                                        // 增加触感
//                                        if !selectedDate.isInSameDay(as: self.selectedDate) {
//                                            selectedChangeGenerator.selectionChanged()
//                                        }
//
//                                        self.selectedDate = selectedDate
//                                    })
//                                    .onEnded({ _ in
//                                        self.selectedDate = nil
//                                    })
//                            )
//                    }
//                }
//
//
//            case .monthSeg:
//                Chart(processedDayAccounts.sorted(by: {$0.key < $1.key}), id: \.key) { data in
//                    // 此处小于号表示图表中从左到右时间越来越大
//                    ForEach(data.value.sorted(by: {$0.key < $1.key}), id: \.key) { dateAndDayAccount in
//                        let cost = dateAndDayAccount.value.wrappedRecords.filter({!$0.costOrIncome}).map({$0.price}).reduce(0.0, +)
//                        let income = dateAndDayAccount.value.wrappedRecords.filter({$0.costOrIncome}).map({$0.price}).reduce(0.0, +)
//
//                        // 每一天的消费都是一个bar
//                        if cost != 0.0 && currentSelectedDate.isInSameMonth(as: dateAndDayAccount.key) {
//                            LineMark(x: .value("Account Day", dateAndDayAccount.key, unit: .day), y: .value("Value", cost))
//                                .symbol(by: .value("Account Day",  data.key))
//                                .symbolSize(currentSelectedDate.isInSameDay(as: dateAndDayAccount.key) ? 250 : 100)
//                                .foregroundStyle(by:.value("Name", "\(StaticProperty.MySelfName)-出"))
//                                .lineStyle(.init(lineWidth: 3))
//
//                            if let selectedDate = selectedDate, selectedDate.isInSameDay(as: dateAndDayAccount.key) {
//                                RuleMark(x: .value("Account Day", dateAndDayAccount.key, unit: .day))
//                                    .foregroundStyle(Color.accentColor.opacity(0.5))
//
//                                PointMark(x: .value("Account Day", dateAndDayAccount.key, unit: .day), y: .value("Value", cost))
////                                    .symbolSize(100)
//                                    .symbol {
//                                        Circle()
//                                            .fill(Color.accentColor)
//                                            .frame(width: 15)
//                                            .shadow(radius: 3, x: 3, y: 3)
//                                    }
////                                    .foregroundStyle(Color.accentColor)
//                                    .annotation(position: .bottom, alignment: .bottom) {
//                                        Text("\(cost, specifier: "%.2F")")
//                                            .font(.footnote)
//                                    }
//
//                            }
//                        }
//
//                        if income != 0.0 && currentSelectedDate.isInSameMonth(as: dateAndDayAccount.key) {
//                            LineMark(x: .value("Account Day", dateAndDayAccount.key, unit: .day), y: .value("Value", income))
//                                .symbol(by: .value("Account Day",  data.key))
//                                .symbolSize(currentSelectedDate.isInSameDay(as: dateAndDayAccount.key) ? 250 : 100)
//                                .foregroundStyle(by:.value("Name", "\(StaticProperty.MySelfName)-入"))
//                                .lineStyle(.init(lineWidth: 3))
//
//                            if let selectedDate = selectedDate, selectedDate.isInSameDay(as: dateAndDayAccount.key) {
//                                RuleMark(x: .value("Account Day", dateAndDayAccount.key, unit: .day))
//                                    .foregroundStyle(Color.accentColor.opacity(0.5))
//
//                                PointMark(x: .value("Account Day", dateAndDayAccount.key, unit: .day), y: .value("Value", income))
////                                    .symbolSize(100)
//                                    .symbol {
//                                        Circle()
//                                            .fill(Color.incomeColor)
//                                            .frame(width: 15)
//                                            .shadow(radius: 3, x: 3, y: 3)
//                                    }
////                                    .foregroundStyle(Color.incomeColor)
////                                    .annotation(position: .bottom, alignment: .bottom) {
////                                        Text("\(cost, specifier: "%.2F")")
////                                            .font(.footnote)
////                                    }
//                            }
//                        }
//                    }
//                }
//                .chartForegroundStyleScale(["\(StaticProperty.MySelfName)-出": Color.accentColor, "\(StaticProperty.MySelfName)-入": Color.incomeColor])  // 这个是控制legend的图表颜色的
//                .chartYAxis {
//                    AxisMarks(position: .leading) {
//                        AxisGridLine(centered: false, stroke: StrokeStyle(dash: [2.5])).foregroundStyle(Color.accentColor)
//                        AxisValueLabel()
//                    }
//                }
//                .chartXAxis {
//                    AxisMarks(values: .stride(by: .day)) { value in
//                        AxisGridLine(centered: false, stroke: StrokeStyle(dash: [2.5]))
//                            .foregroundStyle(Color.accentColor)
//                        AxisValueLabel(format: .dateTime.day(), centered: true)
//                    }
//                }
//                .chartOverlay { proxy in
//                    GeometryReader { geometry in
//                        Rectangle()
//                            .fill(Color.clear)
//                            .contentShape(Rectangle())
//
//                            .onTapGesture { location in
//                                let currentX = location.x - geometry[proxy.plotAreaFrame].origin.x
//                                guard currentX >= 0, currentX < proxy.plotAreaSize.width else {
//                                    return
//                                }
//
//                                guard let selectedDate: Date = proxy.value(atX: currentX, as: Date.self) else {
//
//                                    return
//                                }
//
//                                // 增加触感
//                                if !selectedDate.isInSameDay(as: self.selectedDate) {
//                                    selectedChangeGenerator.selectionChanged()
//                                }
//
//                                self.selectedDate = selectedDate
//                            }
//                            .gesture(
//                                DragGesture()
//                                    .onChanged({ value in
//                                        let currentX = value.location.x - geometry[proxy.plotAreaFrame].origin.x
//                                        guard currentX >= 0, currentX < proxy.plotAreaSize.width else {
//                                            return
//                                        }
//                                        guard let selectedDate: Date = proxy.value(atX: currentX, as: Date.self) else {
//
//                                            return
//                                        }
//
//                                        // 增加触感
//                                        if !selectedDate.isInSameDay(as: self.selectedDate) {
//                                            selectedChangeGenerator.selectionChanged()
//                                        }
//
//                                        self.selectedDate = selectedDate
//                                    })
//                                    .onEnded({ _ in
//                                        self.selectedDate = nil
//                                    })
//                            )
//                    }
//                }
//
//            case .yearSeg:
//                let currentYearCost = yearCosts[currentSelectedDate.year] ?? [String: [String: MonthCostAndIncome]]()
//
//                Chart(currentYearCost.sorted(by: {$0.key < $1.key}), id: \.key) { yearCostsValue in // key是名字
//                    // 此处小于号表示图表中从左到右时间越来越大
//                    ForEach(yearCostsValue.value.sorted(by: {$0.key < $1.key}), id: \.key) { monthAndDayAccount in // key是月
//                        // 每一个月的消费都是一个point
//                        if monthAndDayAccount.value.cost != 0.0 {
//                            LineMark(x: .value("Account Month", monthAndDayAccount.key), y: .value("Value", monthAndDayAccount.value.cost))
//                            //                            .symbol(by: .value("Account Day",  yearCostsValue.key))
//                            //                            .symbol() {
//                            //                                Circle()
//                            //                                    .fill(.red)
//                            //                                    .frame(width: 10)
//                            //                            }
//                            //                            .symbolSize((Int(monthAndDayAccount.key)! == currentSelectedDate.monthInYear) ? 250 : 100)
//                                .interpolationMethod(.catmullRom)
//                                .foregroundStyle(by:.value("Name", "\(StaticProperty.MySelfName)-出"))
//                                .lineStyle(.init(lineWidth: 3))
//
//                            PointMark(x: .value("Account Month", monthAndDayAccount.key), y: .value("Value", monthAndDayAccount.value.cost))
//                                .symbol {
//                                    Circle()
//                                        .fill(Color.accentColor)
//                                        .frame(width: 15)
//                                        .shadow(radius: 3, x: 3, y: 3)
//                                }
//                                .annotation(position: .overlay, alignment: .bottom, spacing: 10) {
//                                    Text("\(monthAndDayAccount.value.cost, specifier: "%.2F")")
//                                        .font(.footnote)
//                                }
//                        }
//
//
//                        // 每一个月的收入都是一个point
//                        LineMark(x: .value("Account Month", monthAndDayAccount.key), y: .value("Value", monthAndDayAccount.value.income))
//                            .interpolationMethod(.catmullRom)
//                            .foregroundStyle(by:.value("Name", "\(StaticProperty.MySelfName)-入"))
//                            .lineStyle(.init(lineWidth: 3))
//
//                        PointMark(x: .value("Account Month", monthAndDayAccount.key), y: .value("Value", monthAndDayAccount.value.income))
//                            .symbol {
//                                Circle()
//                                    .fill(Color.incomeColor)
//                                    .frame(width: 15)
//                                    .shadow(radius: 3, x: 3, y: 3)
//                            }
//                            .annotation(position: .overlay, alignment: .bottom, spacing: 10) {
//                                Text("\(monthAndDayAccount.value.income, specifier: "%.2F")")
//                                    .font(.footnote)
//                            }
//                    }
//                }
//                .chartForegroundStyleScale(["\(StaticProperty.MySelfName)-出": Color.accentColor, "\(StaticProperty.MySelfName)-入": Color.incomeColor])  // 这个是控制legend的图表颜色的
//                .chartYAxis {
//                    AxisMarks(position: .leading) {
//                        AxisGridLine(centered: false, stroke: StrokeStyle(dash: [2.5])).foregroundStyle(Color.accentColor)
//                        AxisValueLabel()
//                    }
//                }
//                .chartXAxis {
//                    AxisMarks { value in
//
//                        AxisGridLine(centered: false, stroke: StrokeStyle(dash: [2.5]))
//                            .foregroundStyle(Color.accentColor)
//                        AxisTick(centered: false, stroke: StrokeStyle(lineWidth: 3))
//                            .foregroundStyle(Color.accentColor)
//                        AxisValueLabel {
//                            if let month = value.as(String.self) {
//                                Text(month)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        .padding([.top, .bottom], 20)
//        .padding([.leading, .trailing], 10)
//        .background {
//            RoundedRectangle(cornerRadius: 10)
////                .fill(Color(.systemFill))
////                .fill(.gray)
//                .fill(Color(UIColor.systemBackground))
//                .padding([.top, .bottom], 10)
//                .shadow(color: .accentColor.opacity(0.4), radius: 5, x: 2, y: 2)
//        }
    }
}
    

