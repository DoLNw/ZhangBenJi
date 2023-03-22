//
//  ContentView.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/12.
//


// 拆分了一些View：添加修改（AddDayAccountView）、显示（ListAndChart）、然后标签修改View的话单独弹出（EditTagView）


import SwiftUI
import CoreData
import LocalAuthentication


struct ContentView: View {
    let selectedChangeGenerator = UISelectionFeedbackGenerator()
    
    
    @Environment(\.managedObjectContext) private var viewContext

    
    
    // DayACcount表示每一天的消费
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DayAccount.date, ascending: false)],
        animation: .default)
    var dayAccounts: FetchedResults<DayAccount>
    
    
    
    // DayAccount中每一个Record会有一个RecordTag，我这里从tag入手，先拿到所有的tag
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \RecordTag.createdDate, ascending: true)],
        animation: .default)
    var tags: FetchedResults<RecordTag>
    @State var currentRecordTag: RecordTag?    // 为了修改，需要让currentRecordTag变量联通AccountList和AddDayAccountView
    
    
    
    // 给多人共享使用
    var personalInfo: PersonalInfo = PersonalInfo(name: StaticProperty.MySelfName, createDate: Date())
    
    
    
    @AppStorage(StaticProperty.USERFEFAULTS_CHARTORLIST) var chartOrList: ShowingView = .accountsList // true是chart
    @AppStorage(StaticProperty.USERFEFAULTS_SegmentationSelection) var segmentationSelection: SegmentationEnum = .weekSeg
    @AppStorage(StaticProperty.USERFEFAULTS_SHOULDLOCK) var shouldLock = false
    @State private var isUnlocked = false

    
    
    // 为了可以给record修改，要贯穿AccountList和AddDayAccountView两个，需要一些东西联通AccountList和AddDayAccountView
    @FocusState var focusedField: FocusedField?
    @State var editAccount: DayAccount? // 有值代表是正在edit界面
    @State var editRecord: Record?
    
    @State private var amount: Double?
    @State var item = ""
    
    
    
    // 当前选择的时间
    @State var currentSelectedDate = Calendar.current.date(from: DateComponents(year: Date().year, month: Date().monthInYear, day: Date().dayInMonth))!
    
    
    
    // 显示通知界面
    @State private var showSettingView = false
    
    
    var body: some View {
        ZStack {
                MyNavigation {
                    ZStack {
                        VStack(alignment: .leading) {
                            
                            Picker("", selection: $segmentationSelection) {
                                ForEach(SegmentationEnum.allCases, id: \.self) { option in
                                    Text(option.rawValue)
                                    
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(alignment: .top)
                            .onChange(of: segmentationSelection) { newValue in
                                selectedChangeGenerator.selectionChanged()
                            }
                            
                            if #available(iOS 16, *) {
                                switch chartOrList {
                                case .accountsList:
                                    AccountsList(focusedField: _focusedField, editAccount: $editAccount, editRecord: $editRecord, amount: $amount, item: $item, currentRecordTag: $currentRecordTag, currentSelectedDate: $currentSelectedDate, segmentationSelection: segmentationSelection, processedDayAccounts: processedDayAccounts, yearCosts: yearCosts)
                                        .environment(\.managedObjectContext, viewContext)
                                case .accountsChart:
                                    AccountsChart(segmentationSelection: segmentationSelection, currentSelectedDate: currentSelectedDate, processedDayAccounts: processedDayAccounts, yearCosts: yearCosts)
                                        .environment(\.managedObjectContext, viewContext)
                                }
                            } else {
                                AccountsList(focusedField: _focusedField, editAccount: $editAccount, editRecord: $editRecord, amount: $amount, item: $item, currentRecordTag: $currentRecordTag, currentSelectedDate: $currentSelectedDate, segmentationSelection: segmentationSelection, processedDayAccounts: processedDayAccounts, yearCosts: yearCosts)
                                    .environment(\.managedObjectContext, viewContext)
                            }
                            
                            
                            Spacer()
                            
                            RoundedRectangle(cornerRadius: 0.3)
                                .frame(height: 1)
                                .foregroundColor(.accentColor)
                            
                            AddDayAccountView(currentRecordTag: $currentRecordTag, currentSelectedDate: $currentSelectedDate, amount: $amount, item: $item, focusedField: _focusedField, editAccount: $editAccount, editRecord: $editRecord, processedDayAccounts: processedDayAccounts, personalInfo: personalInfo)
                                .environment(\.managedObjectContext, viewContext)
                        }
                        .padding()
                        
                        
                        if !isUnlocked && shouldLock {
                            Text("请点击使用Face ID解锁")
                                .frame(width: fullWidth, height: fullHeight)
                                .background(.ultraThinMaterial)
                                .onTapGesture {
                                    authenticate()
                                }
                        }
                    }
                    .sheet(isPresented: $showSettingView, content: {
                        SettingView(isUnlocked: $isUnlocked, todayPrice: todayPrice)
                    })
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            if !(!isUnlocked && shouldLock) {
                                Button {
                                    selectedChangeGenerator.selectionChanged()
                                    self.showSettingView = true
                                } label: {
                                    Label("设置", systemImage: "gear")
                                }
                            }
                        }

                        ToolbarItem(placement: .navigationBarTrailing) {
                            if #available(iOS 16, *) {
                                if !(!isUnlocked && shouldLock) {
                                    Button {
                                        selectedChangeGenerator.selectionChanged()
                                        
                                        withAnimation {
                                            chartOrList.toggle()
                                        }
                                    } label: {
                                        switch chartOrList {
                                        case .accountsList:
                                            Label("", systemImage: "chart.bar.xaxis")
                                        case .accountsChart:
                                            Label("", systemImage: "list.bullet.rectangle.portrait.fill")
                                        }
                                    }
                                }
                            }
                        }

                    
                        ToolbarItem(placement: .navigationBarLeading) {
                            if shouldLock {
                                Button {
                                    if self.isUnlocked {
                                        self.isUnlocked = false
                                    } else {
                                        authenticate()
                                    }
                                } label: {
                                    if self.isUnlocked {
                                        Label("锁定", systemImage: "lock.open")
                                    } else {
                                        Label("解锁", systemImage: "lock")
                                    }
                                    
                                }
                            }
                        }
                    }
                    .navigationTitle("账本：\(currentSelectedDate.year)年\(segmentationSelection == .yearSeg ? "" : "\(currentSelectedDate.monthInYear)月")")
                }
        }
        .onAppear {
            // 人脸解锁
            if shouldLock && !isUnlocked {
                authenticate()
            }
            
            // 首先检查，如果没有标签，设置几个默认的标签
            if tags.count == 0 {
                print("aaaaaaa")
                let tag1 = RecordTag(context: viewContext)
                tag1.createdDate = Date.now.addingTimeInterval(-500)
                print(Date.now.addingTimeInterval(-500).description)
                tag1.tagName = "三餐"
                tag1.id = UUID()
                tag1.setColor(color: .cyan)
                
                let tag2 = RecordTag(context: viewContext)
                tag2.createdDate = Date.now.addingTimeInterval(-400)
                print(Date.now.addingTimeInterval(-400).description)
                tag2.tagName = "娱乐"
                tag2.id = UUID()
                tag2.setColor(color: .blue)
                
                let tag3 = RecordTag(context: viewContext)
                tag3.createdDate = Date.now.addingTimeInterval(-300)
                print(Date.now.addingTimeInterval(-300).description)
                tag3.tagName = "交通"
                tag3.id = UUID()
                tag3.setColor(color: .red)
                
                let tag4 = RecordTag(context: viewContext)
                tag4.createdDate = Date.now.addingTimeInterval(-200)
                tag4.tagName = "其它"
                tag4.id = UUID()
                tag4.setColor(color: .orange)
                
                viewContextSave()
            }
        }
        
    }
        

}

extension ContentView {
    var processedDayAccounts: [String: [Date: DayAccount]] {
        var processedDayAccounts = [String: [Date: DayAccount]]()
        
        for dayAccount in dayAccounts {
            if processedDayAccounts[dayAccount.wrappedName] == nil {
                processedDayAccounts[dayAccount.wrappedName] = [Date: DayAccount]()
            }
            
            processedDayAccounts[dayAccount.wrappedName]![dayAccount.wrappedDate] = dayAccount
        }
        
        return processedDayAccounts
    }
    
    // 给年、月Segmentation用
    // 年份，姓名，月份，该月份总和
    var yearCosts: [Int: [String: [String: Double]]] {
        var yearCosts: [Int: [String: [String: Double]]] = [:]
        
        for dayAccount in dayAccounts {
            if yearCosts[dayAccount.wrappedDate.year] == nil {
                yearCosts[dayAccount.wrappedDate.year] = [String: [String: Double]]()
            }
            if yearCosts[dayAccount.wrappedDate.year]![dayAccount.wrappedName] == nil {
                yearCosts[dayAccount.wrappedDate.year]![dayAccount.wrappedName] = [String: Double]()
            }
            
            if yearCosts[dayAccount.wrappedDate.year]![dayAccount.wrappedName]![String(dayAccount.wrappedDate.monthInYear)] == nil {
                yearCosts[dayAccount.wrappedDate.year]![dayAccount.wrappedName]![String(dayAccount.wrappedDate.monthInYear)] = dayAccount.wrappedRecords.map({$0.price}).reduce(0.0, +)
            } else {
                yearCosts[dayAccount.wrappedDate.year]![dayAccount.wrappedName]![String(dayAccount.wrappedDate.monthInYear)] =  yearCosts[dayAccount.wrappedDate.year]![dayAccount.wrappedName]![String(dayAccount.wrappedDate.monthInYear)]! + dayAccount.wrappedRecords.map({$0.price}).reduce(0.0, +)
            }
        }
        
        return yearCosts
    }
    
    var todayPrice: Double {
        if let _ = processedDayAccounts[StaticProperty.MySelfName] {
            if let tempDayAccount = processedDayAccounts[StaticProperty.MySelfName]![currentSelectedDate] {
                return tempDayAccount.wrappedRecords.map({$0.price}).reduce(0.0, +)
            }
        }
        
        return 0.0
    }
    
    func removeRecord(by name: String, and date: Date, for record: Record) {
        processedDayAccounts[name]![date]!.removeFromRecords(record)
        
        if processedDayAccounts[name]![date]!.wrappedRecords.count == 0 {
            viewContext.delete(processedDayAccounts[name]![date]!)
            
            viewContextSave()
        }
    }
    
    // face id解锁过程
    func authenticate() {
        let context = LAContext()
        var error: NSError?

        // check whether biometric authentication is possible
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // it's possible, so go ahead and use it
            let reason = "We need to unlock your data."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                // authentication has now completed
                if success {
                    self.isUnlocked = true
                } else {
                    self.isUnlocked = false
                }
            }
        } else {
            self.isUnlocked = false
        }
    }
    
    func viewContextSave() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}


