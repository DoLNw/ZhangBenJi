//
//  ZhangBuApp.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/12.
//

import SwiftUI

@main
struct ZhangBuApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var purchaseManager: PurchaseManager
    // 为了保证Extension中可以使用
    @StateObject private var entitlementManager: EntitlementManager  // 由于这个依赖purchaseManager，所以写在init里面
    
    init() {
        let entitlementManager = EntitlementManager()
        let purchaseManager = PurchaseManager(entitlementManager: entitlementManager)
        
        self._entitlementManager = StateObject(wrappedValue: entitlementManager)
        self._purchaseManager = StateObject(wrappedValue: purchaseManager)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(entitlementManager)
                .environmentObject(purchaseManager)
                .task {
                    await purchaseManager.updatePurchasedProducts()
                }
        }
    }
}
