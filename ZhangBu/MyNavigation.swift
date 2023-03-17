//
//  MyNavigation.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/17.
//

import SwiftUI

struct MyNavigation<Content>: View where Content: View {
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        if #available(iOS 16, *) {
            NavigationStack(root: content)
        } else {
            NavigationView(content: content)
        }
    }
}
//
//struct MyNavigation_Previews: PreviewProvider {
//    static var previews: some View {
//        MyNavigation()
//    }
//}
