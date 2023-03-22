//
//  AccountsList.swift
//  DemoForSharingRecord
//
//  Created by Jcwang on 2023/3/11.
//


// 此处是显示List界面的UI，根据segment来分隔。


import SwiftUI

struct AccountsList: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    
    
    // 每天通知时间，Date不能直接存在UserDefaults中，所以多用了一个Double
    @AppStorage(StaticProperty.USERFEFAULTS_DailyReportTime) var savedDailyReportTime = 0.0
    
    
    
    // 为了可以给record修改，要贯穿AccountList和AddDayAccountView两个，需要一些东西串联
    @FocusState var focusedField: FocusedField?
    @Binding var editAccount: DayAccount? // 有值代表是正在edit界面
    @Binding var editRecord: Record?
    // 修改时，金额和物品名称
    @Binding var amount: Double?
    @Binding var item: String
    // 修改时，标签也要改变
    @Binding var currentRecordTag: RecordTag?
    
    
    // 修改时，当前时间要变成那个record的时间。然后显示界面，显示currentSelectedDate相关日、周、月、年的相关金额
    @Binding  var currentSelectedDate: Date
    
    
    // 选择，选择查看的是日、周、月、年
    var segmentationSelection: SegmentationEnum
    
    
    
    // DayAccounts和他有关的计算属性processedDayAccounts和yearCosts。
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DayAccount.date, ascending: false)],
        animation: .default)
    var dayAccounts: FetchedResults<DayAccount>
    
    // 名字，日期，DayAccount
    var processedDayAccounts: [String: [Date: DayAccount]]
    // 年份，姓名，月份，该月份总和
    var yearCosts: [Int: [String: [String: Double]]]
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
    
    
    
    // DayAccount中每一个Record会有一个RecordTag，我这里从tag入手，先拿到所有的tag
    // 修改时，如果没有标签，那么默认第一个标签
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \RecordTag.createdDate, ascending: true)],
        animation: .default)
    var tags: FetchedResults<RecordTag>
    
    
    
    
    // 本来想的是给不同的用户，不同的线条颜色
    var gradients: [String: LinearGradient] {
        var gradients = [String: LinearGradient]()
        for (index, name) in processedDayAccounts.keys.sorted(by: {$0 < $1}).enumerated() {
            if name == StaticProperty.MySelfName {
                gradients[name] = LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .top, endPoint: .bottom)
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
                } else {
                    Text("日消费：¥0.00").bold()
                        .foregroundColor(.accentColor)
                }
            
            case .weekSeg:
                Text("第\(currentSelectedDate.weekInMonth)周消费：¥\(weekCost, specifier: "%.2F")").bold()
                    .foregroundColor(.accentColor)
            case .monthSeg:
                let currentMonthCost = yearCosts[currentSelectedDate.year]?[StaticProperty.MySelfName]?[String(currentSelectedDate.monthInYear)] ?? 0.0

                Text("月消费：¥\(currentMonthCost, specifier: "%.2F")").bold()
                    .foregroundColor(.accentColor)
            case .yearSeg:
                let currentYearCost = yearCosts[currentSelectedDate.year] ?? [String: [String: Double]]()
                    
                Text("年消费：¥\(currentYearCost[StaticProperty.MySelfName]?.values.reduce(0.0, +) ?? 0.0, specifier: "%.2F")").bold()
                    .foregroundColor(.accentColor)
            }
            
            List(dayAccounts, id: \.id) { dayAccount in
                if (segmentationSelection == .daySeg && dayAccount.wrappedDate.isInSameDay(as: currentSelectedDate)) || (segmentationSelection == .weekSeg && dayAccount.wrappedDate.isInSameWeek(as: currentSelectedDate)) || (segmentationSelection == .monthSeg && dayAccount.wrappedDate.isInSameMonth(as: currentSelectedDate)) || (segmentationSelection == .yearSeg && dayAccount.wrappedDate.isInSameYear(as: currentSelectedDate)) {
                    // 同一天的一个Section
                    Section {
                        ForEach(dayAccount.wrappedRecords, id: \.id) { record in
                            HStack {
                                if let tempTag = record.belongTag {
                                    Text("\(tempTag.wrappedTagName)")
                                        .font(.caption)
                                        .foregroundColor(tempTag.wrappedColor)
                                } else {
                                    Text("无")
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
                                }
                                if editRecord == record {
                                    Text("正在修改...")
                                        .font(.title3)
                                        .foregroundColor(.accentColor)
                                    Spacer()
                                    Text("右滑取消")
                                        .foregroundColor(.accentColor)
                                } else {
                                    Text("\(record.wrappedItem)")
                                        .font(.title3)
                                    Spacer()
                                    Text("¥\(record.price, specifier: "%.2F")")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    if let tempEditRecord = editRecord, tempEditRecord.id == record.id {
                                        // 此处是取消修改，需要自动将键盘收回，然后取消当前的dayAccount和record，item和price，然后currentSelectedDate，currentRecordTag就不变了
                                        focusedField = nil
                                        
                                        editAccount = nil
                                        editRecord = nil
                                        
                                        amount = nil
                                        item = ""
                                    } else {
                                        // 此处是修改，需要自动将键盘弹出，然后拿到当前的dayAccount和record，然后让currentSelectedDate是该日期的，currentRecordTag是该record的标签的，item和price得到
                                        focusedField = .amountField
                                        
                                        editAccount = dayAccount
                                        editRecord = record
                                        
                                        currentSelectedDate = dayAccount.wrappedDate
                                        amount = record.price
                                        item = record.wrappedItem
                                        
                                        if let _ = record.belongTag {
                                            currentRecordTag = record.belongTag
                                        } else {
                                            currentRecordTag = tags.first
                                        }
                                        
                                    }
                                } label: {
                                    if let tempEditRecord = editRecord, tempEditRecord.id == record.id {
                                        Label("取消修改", systemImage: "")
                                    } else {
                                        Label("", systemImage: "pencil.line")
                                    }
                                }
                                .tint(Color.accentColor)
                            }
                        }
                        .onDelete { offsets in
                            withAnimation {
                                let _ = offsets.map { dayAccount.wrappedRecords[$0] }.forEach { record in
                                    if dayAccount.wrappedDate.isInToday {
                                        // 如果先remove，此处计算金钱的时候，可能dayAccount已经被remove了，dayAccount会位移到别的地方
                                        let _ = NotificationHelper.editNotification(savedDailyReportTime: 09, todayPrice: dayAccount.wrappedRecords.map({$0.price}).reduce(0.0, +) - record.price)
                                    }
                                    
                                    self.removeRecord(dayAccount: dayAccount, for: record)
                                }
                            }
                        }
                    } header: {
                        if currentSelectedDate.isInSameDay(as: dayAccount.wrappedDate) {
                            Text("\(segmentationSelection == .yearSeg ? "\(dayAccount.wrappedDate.monthInYear)月" : "")\(dayAccount.wrappedDate.dayInMonth)号（当前）")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        } else {
                            Text("\(segmentationSelection == .yearSeg ? "\(dayAccount.wrappedDate.monthInYear)月" : "")\(dayAccount.wrappedDate.dayInMonth)号")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .listRowSeparatorTint(Color.accentColor)

                }
            }
            .listStyle(.inset)
        }
    }
}

extension AccountsList {
    func removeRecord(dayAccount: DayAccount, for record: Record) {
        dayAccount.removeFromRecords(record)
        
        if dayAccount.wrappedRecords.count == 0 {
            viewContext.delete(dayAccount)
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

