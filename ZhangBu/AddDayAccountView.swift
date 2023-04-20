//
//  AddDayAccountView.swift
//  DemoForSharingRecord
//
//  Created by Jcwang on 2023/3/2.
//


// 增加，或者修改的界面
// 修改的话，是AccountList传过来的Binding数据，有数据的话代表是修改


import SwiftUI

enum CostOrIncomeEnum: String, CaseIterable {
    case cost = "出"
    case income = "入"
}


struct AddDayAccountView: View {
    let generator = UISelectionFeedbackGenerator()
    
    
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var entitlementManager: EntitlementManager // 为了设置
    
    
    // DayAccount中每一个Record会有一个RecordTag，我这里从tag入手，先拿到所有的tag
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \RecordTag.createdDate, ascending: true)],
        animation: .default)
    var tags: FetchedResults<RecordTag>
    
    
    // 从这里到下面 显示DatePicker的格式 之前的几个指标都是给添加、修改使用的
    // 显示修改标签菜单
    @State private var showEditRecordTagView = false
    @Binding var currentRecordTag: RecordTag?
    
    @Binding var currentSelectedDate: Date
    @Binding var amount: Double?
    @Binding var item: String
    
    // 为了可以给record修改，要贯穿AccountList和AddDayAccountView两个，需要一些东西串联
    @FocusState var focusedField: FocusedField?
    @Binding var editAccount: DayAccount? // 有值代表是正在edit界面
    @Binding var editRecord: Record?
        
    
    
    
    // 显示彩蛋
    @State var supriseFullName: String?
    @State var showSuprise = false
    
    
    
    // 显示添加栏
    @State var showAddView: Bool = false
    // 显示物品TextField
    @State var showItem: Bool = false
    
    
    // 收入还是消费
    @State var costOrIncomeEnum: CostOrIncomeEnum = .cost
    
    
    
    // 对应通知的权限，每一次添加或者修改消费之后，需要更新通知
    @AppStorage(StaticProperty.USERFEFAULTS_SHOULDDAILYREPORT) var shouldDailyReport = false
    // 每天通知时间，Date不能直接存在UserDefaults中，所以多用了一个Double
    @AppStorage(StaticProperty.USERFEFAULTS_DailyReportTime) var savedDailyReportTime = 0.0
    // 通知时间，是否已经设置通知闹钟
    @AppStorage(StaticProperty.USERFEFAULTS_AlreadySettingReport) var alreadySettingReport = false
    
    
    
    // 通知的时候显示消费，以及删除的时候判断某一个dayAccount中是否还有record，没有的话需要删除dayAccount
    var processedDayAccounts: [String: [Date: DayAccount]]
    
    
    
    // 多人共享的时候使用
    let personalInfo: PersonalInfo
    
    
    
    var body: some View {
        HStack {
            Spacer()
            
            VStack {
                HStack {
                    if showItem {
                        TextField("物品", text: $item)
                            .font(.title)
                            .focused($focusedField, equals: .itemField)
                        
                        Spacer()
                        
                        Picker("", selection: $costOrIncomeEnum) {
                            ForEach(CostOrIncomeEnum.allCases, id: \.self) { myEnum in
                                Text(myEnum.rawValue)
                                    .tag(Optional(myEnum))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 60, alignment: .trailing)
                        
                        Picker("", selection: $currentRecordTag) {
                            ForEach(tags, id: \.wrappedID) { tag in
                                Text("\(tag.wrappedTagName)")
                                    .foregroundColor(tag.wrappedColor)
                                //                            .tag(tag as? RecordTag)
                                    .tag(Optional(tag))
                            }
                            Text("编辑标签").tag(nil as RecordTag?)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 80, alignment: .trailing)
                        .onChange(of: currentRecordTag) { newValue in
                            // 此处使用nil表示需要编辑标签，弹出编辑界面。然后这个标签被主动设置为第一个
                            if currentRecordTag == nil {
                                showEditRecordTagView = true
                                currentRecordTag = tags.first
                            }
                        }
                        
                        
                        Button() {
                            if let tempAmount = amount, let tag = currentRecordTag {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                
                                if let tempEditAccount = editAccount, let tempEditRecord = editRecord {
                                    self.removeRecord(dayAccount: tempEditAccount, for: tempEditRecord)
                                    
                                    self.addRecord(by: StaticProperty.MySelfName, and: currentSelectedDate, with: item, price: tempAmount, createdDate: tempEditRecord.wrappedcreateDate, tag: tag)
                                } else {
                                    self.addRecord(by: StaticProperty.MySelfName, and: currentSelectedDate, with: item, price: tempAmount, tag: tag)
                                }
                                
                                amount = nil
                                item = ""
                                editAccount = nil
                                editRecord = nil
                                
                                // 如果添加或者修改了今天的消费，那么需要修改通知
                                if currentSelectedDate.isInToday {
                                    var todayPrice = 0.0
                                    if let _ = processedDayAccounts[StaticProperty.MySelfName] {
                                        if let tempDayAccount = processedDayAccounts[StaticProperty.MySelfName]![currentSelectedDate] {
                                            todayPrice = tempDayAccount.wrappedRecords.filter({!$0.costOrIncome}).map({$0.price}).reduce(0.0, +)
                                        }
                                    }
                                    
                                    alreadySettingReport = NotificationHelper.editNotification(savedDailyReportTime: savedDailyReportTime, todayPrice: todayPrice)
                                }
                            }
                            
                            focusedField = nil
                        } label: {
                            if let _ = editAccount {
                                Label("修改", systemImage: "")
                                    .font(.title3)
                            } else {
                                Label("", systemImage: "plus.app.fill")
                                    .font(.title)
                            }
                        }
                    }
                }
                
                
                
                HStack {
                    Text("¥")
                        .font(.title)
                    TextField("金额", value: $amount, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .amountField)
                        .font(.title)
                        .onChange(of: amount) { newValue in
                            withAnimation {
                                if newValue != nil {
                                    showItem = true
                                } else {
                                    showItem = false
                                }
                            }
                        }
                    
//                    Button {
//                        withAnimation {
//                            showItem.toggle()
//                        }
//
//                        if showItem {
//                            focusedField = .amountField
//                        } else {
//                            focusedField = nil
//                        }
//
//                        generator.selectionChanged()
//                    } label: {
//                        if showItem {
//                            Label("", systemImage: "arrow.down.right.and.arrow.up.left")
//                        } else {
//                            Label("", systemImage: "arrow.up.backward.and.arrow.down.forward")
//                        }
//                    }
                    
                    Button {
                        let currentDate = Date()
                        let components = DateComponents(year: currentDate.year, month: currentDate.monthInYear, day: currentDate.dayInMonth)
    
                        currentSelectedDate = Calendar.current.date(from: components)!
                        
                        focusedField = nil
                    } label: {
                        // 下面这段是看，是否是今天
                        let _currentDate = Date()
                        let components = DateComponents(year: _currentDate.year, month: _currentDate.monthInYear, day: _currentDate.dayInMonth)
                        let currentDate = Calendar.current.date(from: components)!
    
                        if currentDate == currentSelectedDate {
                            Label("", systemImage: "smallcircle.filled.circle.fill")
                                .font(.title2)
                        } else {
                            Label("", systemImage: "smallcircle.filled.circle")
                                .font(.title2)
                        }
                    }
                    
                    DatePicker("", selection: $currentSelectedDate, displayedComponents: .date)
                        .labelsHidden()
                        .onChange(of: currentSelectedDate) { newValue in
                            let components = DateComponents(year: newValue.year, month: newValue.monthInYear, day: newValue.dayInMonth)
                            currentSelectedDate = Calendar.current.date(from: components)!
                        }
                }
            }
            .onSubmit {
                // 按下回车之后会有反应
                if focusedField == .amountField {
                    focusedField = .itemField
                } else if focusedField == .itemField {
                    if let fullName = supriseString[item] {
                        if amount == 19970717 {
                            entitlementManager.hasVariousChartsFunc = true
                            entitlementManager.hasMultiSharingFunc = true
                        }
                        supriseFullName = fullName
                        showSuprise = true
                        
                        amount = nil
                        item = ""
                    }
                    
                    if let tempAmount = amount, let tag = currentRecordTag {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        if let tempEditAccount = editAccount, let tempEditRecord = editRecord {
                            self.removeRecord(dayAccount: tempEditAccount, for: tempEditRecord)
                            
                            self.addRecord(by: StaticProperty.MySelfName, and: currentSelectedDate, with: item, price: tempAmount, createdDate: tempEditRecord.wrappedcreateDate, tag: tag)
                            
                        } else {
                            self.addRecord(by: StaticProperty.MySelfName, and: currentSelectedDate, with: item, price: tempAmount, tag: tag)
                        }
                        
                        amount = nil
                        item = ""
                        editAccount = nil
                        editRecord = nil
                        
                        // 如果添加或者修改了今天的消费，那么需要修改通知
                        // 如果添加或者修改了今天的消费，那么需要修改通知
                        if currentSelectedDate.isInToday {
                            var todayPrice = 0.0
                            if let _ = processedDayAccounts[StaticProperty.MySelfName] {
                                if let tempDayAccount = processedDayAccounts[StaticProperty.MySelfName]![currentSelectedDate] {
                                    todayPrice = tempDayAccount.wrappedRecords.filter({!$0.costOrIncome}).map({$0.price}).reduce(0.0, +)
                                }
                            }
                            
                            alreadySettingReport = NotificationHelper.editNotification(savedDailyReportTime: savedDailyReportTime, todayPrice: todayPrice)
                        }
                    }
                    
                    focusedField = nil
                } else {
                    focusedField = nil
                }
            }
            .padding(5)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.systemBackground))
                    .padding(-5)
                //                .shadow(color: Color(UIColor.systemGray), radius: 10, x: 5, y: 5)
                    .shadow(color: .accentColor.opacity(0.35), radius: 10)
            )
            .sheet(isPresented: $showEditRecordTagView, content: {
                if #available(iOS 16.0, *) {
                    EditRecordTagView()
                        .environment(\.managedObjectContext, viewContext)
                        .presentationDetents([.medium, .large])
                    //                    .presentationDetents([.fraction(0.2), .height(100)])
                } else {
                    EditRecordTagView()
                        .environment(\.managedObjectContext, viewContext)
                }
            })
            .alert(isPresented: $showSuprise) {
                Alert(title: Text("这是彩蛋奥!"), message: Text("你好呀，\(supriseFullName ?? item)~\n本次打开app，为您解锁所有功能。"))
            }
            .onAppear {
                currentRecordTag = tags.first
            }
        }
        
        
    }
}


extension AddDayAccountView {
    // 同一天内，不同的物品消费，添加
    // 此处需要再加一个tempDayAccount.wrappedRecords.count != 0，因为edit的时候吗，先删除可能吧dayAccount删除了但是processedDayAccounts还没有改变，导致出错。
    // createdDate是给record排序用的，与RecordTag的的createdDate是一样的。
    func addRecord(by name: String, and date: Date, with item: String, price: Double, createdDate: Date = Date(), tag: RecordTag) -> Void {
        if let _ = processedDayAccounts[name], let tempDayAccount = processedDayAccounts[name]![date], tempDayAccount.wrappedRecords.count != 0 {
            let record = Record(context: viewContext)
            record.id = UUID()
            record.createDate = createdDate
            record.item = item == "" ? tag.wrappedTagName : item
            record.price = price
            record.belongTag = tag
            record.costOrIncome = costOrIncomeEnum == .income   // cost是false
            
            processedDayAccounts[name]![date]!.addToRecords(record)
        } else {
            let dayAccount = DayAccount(context: viewContext)
            dayAccount.id = UUID()
            dayAccount.date = date
            dayAccount.name = name
            
            let record = Record(context: viewContext)
            record.belongDayAccount = dayAccount
            record.createDate = createdDate
            record.id = UUID()
            record.price = price
            record.item = item == "" ? tag.wrappedTagName : item
            record.belongTag = tag
            record.costOrIncome = costOrIncomeEnum == .income
        }
        
        //        self._addRecord(by: name, and: date, with: item, price: price)
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
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
