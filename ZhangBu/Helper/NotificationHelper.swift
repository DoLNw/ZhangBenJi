//
//  NotificationHelper.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/19.
//

import Foundation
import NotificationCenter

class NotificationHelper {
    static func editNotification(savedDailyReportTime: Double, todayPrice: Double) -> Bool {
        let dailyReportTime = Date(timeIntervalSinceReferenceDate: savedDailyReportTime)
        
        let noti1 = NotificationHelper.addNotificationRequest(reportDate: dailyReportTime, price: 0.0, shouldRepeat: true)
        var noti2 = false
        
        let now = Date()
        if (dailyReportTime.hour * 60 + dailyReportTime.minute) > (now.hour * 60 + now.minute) {
            noti2 = NotificationHelper.addNotificationRequest(reportDate: dailyReportTime, price: todayPrice, shouldRepeat: false)
        }
        
        return noti1 && noti2
    }
    
    // shouldRepeat为false，为今天的通知；shouldRepeat为true，是后面天的通知
    static private func addNotificationRequest(reportDate: Date, price: Double, shouldRepeat: Bool) -> Bool {
        let notificationCenter = UNUserNotificationCenter.current()
        
        // 首先取消之前的所有通知
        notificationCenter.removeAllPendingNotificationRequests()
        
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        
        dateComponents.hour = Calendar.current.component(.hour, from: reportDate)
        dateComponents.minute = Calendar.current.component(.minute, from: reportDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: shouldRepeat)
        
        let content = UNMutableNotificationContent()
        content.title = "今天消费金额出炉啦"
        content.body = shouldRepeat ? "赶快来记录今日消费吧～" : "今日已消费\(String(format: "%.2f", price))元，未记录的消费赶紧记录奥～"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        var alreadySettingReport = true
        notificationCenter.add(request) { (error) in
            if error != nil {
                alreadySettingReport = false
            } else {
                alreadySettingReport = true
                print("成功发送消息")
            }
        }
        
        return alreadySettingReport
    }
}
