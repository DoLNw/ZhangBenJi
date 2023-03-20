//
//  ContentView.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/12.
//

import SwiftUI
import CoreData
import LocalAuthentication

var fullWidth: CGFloat = UIScreen.main.bounds.width
var fullHeight: CGFloat = UIScreen.main.bounds.height

enum SegmentationEnum: String, CaseIterable {
    case daySeg = "日"
    case weekSeg = "周"
    case monthSeg = "月"
    case yearSeg = "年"
}

enum FocusedField {
    case itemField, amountField
}

struct ContentView: View {
    let selectedChangeGenerator = UISelectionFeedbackGenerator()
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DayAccount.date, ascending: false)],
        animation: .default)
    var dayAccounts: FetchedResults<DayAccount>
    
    var personalInfo: PersonalInfo = PersonalInfo(name: StaticProperty.MySelfName, createDate: Date())
    
    @AppStorage("ChartOrList") var chartOrList = false // true是chart
    @AppStorage("SegmentationSelection") var segmentationSelection: SegmentationEnum = .weekSeg
    @State private var isUnlocked = false
    @AppStorage(StaticProperty.USERFEFAULTS_SHOULDLOCK) var shouldLock = false

    // 为了可以给record修改，要贯穿AccountList和AddDayAccountView两个，需要一些东西串联
    @FocusState var focusedField: FocusedField?
    @State var editAccount: DayAccount? // 有值代表是正在edit界面
    @State var editRecord: Record?
    
    @State var currentSelectedDate = Calendar.current.date(from: DateComponents(year: Date().year, month: Date().monthInYear, day: Date().dayInMonth))!
    @State private var amount: Double?
    @State var item = ""
    
    
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
                                if chartOrList {
                                    AccountsChart(segmentationSelection: segmentationSelection, currentSelectedDate: currentSelectedDate, processedDayAccounts: processedDayAccounts, yearCosts: yearCosts)
                                        .environment(\.managedObjectContext, viewContext)
                                } else {
                                    AccountsList(focusedField: _focusedField, editAccount: $editAccount, editRecord: $editRecord, date: $currentSelectedDate, amount: $amount, item: $item, segmentationSelection: segmentationSelection, currentSelectedDate: $currentSelectedDate, processedDayAccounts: processedDayAccounts, yearCosts: yearCosts)
                                        .environment(\.managedObjectContext, viewContext)
                                }
                            } else {
                                AccountsList(focusedField: _focusedField, editAccount: $editAccount, editRecord: $editRecord, date: $currentSelectedDate, amount: $amount, item: $item, segmentationSelection: segmentationSelection, currentSelectedDate: $currentSelectedDate, processedDayAccounts: processedDayAccounts, yearCosts: yearCosts)
                                    .environment(\.managedObjectContext, viewContext)
                            }
                            
                            
                            Spacer()
                            
                            RoundedRectangle(cornerRadius: 0.3)
                                .frame(height: 1)
//                                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .leading, endPoint: .trailing))
                                .foregroundColor(.accentColor)
                            
                            AddDayAccountView(currentSelectedDate: $currentSelectedDate, amount: $amount, item: $item, focusedField: _focusedField, editAccount: $editAccount, editRecord: $editRecord, processedDayAccounts: processedDayAccounts, personalInfo: personalInfo)
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
                                    //                                    .tint(LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .top, endPoint: .bottom))
                                    
                                }
                            }
                        }

                        ToolbarItem(placement: .navigationBarTrailing) {
                            if !(!isUnlocked && shouldLock) {
                                Button {
                                    selectedChangeGenerator.selectionChanged()
                                    
                                    withAnimation {
                                        chartOrList.toggle()
                                    }
                                } label: {
                                    if chartOrList {
                                        Label("", systemImage: "list.bullet.rectangle.portrait.fill")
                                        //                                        .tint(LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .top, endPoint: .bottom))
                                        
                                    } else {
                                        Label("", systemImage: "chart.bar.xaxis")
                                        //                                        .tint(LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .top, endPoint: .bottom))
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
                                        //                                        .tint(LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .top, endPoint: .bottom))
                                    } else {
                                        Label("解锁", systemImage: "lock")
                                        //                                        .tint(LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .top, endPoint: .bottom))
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
    
    // 给年Segmentation用
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
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
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
    
    // 设置通知
    // 在每天一定时候设置通知提醒，提醒今日已经消费，然后记录今天未记录的。当然还需要放入后面天的通知，因为避免后面天不打开app。
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}


