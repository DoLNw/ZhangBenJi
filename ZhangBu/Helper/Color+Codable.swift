//
//  Color+Codable.swift
//  YueJi
//
//  Created by Jcwang on 2022/11/8.
//

import Foundation
import SwiftUI



extension Color {
    static let incomeColor = Color("IncomeColor")
}



// 此处使用的是，Color能够Core Data中通过String实现存储。


// 为了Codable
#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#elseif os(macOS)
import AppKit
#endif

fileprivate extension Color {
    #if os(macOS)
    typealias SystemColor = NSColor
    #else
    typealias SystemColor = UIColor
    #endif
    
    var colorComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        #if os(macOS)
        SystemColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        // Note that non RGB color will raise an exception, that I don't now how to catch because it is an Objc exception.
        #else
        guard SystemColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else {
            // Pay attention that the color should be convertible into RGB format
            // Colors using hue, saturation and brightness won't work
            return nil
        }
        #endif
        
        return (r, g, b, a)
    }
}

extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let r = try container.decode(Double.self, forKey: .red)
        let g = try container.decode(Double.self, forKey: .green)
        let b = try container.decode(Double.self, forKey: .blue)
        
        self.init(red: r, green: g, blue: b)
    }
    
    public func encode(to encoder: Encoder) throws {
        guard let colorComponents = self.colorComponents else {
            return
        }
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(colorComponents.red, forKey: .red)
        try container.encode(colorComponents.green, forKey: .green)
        try container.encode(colorComponents.blue, forKey: .blue)
    }
}



// 也是为了Codable，Swift可以encode那种Data
// https://nilcoalescing.com/blog/EncodeAndDecodeSwiftUIColor/
#if os(iOS)
typealias PlatformColor = UIColor
extension Color {
    init(platformColor: PlatformColor) {
        self.init(uiColor: platformColor)
    }
}
#elseif os(macOS)
typealias PlatformColor = NSColor
extension Color {
    init(platformColor: PlatformColor) {
        self.init(nsColor: platformColor)
    }
}
#endif

let color = Color(.sRGB, red: 0, green: 0, blue: 1, opacity: 1)

func encodeColor() throws -> Data {
    let platformColor = PlatformColor(color)
    return try NSKeyedArchiver.archivedData(
        withRootObject: platformColor,
        requiringSecureCoding: true
    )
}

func decodeColor(from data: Data) throws -> Color {
    guard let platformColor = try NSKeyedUnarchiver
            .unarchiveTopLevelObjectWithData(data) as? PlatformColor
        else {
            throw DecodingError.wrongType
        }
    return Color(platformColor: platformColor)
}

enum DecodingError: Error {
    case wrongType
}

// 为了SwiftUI Color能够转成UIColor
extension Color {
//    func uiColor() -> UIColor {
//        if #available(iOS 14.0, *) {
//            return UIColor(self)
//        }
//
//        let components = self.components()
//        return UIColor(red: components.r, green: components.g, blue: components.b, alpha: components.a)
//    }

//    private func components() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
//        let scanner = Scanner(string: self.description.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
//        var hexNumber: UInt64 = 0
//        var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0
//
//        let result = scanner.scanHexInt64(&hexNumber)
//        if result {
//            r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
//            g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
//            b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
//            a = CGFloat(hexNumber & 0x000000ff) / 255
//        }
//        return (r, g, b, a)
//    }
    
//    public func toHexString() -> String {
//        let scanner = Scanner(string: self.description.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
//        var hexNumber: UInt64 = 0
//        let result = scanner.scanHexInt64(&hexNumber)
//
//        return "#\(hexNumber)"
//    }
//
//    public init(hex: String) {
//            let r, g, b, a: CGFloat
//
//            if hex.hasPrefix("#") {
//                let start = hex.index(hex.startIndex, offsetBy: 1)
//                let hexColor = String(hex[start...])
//
//                if hexColor.count == 8 {
//                    let scanner = Scanner(string: hexColor)
//                    var hexNumber: UInt64 = 0
//
//                    if scanner.scanHexInt64(&hexNumber) {
//                        r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
//                        g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
//                        b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
//                        a = CGFloat(hexNumber & 0x000000ff) / 255
//
//                        self.init(uiColor: UIColor(red: r, green: g, blue: b, alpha: a))
//                        return
//                    }
//                }
//            }
//
//        self.init(uiColor: UIColor.red)
//    }
    
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            self.init(uiColor: .red)
            return
        }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0

        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            self.init(uiColor: .red)
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
    
    func toHexString() -> String {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return ""
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if a != Float(1.0) {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}

extension UUID: Identifiable {
    public var id: UUID { return self }
}
