//
//  NotificationHelper.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/19.
//

import Foundation
import NotificationCenter

// 因为通知涉及金额，
// 1、所以需要在AccountList中删除的时候重新设置通知，
// 2、AddDayAccountView中添加还有修改的时候重新设置通知，
// 3、然后就是SettingView开启通知的时候设置

// 设置通知
// 在每天一定时候设置通知提醒，提醒今日已经消费，然后记录今天未记录的。当然还需要放入后面天的通知，因为避免后面天不打开app。
// shouldRepeat为false，为今天的通知；shouldRepeat为true，是后面天的通知
class NotificationHelper {
    static func editNotification(savedDailyReportTime: Double, todayPrice: Double) -> Bool {
        let dailyReportTime = Date(timeIntervalSinceReferenceDate: savedDailyReportTime)
        
        let noti1 = NotificationHelper.addNotificationRequest(reportDate: dailyReportTime, price: 0.0, shouldRepeat: true)
        var noti2 = true   // 如果今天不需要通知了，那么这个需要是true
        
        let now = Date()
        if (dailyReportTime.hour * 60 + dailyReportTime.minute) > (now.hour * 60 + now.minute) {
            noti2 = NotificationHelper.addNotificationRequest(reportDate: dailyReportTime, price: todayPrice, shouldRepeat: false)
        }
        
        return noti1 && noti2
    }
    
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
        content.body = shouldRepeat ? "赶快来记录今日消费吧～" : "今日已消费\(String(format: "%.2f", price))元，点击记录今日新消费～"
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
