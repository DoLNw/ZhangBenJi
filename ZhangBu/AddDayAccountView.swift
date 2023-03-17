//
//  AddDayAccountView.swift
//  DemoForSharingRecord
//
//  Created by Jcwang on 2023/3/2.
//

import SwiftUI
private var supriseString = ["诚妈": "周林芬", "忠忠": "王建忠", "王嘉诚": "王嘉诚", "杰哥": "沈杰", "翔哥": "王瀚翔", "苏航": "苏航", "VIGA": "王佳维", "陈胜": "陈胜", "WTT": "王婷婷", "张姐": "张婉卿", "都哥": "季建都", "新程": "沈新程"]

struct AddDayAccountView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var currentSelectedDate: Date
    @Binding var amount: Double?
    @Binding var item: String
    
    // 为了可以给record修改，要贯穿AccountList和AddDayAccountView两个，需要一些东西串联
    @FocusState var focusedField: FocusedField?
    @Binding var editAccount: DayAccount? // 有值代表是正在edit界面
    @Binding var editRecord: Record?
    
//    var focusedField: FocusState<FocusedField?>.Binding
    
    @State var showFullDatePicker = false
    
    @State var supriseFullName: String?
    @State var showSuprise = false
    
    var processedDayAccounts: [String: [Date: DayAccount]]
    let personalInfo: PersonalInfo
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack() {
                Text("¥")
                    .font(.title)
                TextField("金额", value: $amount, format: .number)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amountField)
                    .font(.title)
                
                TextField("物品", text: $item)
                    .font(.title)
                    .focused($focusedField, equals: .itemField)
                
                Button() {
                    if let tempAmount = amount, item != "" {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        if let tempEditAccount = editAccount, let tempEditRecord = editRecord {
                            self.removeRecord(dayAccount: tempEditAccount, for: tempEditRecord)
                            
                            self.addRecord(by: StaticProperty.MySelfName, and: currentSelectedDate, with: item, price: tempAmount, createdDate: tempEditRecord.wrappedcreateDate)
                            
                            
                        } else {
                            self.addRecord(by: StaticProperty.MySelfName, and: currentSelectedDate, with: item, price: tempAmount)
                        }
                        
                        amount = nil
                        item = ""
                        editAccount = nil
                        editRecord = nil
                    }
                    
                    focusedField = nil
                } label: {
                    if let _ = editAccount {
                        Label("", systemImage: "pencil.line")
                            .font(.title)
//                            .tint(LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .leading, endPoint: .trailing))
                    } else {
                        Label("", systemImage: "plus.app.fill")
                            .font(.title)
//                            .tint(LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .leading, endPoint: .trailing))
                    }
                    
                }
            }
            .onSubmit {
                // 按下回车之后会有反应
                if focusedField == .amountField {
                    focusedField = .itemField
                } else if focusedField == .itemField {
                    if let fullName = supriseString[item] {
                        supriseFullName = fullName
                        showSuprise = true
                    }
                    
                    if let tempAmount = amount, item != "" {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        if let tempEditAccount = editAccount, let tempEditRecord = editRecord {
                            self.removeRecord(dayAccount: tempEditAccount, for: tempEditRecord)
                            
                            self.addRecord(by: StaticProperty.MySelfName, and: currentSelectedDate, with: item, price: tempAmount, createdDate: tempEditRecord.wrappedcreateDate)
                            
                            
                        } else {
                            self.addRecord(by: StaticProperty.MySelfName, and: currentSelectedDate, with: item, price: tempAmount)
                        }
                        
                        amount = nil
                        item = ""
                        editAccount = nil
                        editRecord = nil
                    }
                    
                    focusedField = nil
                } else {
                    focusedField = nil
                }
            }
            .onChange(of: focusedField) { newValue in
                if focusedField != nil {
                    showFullDatePicker = false
                }
            }
            
            HStack {
                Toggle("日历", isOn: $showFullDatePicker.animation())
                    .toggleStyle(.button)
//                    .tint(LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .top, endPoint: .bottom))
                    .onChange(of: showFullDatePicker) { newValue in
                        let generator = UISelectionFeedbackGenerator()
                        generator.selectionChanged()
                        
                        if newValue && focusedField != nil {
                            focusedField = nil
                        }
                    }

                Button {
                    focusedField = nil
                    
                    let generator = UISelectionFeedbackGenerator()
                    generator.selectionChanged()
                    
                    let currentDate = Date()
                    let components = DateComponents(year: currentDate.year, month: currentDate.monthInYear, day: currentDate.dayInMonth)

                    currentSelectedDate = Calendar.current.date(from: components)!
                } label: {
                    let _currentDate = Date()
                    let components = DateComponents(year: _currentDate.year, month: _currentDate.monthInYear, day: _currentDate.dayInMonth)
                    let currentDate = Calendar.current.date(from: components)!

                    if currentDate == currentSelectedDate {
                        Label("", systemImage: "smallcircle.filled.circle.fill")
//                            .tint(LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .top, endPoint: .bottom))
                            .font(.title2)
                    } else {
                        Label("", systemImage: "smallcircle.filled.circle")
//                            .tint(LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .top, endPoint: .bottom))
                            .font(.title2)
                    }
                }
                
                Spacer()
                
                if showFullDatePicker {
                    DatePicker("", selection: $currentSelectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
//                        .tint(LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .top, endPoint: .bottom))
                        .labelsHidden()
                        .onChange(of: currentSelectedDate) { newValue in
                            let components = DateComponents(year: newValue.year, month: newValue.monthInYear, day: newValue.dayInMonth)
                            currentSelectedDate = Calendar.current.date(from: components)!
                        }
                } else {
                    DatePicker("", selection: $currentSelectedDate, displayedComponents: .date)
//                        .tint(LinearGradient(gradient: Gradient(colors: [.orange, .red]), startPoint: .top, endPoint: .bottom))
                        .labelsHidden()
                        .onChange(of: currentSelectedDate) { newValue in
                            let components = DateComponents(year: newValue.year, month: newValue.monthInYear, day: newValue.dayInMonth)
                            currentSelectedDate = Calendar.current.date(from: components)!
                        }
                }
            }
        }
        .alert(isPresented: $showSuprise) {
            Alert(title: Text("这是彩蛋奥!"), message: Text("你好呀，\(supriseFullName ?? item)~"))
        }
    }
}


extension AddDayAccountView {
    // 同一天内，不同的物品消费，添加
    // 此处需要再加一个tempDayAccount.wrappedRecords.count != 0，因为edit的时候吗，先删除可能吧dayAccount删除了但是processedDayAccounts还没有改变，导致出错。
    func addRecord(by name: String, and date: Date, with item: String, price: Double, createdDate: Date = Date()) -> Void {
        if let _ = processedDayAccounts[name], let tempDayAccount = processedDayAccounts[name]![date], tempDayAccount.wrappedRecords.count != 0 {
            let record = Record(context: viewContext)
            record.id = UUID()
            record.createDate = createdDate
            record.item = item
            record.price = price
            
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
            record.item = item
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
    
    
    
//    func editRecord(remove dayAccount: DayAccount, for record: Record, by name: String, and newDate: Date, with newItem: String, newPrice: Double) {
//        dayAccount.removeFromRecords(record)
//
//        if newDate != dayAccount.wrappedDate && dayAccount.wrappedRecords.count == 0 {
//            viewContext.delete(dayAccount)
//
//            let newDayAccount = DayAccount(context: viewContext)
//            newDayAccount.id = UUID()
//            newDayAccount.date = newDate
//            newDayAccount.name = name
//
//            let record = Record(context: viewContext)
//            record.belongDayAccount = newDayAccount
//            record.createDate = record.createDate  // 修改的话，createdDate不变
//            record.id = UUID()
//            record.price = newPrice
//            record.item = newItem
//        } else if newDate != dayAccount.wrappedDate {
//            let record = Record(context: viewContext)
//            record.id = UUID()
//            record.createDate = record.createDate  // 修改的话，createdDate不变
//            record.item = newItem
//            record.price = newPrice
//        }
//
//
//
//        do {
//            try viewContext.save()
//        } catch {
//            let nsError = error as NSError
//            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
//        }
//    }
}
