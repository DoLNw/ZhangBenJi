//
//  CircleProgressView.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/30.
//

// [MyProgresViewPlayground.swift](https://gist.github.com/mindobix/b7d30783ff04d92230e9cd0dd990504f)

import SwiftUI

struct CircleProgressView: View {
    // DayAccount中每一个Record会有一个RecordTag，我这里从tag入手，先拿到所有的tag
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \RecordTag.createdDate, ascending: true)],
        animation: .default)
    var tags: FetchedResults<RecordTag>
    
    // DayACcount表示每一天的消费
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DayAccount.date, ascending: false)],
        animation: .default)
    var dayAccounts: FetchedResults<DayAccount>
    
    let currentSelectedDate: Date
    let currentSegment: SegmentationEnum
    
    
    
    
    var engelProgress: Double {
        var total = 0.0
        var foodPrice = 0.0
        
        for dayAccount in dayAccounts {
            for record in dayAccount.wrappedRecords {
                guard record.costOrIncome == false else {
                    continue
                }
                
                var canAdd = false
                
                switch currentSegment {
                case .daySeg:
                    if dayAccount.wrappedDate.isInSameDay(as: currentSelectedDate) {
                        canAdd = true
                    }
                case .weekSeg:
                    if dayAccount.wrappedDate.isInSameWeek(as: currentSelectedDate) {
                        canAdd = true
                    }
                case .monthSeg:
                    if dayAccount.wrappedDate.isInSameMonth(as: currentSelectedDate) {
                        canAdd = true
                    }
                case .yearSeg:
                    if dayAccount.wrappedDate.isInSameYear(as: currentSelectedDate) {
                        canAdd = true
                    }
                }
                
                if canAdd {
                    total += record.price
                    if let tag = record.belongTag, tag.wrappedTagName.contains("餐") {
                        foodPrice += record.price
                    }
                }
            }
        }
        
        if total == 0 {
            total = 1
        }
        return foodPrice / total
    }
    
    
    
    
    
    let gradientColors: [Color] = [Color(.red), Color(.blue)]
    let sliceSize = 0.25
    
    init(currentSelectedDate: Date, currentSegment: SegmentationEnum) {
        self.currentSelectedDate = currentSelectedDate
        self.currentSegment = currentSegment
    }
    
    var body: some View {
        HStack(alignment: .center) {
            GeometryReader { geometry in
                ZStack {
                    Group {
                        Circle()
                            .trim(from: 0, to: 1 - CGFloat(self.sliceSize))
                            .stroke(self.strokeGradient, style: self.strokeStyle(with: geometry))
                            .opacity(0.5)
                        Circle()
                            .trim(from: 0, to: (1 - CGFloat(self.sliceSize)) * CGFloat(self.engelProgress))
                            .stroke(self.strokeGradient, style: self.strokeStyle(with: geometry))
                            .opacity(0.5)
                    }.rotationEffect(.degrees(90) + .degrees(360 * self.sliceSize / 2))
                    
                    
                    if self.engelProgress >= 0.995 {
                        Image(systemName: "star.fill")
                            .font(.system(size: 0.4 * min(geometry.size.width, geometry.size.height), weight: .bold, design: .rounded))
                            .foregroundColor(Color.yellow)
                            .offset(y: -0.05 * min(geometry.size.width, geometry.size.height))
                    } else {
                        Text(self.percentageFormatter.string(from: self.engelProgress as NSNumber)!)
                            .font(.system(size: 0.3 * min(geometry.size.width, geometry.size.height), weight: .bold, design: .rounded))
                            .offset(y: -0.05 * min(geometry.size.width, geometry.size.height))
                    }
                }
                .offset(y: 0.1 * min(geometry.size.width, geometry.size.height))
            }
            .frame(width: 170, height: 170)
            .padding(50)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(20)
            
            Text("恩格尔系数，标签带“餐”标签的（食品）消费占总消费比值。")
                .font(.caption)
                .foregroundColor(Color(UIColor.systemGray))
        }
    }
    
    private let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }()
    
    private var strokeGradient: AngularGradient {
        AngularGradient(gradient: Gradient(colors: self.gradientColors),
                        center: .center, angle: .degrees(-10))
    }
    
    private func strokeStyle(with geometry: GeometryProxy) -> StrokeStyle {
       StrokeStyle(lineWidth: 0.12 * min(geometry.size.width, geometry.size.height),
                   lineCap: .round)
    }
}

//struct PreviewProgress: View {
//
//    @State var progress = 0.25
//
//    var body: some View {
//        ZStack {
//            VStack(spacing: 30) {
//                CircleProgressView(progress)
//                CircleProgressView(progress)
//                    .environment(\.colorScheme, .dark)
//
//                Button(action: increment) {
//                    Text("Increment Progress")
//                        .foregroundColor(.white)
//                        .padding(/*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
//                }
//                .background(Color(UIColor.systemGray))
//                .cornerRadius(4)
//            }
//
//
//        }
//        .padding(50)
//        .background(Color(UIColor.secondarySystemBackground))
//
//    }
//
//    private func increment() {
//        withAnimation {
//            self.progress += 0.25
//
//            if self.progress > 1.0 {
//                self.progress = 0.25
//            }
//        }
//    }
//}
//
//struct CircleProgressView_Previews: PreviewProvider {
//    static var previews: some View {
//        PreviewProgress()
//    }
//}
