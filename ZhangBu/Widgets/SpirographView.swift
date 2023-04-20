//
//  SpirographView.swift
//  DemoForSharingRecord
//
//  Created by Jcwang on 2023/3/9.
//

import SwiftUI

struct Spirograph: Shape {
    let innerRadius: Int
    let outerRadius: Int
    let distance: Int
    let startAmount: Double
    let endAmount: Double
    
    func gcd(_ a: Int, _ b: Int) -> Int {
        var a = a
        var b = b

        while b != 0 {
            let temp = b
            b = a % b
            a = temp
        }

        return a
    }
    
    func path(in rect: CGRect) -> Path {
        let divisor = gcd(innerRadius, outerRadius)
        let outerRadius = Double(self.outerRadius)
        let innerRadius = Double(self.innerRadius)
        let distance = Double(self.distance)
        let difference = innerRadius - outerRadius
        let startPoint = ceil(2 * Double.pi * outerRadius / Double(divisor)) * startAmount
        let endPoint = ceil(2 * Double.pi * outerRadius / Double(divisor)) * endAmount

        var path = Path()

        for theta in stride(from: startPoint, through: endPoint, by: 0.01) {
            var x = difference * cos(theta) + distance * cos(difference / outerRadius * theta)
            var y = difference * sin(theta) - distance * sin(difference / outerRadius * theta)

            x += rect.width / 2
            y += rect.height / 2

            if theta == startPoint {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}


struct SpirographView: View {
    @State private var innerRadius = Double.random(in: 50 ... 150)
    @State private var outerRadius = Double.random(in: 50 ... 150)
    @State private var distance = 150.0
    @State private var startAmount = 0.0
    @State private var endAmount = 0.02
    @State private var hue = Double.random(in: 0 ... 1)
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Spirograph(innerRadius: Int(innerRadius), outerRadius: Int(outerRadius), distance: Int(distance), startAmount: startAmount, endAmount: endAmount)
                .stroke(Color(hue: hue, saturation: 1, brightness: 1), lineWidth: 7)
                .frame(width: 300, height: 300)
                .onReceive(timer) { time in
                    startAmount += 0.0005
                    endAmount += 0.0005
                    
                    if startAmount >= 1 {
                        startAmount = 0
                        endAmount = 0
                        timer.upstream.connect().cancel()
                    }
                }
            
            Rectangle()
                .fill(Color.clear)
                .background(.ultraThinMaterial)
        }
//        VStack(spacing: 0) {
//            Spirograph(innerRadius: Int(innerRadius), outerRadius: Int(outerRadius), distance: Int(distance), startAmount: startAmount, endAmount: endAmount)
//                .stroke(Color(hue: hue, saturation: 1, brightness: 1), lineWidth: 1)
//                .frame(width: 300, height: 300)
//                .onReceive(timer) { time in
//                    startAmount += 0.001
//                    endAmount += 0.002
//
//                    if startAmount >= 1 {
//                        startAmount = 0
//                        timer.upstream.connect().cancel()
//                    }
//
//                }
//
//
////            Spacer()
////
////            Group {
////                Text("Inner radius: \(Int(innerRadius))")
////                Slider(value: $innerRadius, in: 10...150, step: 1)
////                    .padding([.horizontal, .bottom])
////
////                Text("Outer radius: \(Int(outerRadius))")
////                Slider(value: $outerRadius, in: 10...150, step: 1)
////                    .padding([.horizontal, .bottom])
////
////                Text("Distance: \(Int(distance))")
////                Slider(value: $distance, in: 1...150, step: 1)
////                    .padding([.horizontal, .bottom])
////
////                Group {
////                    Text("StartAmount: \(startAmount, format: .number.precision(.fractionLength(2)))")
////                    Slider(value: $startAmount.animation(
////                        .easeInOut(duration: 2)
////                    ))
////                        .padding([.horizontal, .bottom])
////
////
////                    Text("EndAmount: \(endAmount, format: .number.precision(.fractionLength(2)))")
////                    Slider(value: $endAmount)
////                        .padding([.horizontal, .bottom])
////                }
////
////                Text("Color")
////                Slider(value: $hue)
////                    .padding(.horizontal)
////            }
//        }
    }
}


//struct SpirographView_Previews: PreviewProvider {
//    static var previews: some View {
//        MySinVIew()
//    }
//}
//
//
//struct MySin: Shape {
//    let a: CGFloat
//    let b: CGFloat
//
//    func path(in rect: CGRect) -> Path {
//        var path = Path()
//
//        for number in stride(from: 0, to: 400, by: 0.01) {
//            let y = 500 * sin(a * number + b)
//            if number == 0 {
//                path.move(to: CGPoint(x: number, y: y))
//            } else {
//                path.addLine(to: CGPoint(x: number, y: y))
//            }
//        }
//
//        return path
//    }
//}
//
//struct MySinVIew: View {
//    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
//
//    @State var a: CGFloat = 0.05
//    @State var b: CGFloat = 3.2
//
//    var body: some View {
//        MySin(a: a, b: b)
//            .stroke(Color(hue: 0.2, saturation: 1, brightness: 1), lineWidth: 2)
//            .onReceive(timer) { time in
//                b += 0.01
//            }
//    }
//}
