//
//  PurchaseView.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/29.
//

import SwiftUI
import StoreKit

struct PurchaseView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    
    var body: some View {
        VStack(spacing: 20) {
            // 展示出所有的购买项目
            ForEach(purchaseManager.products) { product in
                PurchaseItemView(product: product)
            }
            
            HStack {
                Spacer()
                
                // 恢复购买按钮
                Button {
                    Task {
                        do {
                            try await AppStore.sync()
                        } catch {
                            print(error)
                        }
                    }
                } label: {
                    Text("恢复购买")
                }
            }
            
        }.task {
            // 刚进来的时候，需要加载所有的购买项目
            do {
                try await purchaseManager.loadProducts()
            } catch {
                print(error)
            }
        }
    }
}
