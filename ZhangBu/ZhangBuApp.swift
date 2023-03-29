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
    @StateObject private var purchaseManager = PurchaseManager()
    

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(purchaseManager)
                .task {
                    await purchaseManager.updatePurchasedProducts()
                }
        }
    }
}
