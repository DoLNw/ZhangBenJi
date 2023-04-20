//
//  PurchaseItemView.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/29.
//

import SwiftUI
import StoreKit

struct PurchaseItemView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var purchaseManager: PurchaseManager
    var product: Product
    
    var body: some View {
        HStack {
            Text("\(product.displayName)")
            
            Spacer()
            
            Button {
                Task {
                    do {
                        try await purchaseManager.purchase(product)
                    } catch {
                        print(error)
                    }
                }
            } label: {
                if product.id == StaticProperty.USERDEFAULT_Various_Charts {
                    Text("\(entitlementManager.hasVariousChartsFunc ? "已购买" : "\(product.displayPrice)")")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                } else if product.id == StaticProperty.USERDEFAULT_Multi_Sharing {
                    Text("\(entitlementManager.hasMultiSharingFunc ? "已购买" : "\(product.displayPrice)")")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
            }
            .disabled((product.id == StaticProperty.USERDEFAULT_Various_Charts && entitlementManager.hasVariousChartsFunc) || (product.id == StaticProperty.USERDEFAULT_Multi_Sharing && entitlementManager.hasMultiSharingFunc))
        }
    }
}
