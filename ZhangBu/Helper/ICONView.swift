//
//  ICONView.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/16.
//

import SwiftUI
import Charts

struct Amount: Identifiable {
    var date: Date
    var amount1: Double
    var amount2: Double
    var amount3: Double
    var id = UUID()
}

var date: [Amount] = [
    .init(date: Date().addingTimeInterval(86400 * 0), amount1: 1.15, amount2: 1.75, amount3: 0),
    .init(date: Date().addingTimeInterval(86400 * 1), amount1: 1.34, amount2: 2.22, amount3: 0.73),
    .init(date: Date().addingTimeInterval(86400 * 2), amount1: 1.14, amount2: 1.23, amount3: 0.33),
    .init(date: Date().addingTimeInterval(86400 * 3), amount1: 1.42, amount2: 1.68, amount3: 1.23),
    .init(date: Date().addingTimeInterval(86400 * 4), amount1: 0.84, amount2: 1.42, amount3: 0.63),
    .init(date: Date().addingTimeInterval(86400 * 5), amount1: 0.84, amount2: 1.47, amount3: 0)
]

@available(iOS 16, *)
struct ICONView: View {
    var body: some View {
        Chart(date) { amount in
            BarMark(x: .value("price", amount.amount3), y: .value("Day", amount.date, unit: .day))
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .red]), startPoint: .leading, endPoint: .trailing))
            
//            LineMark(x: .value("Day", amount.date, unit: .day), y: .value("price", amount.amount1))
//                .symbol(by: .value("Day",  "111"))
//                .interpolationMethod(.catmullRom)
////                            .foregroundStyle(gradients[StaticProperty.MySelfName]!)
//                .foregroundStyle(.orange)
//                .foregroundStyle(by:.value("Name", "111"))
            
//            LineMark(x: .value("Day", amount.date, unit: .day), y: .value("price", amount.amount2))
//                .symbol(by: .value("Day",  "222"))
//                .interpolationMethod(.catmullRom)
////                            .foregroundStyle(gradients[StaticProperty.MySelfName]!)
//                .foregroundStyle(.red)
//                .foregroundStyle(by:.value("Name", "222"))
        }
        
//        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks {
                AxisGridLine()
                    .foregroundStyle(Color.accentColor)
            }
        }
        .chartYAxis(.hidden)
        .frame(width: 250, height: 300)
        .chartLegend(position: .top, alignment: .topTrailing) {
            Text("账本记")
                .font(.title)
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .red]), startPoint: .top, endPoint: .bottom))
        }
    }
}

//struct ICONView_Previews: PreviewProvider {
//    static var previews: some View {
//        ICONView()
//    }
//}
