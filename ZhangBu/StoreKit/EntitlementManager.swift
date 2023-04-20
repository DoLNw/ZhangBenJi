//
//  EntitlementManager.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/29.
//


// [iOS in-app subscription tutorial with StoreKit 2 and Swift](https://www.revenuecat.com/blog/engineering/ios-in-app-subscription-tutorial-with-storekit-2-and-swift/)


import SwiftUI

// 将已经购买的功能存储在UserDefaults中，这样的话Extensions中就能访问了。
class EntitlementManager: ObservableObject {
    static let userDefaults = UserDefaults(suiteName: "com.jcwang.ZhangBu")
    
    
    @AppStorage(StaticProperty.USERDEFAULT_Various_Charts, store: userDefaults) var hasVariousChartsFunc: Bool = false
    @AppStorage(StaticProperty.USERDEFAULT_Has_Multi_Sharing, store: userDefaults) var hasMultiSharingFunc: Bool = false
}



// 把这两个购买的参量从purchasemanager中解耦，那么在Extension中就能直接使用了。
// let entitlementManager = EntitlementManager()
// if entitlementManager.hasPro {
//     // Do something
// } else {
//     // Don't do something
// }

