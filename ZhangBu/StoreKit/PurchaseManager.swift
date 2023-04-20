//
//  PurchaseManager.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/29.
//

import Foundation


import Foundation
import StoreKit

@MainActor
class PurchaseManager: ObservableObject {
    // 第一阶段，查找当前App总共多少个购买项目
    private let productIds = [StaticProperty.USERDEFAULT_Various_Charts, StaticProperty.USERDEFAULT_Multi_Sharing]
    
    @Published
    private(set) var products: [Product] = []   // 这个表示当前的App有多少个购买的项目
    private var productsLoaded = false
    
    // 加载所有的购买项目
    // 当在设置界面的时候，加载出所有的购买项目
    func loadProducts() async throws {
        guard !self.productsLoaded else { return }
        self.products = try await Product.products(for: productIds)
        self.productsLoaded = true
    }
    
    // 用户点击后，跳出购买界面，然后进行操作
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case let .success(.verified(transaction)):
            // Successful purhcase
            await transaction.finish()
            await self.updatePurchasedProducts()
        case .success(.unverified(_, _)):  // 第二个参数是error
            // Successful purchase but transaction/receipt can't be verified
            // Could be a jailbroken phone
            break
        case .pending:
            // Transaction waiting on SCA (Strong Customer Authentication) or
            // approval from Ask to Buy
            break
        case .userCancelled:
            // ^^^
            break
        @unknown default:
            break
        }
    }
    
    
    
    // 第二阶段，三次调用更新
    // 上面的是调用系统的购买方法，然后下面的就是拿到购买的东西的变量
    // 这个表示已经购买的的项目的ID
    @Published private(set) var purchasedProductIDs = Set<String>()
    
//    var hasVariousChartsFunc: Bool {
//        return purchasedProductIDs.contains(StaticProperty.USERDEFAULT_Various_Charts)
//    }
//
//    var hasMultiSharingFunc: Bool {
//        return purchasedProductIDs.contains(StaticProperty.USERDEFAULT_Multi_Sharing)
//    }
    
    
    // 1、当App运行的时候更新当前购买了多少项目。所以在ZhangBuApp里面有代码。
    // 2、然后用户购买了之后，重新调用该方法，更新
    // 3、用户在别的设备购买，或者有一些订阅是到期的，就是下面的observeTransactionUpdates间听到之后，做出更新
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            if transaction.revocationDate == nil {
                self.purchasedProductIDs.insert(transaction.productID)
            } else {
                self.purchasedProductIDs.remove(transaction.productID)
            }
        }
        
        self.entitlementManager.hasVariousChartsFunc = purchasedProductIDs.contains(StaticProperty.USERDEFAULT_Various_Charts)
        self.entitlementManager.hasMultiSharingFunc = purchasedProductIDs.contains(StaticProperty.USERDEFAULT_Multi_Sharing)
    }
    
    
    
    // 第三阶段，当购买的项目发生在别的设备、或者订阅的到期了等等，需要增加监听
    private var updates: Task<Void, Never>? = nil
    
//    init() {
//        updates = observeTransactionUpdates()
//    }
    
    deinit {
        updates?.cancel()
    }
    
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await _ in Transaction.updates {
                await self.updatePurchasedProducts()
            }
        }
    }
    
    
    
    
    
    // 第四阶段，Extension中访问购买，然后这个参数里面的信息，在第二阶段的更新方法里面更新了
    private let entitlementManager: EntitlementManager
    
    init(entitlementManager: EntitlementManager) {
        self.entitlementManager = entitlementManager
    }
}


