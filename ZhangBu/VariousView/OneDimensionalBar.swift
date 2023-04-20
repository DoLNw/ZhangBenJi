//
//  OneDimensionalBar.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/24.
// [Swift-Charts-Examples/Swift Charts Examples/Charts/AppleCharts/OneDimensionalBar.swift](https://github.com/jordibruin/Swift-Charts-Examples/blob/main/Swift%20Charts%20Examples/Charts/AppleCharts/OneDimensionalBar.swift)



import SwiftUI
import Charts

/// A data series for the bars.
struct TagCost: Identifiable {
    let color: Color
    
    let category: String

    var price: Double

    var id: String { category }
}

@available(iOS 16.0, *)
struct OneDimensionalBar: View {
    // DayAccount中每一个Record会有一个RecordTag，我这里从tag入手，先拿到所有的tag
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \RecordTag.createdDate, ascending: true)],
        animation: .default)
    var tags: FetchedResults<RecordTag>
    
    let currentSelectedDate: Date
    let currentSegment: SegmentationEnum
    
//    @State var selectedPrice: Double?
    @State var selectedTag: String?
    
    var data: [TagCost] {
        var data = [TagCost]()
        
        for tag in tags {
            var tagCost = TagCost(color: tag.wrappedColor, category: tag.wrappedTagName, price: 0.0)
            for record in tag.wrappedRecords {
                guard record.costOrIncome == false else {
                    continue
                }
                
                if let dayAccount = record.belongDayAccount {
                    switch currentSegment {
                    case .daySeg:
                        if dayAccount.wrappedDate.isInSameDay(as: currentSelectedDate) {
                            tagCost.price += record.price
                        }
                    case .weekSeg:
                        if dayAccount.wrappedDate.isInSameWeek(as: currentSelectedDate) {
                            tagCost.price += record.price
                        }
                    case .monthSeg:
                        if dayAccount.wrappedDate.isInSameMonth(as: currentSelectedDate) {
                            tagCost.price += record.price
                        }
                    case .yearSeg:
                        if dayAccount.wrappedDate.isInSameYear(as: currentSelectedDate) {
                            tagCost.price += record.price
                        }
                    }
                }
            }
            data.append(tagCost)
        }
        
        return data
    }

//    @State var data = DataUsageData.example

    @State private var showLegend = true
    
    private var totalSize: Double {
        data.reduce(0) { $0 + $1.price }
    }

    var body: some View {
        chart
    }

    private var chart: some View {
        Chart(data, id: \.category) { element in
            Plot {
                BarMark(
                    x: .value("Price", element.price)
                )
                .annotation(position: .overlay, alignment: .center ,content: {
                    if self.selectedTag == element.category {
                        Text("\(element.price, specifier: "%.2F")")
                            .font(.caption)
                    }
                })
                .foregroundStyle(by: .value("Data Category", element.category))
            }
            .accessibilityLabel(element.category)
            .accessibilityValue("\(element.price, specifier: "%.2f")")
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())

                    .onTapGesture { location in
                        let currentX = location.x - geometry[proxy.plotAreaFrame].origin.x
                        guard currentX >= 0, currentX < proxy.plotAreaSize.width else {
                            return
                        }
                        
//                        let currentY = location.y - geometry[proxy.plotAreaFrame].origin.y
//                        guard currentY >= 0, currentY < proxy.plotAreaSize.height else {
//                            return
//                        }
//
//                        let location = CGPoint(x: currentX, y: currentY)

                        
                        
                        guard let selectedPrice = proxy.value(atX: currentX, as: Double.self) else {
                            
                            return
                        }
                        
//                        self.selectedPrice = selectedPrice
                        
                        let selectedTag = calculateSelectedTag(selectedPrice: selectedPrice)
                        // 就是本来已经显示了，再点击取消显示
                        
                        self.selectedTag = selectedTag == self.selectedTag ? nil : selectedTag
                    }
            }
        }
        .chartForegroundStyleScale(range: data.map({ $0.color}))
        .chartPlotStyle { plotArea in
            plotArea
                #if os(macOS)
                .background(Color.gray.opacity(0.2))
                #else
                .background(Color(.systemFill))
                #endif
                .cornerRadius(18)
        }
        .chartXAxis(.hidden)
        .chartYScale(range: .plotDimension(endPadding: -8))
        .chartLegend(position: .bottom, spacing: 8)
        .frame(height: 50)
        
    }
}

@available(iOS 16.0, *)
extension OneDimensionalBar {
    func calculateSelectedTag(selectedPrice: Double) -> String? {
        var total = 0.0
        
        for tagCost in data {
            if selectedPrice <= total + tagCost.price {
                return tagCost.category
            }
            
            total += tagCost.price
        }
        
        return nil
    }
}

//// MARK: - Preview
//
//@available(iOS 16.0, *)
//struct OneDimensionalBar_Previews: PreviewProvider {
//    static var previews: some View {
////        OneDimensionalBar(isOverview: true)
////        OneDimensionalBar(isOverview: false)
//        OneDimensionalBar(isOverview: true, currentSelectedDate: Date(), currentSegment: .yearSeg)
//    }
//}
