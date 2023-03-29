//
//  PurchaseItemView.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/29.
//

import SwiftUI
import StoreKit

struct PurchaseItemView: View {
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
                if product.id == "various_charts" {
                    Text("\(purchaseManager.hasVariousChartsFunc ? "已购买" : "\(product.displayPrice)")")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                } else if product.id == "Multi_Sharing" {
                    Text("\(purchaseManager.hasMultiSharingFunc ? "已购买" : "\(product.displayPrice)")")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
            }
            .disabled((product.id == "various_charts" && purchaseManager.hasVariousChartsFunc) || (product.id == "Multi_Sharing" && purchaseManager.hasMultiSharingFunc))
        }
    }
}
