//
//  SettingView.swift
//  DemoForSharingRecord
//
//  Created by Jcwang on 2023/3/15.
//

import SwiftUI
import LocalAuthentication
import UserNotifications

struct SettingView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var purchaseManager: PurchaseManager
    
    
    
    @Binding private var isUnlocked: Bool
    // 对应人脸识别的权限
    @AppStorage(StaticProperty.USERFEFAULTS_SHOULDLOCK) var shouldLock = false
    
    
    
    // 通知逻辑，因为需要在通知显示当天的消费金额，所以需要每一次都更新通知内容。
    // 所以1、一开始打开通知后，需要设置通知request。2、然后每添加修改（AddDayAccountView的Button和onSubmit中）、3、删除（AccountList中的ondelete）一次今天的消费，需要修改通知request。
    // 对应通知的权限
    @AppStorage(StaticProperty.USERFEFAULTS_SHOULDDAILYREPORT) var shouldDailyReport = false
    // 每天通知时间，Date不能直接存在UserDefaults中，所以多用了一个Double
    @AppStorage(StaticProperty.USERFEFAULTS_DailyReportTime) var savedDailyReportTime = 0.0
    @State var dailyReportTime = Date()
    // 通知时间，是否已经设置通知闹钟
    @AppStorage(StaticProperty.USERFEFAULTS_AlreadySettingReport) var alreadySettingReport = false
    // 通知使用
    var todayPrice: Double
    
    let notificationCenter = UNUserNotificationCenter.current()
    
    
    
//    @Environment(\.dismiss) var dismiss
    init(isUnlocked: Binding<Bool>, todayPrice: Double) {
        self._isUnlocked = isUnlocked
        self.todayPrice = todayPrice
    }
    
    
    
    
    var body: some View {
        
        ZStack {
            // 繁花曲线，在背景
            SpirographView()
            
            VStack(alignment: .leading) {
                Spacer()
                Spacer()
                
                Toggle("使用Face ID锁定", isOn: $shouldLock)
                    .onChange(of: shouldLock) { newValue in
                        if newValue {
                            authenticate()
                        }
                    }
                
                Spacer()
                
                Toggle("日报提醒", isOn: $shouldDailyReport)
                    .onChange(of: shouldDailyReport) { newValue in
                        
                        alreadySettingReport = false
                        if newValue {
                            requestNotiPermission()
                        } else {
                            // false之后需要把通知全部清空
                            notificationCenter.removeAllDeliveredNotifications()
                        }
                    }
                
                if shouldDailyReport {
                    if !alreadySettingReport {
                        DatePicker("请选择每天日报时间", selection: $dailyReportTime, displayedComponents: .hourAndMinute)
                            .onChange(of: dailyReportTime) { newValue in
                                savedDailyReportTime = newValue.timeIntervalSinceReferenceDate
                            }
                    }
                    
                    Button {
                        if !alreadySettingReport {
                            // 如果添加或者修改了今天的消费，那么需要修改通知
                            alreadySettingReport = NotificationHelper.editNotification(savedDailyReportTime: savedDailyReportTime, todayPrice: todayPrice)
                        } else {
                            alreadySettingReport = false // 重新设置时间
                            notificationCenter.removeAllPendingNotificationRequests()
                        }
                        
                    } label: {
                        Text("\(alreadySettingReport ? "已设置每天\(dailyReportTime.hour)：\(dailyReportTime.minute)发送日报，点击可调整时间" : "未设置日报通知，点击设置每天此时间发送日报")")
                    }
                }
                
                Spacer()
                
                PurchaseView()
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("开发人员：王嘉诚")
                        .font(.caption)
                    Text("联系邮箱：jcwang0717@163.com")
                        .font(.caption)
                }
            }
            .padding(20)
//            .backgroundStyle(Color.clear)
            .background(Color.clear)
        }
        .onAppear {
            dailyReportTime = Date(timeIntervalSinceReferenceDate: savedDailyReportTime)
        }
    }
    
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
                    self.shouldLock = true
                    self.isUnlocked = true
                } else {
                    self.shouldLock = false
                }
            }
        } else {
            self.shouldLock = false
        }
    }
    
    func requestNotiPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                self.shouldDailyReport = true
                print("All set")
            } else if let error = error {
                print(error.localizedDescription)
                self.shouldDailyReport = false
            }
        }
    }
}
