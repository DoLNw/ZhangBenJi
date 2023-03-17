//
//  AccountsList.swift
//  DemoForSharingRecord
//
//  Created by Jcwang on 2023/3/11.
//

import SwiftUI

struct AccountsList: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // 为了可以给record修改，要贯穿AccountList和AddDayAccountView两个，需要一些东西串联
    @FocusState var focusedField: FocusedField?
    @Binding var editAccount: DayAccount? // 有值代表是正在edit界面
    @Binding var editRecord: Record?
    
    @Binding var date: Date
    @Binding var amount: Double?
    @Binding var item: String
    
    @State var showItemEditOrBar: Bool = true
    
    var segmentationSelection: SegmentationEnum
    @Binding  var currentSelectedDate: Date
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DayAccount.date, ascending: false)],
        animation: .default)
    var dayAccounts: FetchedResults<DayAccount>
    
    var processedDayAccounts: [String: [Date: DayAccount]]
    var yearCosts: [Int: [String: [String: Double]]]
    
    
    // 从ContentView到本View和AddDayAccountView，为了修改
//    focusedField
    
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
    
    
//    init(focusedField: FocusedField?, segmentationSelection: SegmentationEnum, currentSelectedDate: Date, selectedItemName: String? = nil, processedDayAccounts: [String: [Date: DayAccount]], yearCosts: [Int: [String: [String: Double]]]) {
//        self.focusedField = focusedField
//        
//        self.segmentationSelection = segmentationSelection
//        self.currentSelectedDate = currentSelectedDate
//
//        self.processedDayAccounts = processedDayAccounts
//        self.yearCosts = yearCosts
//    }
    
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
                                if editRecord == record {
                                    Text("正在修改...")
                                        .font(.title3)
                                        .foregroundColor(.accentColor)
                                    Spacer()
                                    Text("左滑取消")
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
                                        // 此处是修改，需要自动将键盘弹出，然后拿到当前的dayAccount和record，然后让currentSelectedDate是该日期的，item和price得到
                                        focusedField = nil
                                        
                                        editAccount = nil
                                        editRecord = nil
                                        
                                        amount = nil
                                        item = ""
                                    } else {
                                        // 此处是修改，需要自动将键盘弹出，然后拿到当前的dayAccount和record，然后让currentSelectedDate是该日期的，item和price得到
                                        focusedField = .amountField
                                        
                                        editAccount = dayAccount
                                        editRecord = record
                                        
                                        currentSelectedDate = dayAccount.wrappedDate
                                        amount = record.price
                                        item = record.wrappedItem
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
                                    self.removeRecord(dayAccount: dayAccount, for: record)
                                }
                            }
                        }

                    } header: {
                        if currentSelectedDate.isInSameDay(as: dayAccount.wrappedDate) {
                            Text("\(segmentationSelection == .yearSeg ? "\(dayAccount.wrappedDate.monthInYear)月" : "")\(dayAccount.wrappedDate.dayInMonth)号（当前）")
//                                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .red]), startPoint: .leading, endPoint: .trailing))
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        } else {
                            Text("\(segmentationSelection == .yearSeg ? "\(dayAccount.wrappedDate.monthInYear)月" : "")\(dayAccount.wrappedDate.dayInMonth)号")
//                                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .red]), startPoint: .leading, endPoint: .trailing))
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
        //        objectWillChange.send()
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

