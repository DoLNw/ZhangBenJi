//
//  SettingView.swift
//  DemoForSharingRecord
//
//  Created by Jcwang on 2023/3/15.
//

import SwiftUI
import LocalAuthentication

struct SettingView: View {
    @Binding private var isUnlocked: Bool
    @AppStorage(StaticProperty.USERFEFAULTS_SHOULDLOCK) var shouldLock = false
    
//    @Environment(\.dismiss) var dismiss
    init(isUnlocked: Binding<Bool>) {
        self._isUnlocked = isUnlocked
    }
    
    
    var body: some View {
        
        ZStack {
            // 繁花曲线
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
                
                // TODO
    //            Toggle("使用iCloud同步", isOn: $shouldLock)
    //                .onChange(of: shouldLock) { newValue in
    //                    if newValue {
    //                        authenticate()
    //                    }
    //                }
                
                
    //            Toggle("共享", isOn: $shouldLock)
    //                .onChange(of: shouldLock) { newValue in
    //                    if newValue {
    //                        authenticate()
    //                    }
    //                }
                
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
}
