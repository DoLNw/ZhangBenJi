//
//  ThirdHelper.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/17.
//

import Foundation

extension Date {
    var isFirstMonthOfQuarter: Bool {
        Calendar.current.component(.month, from: self) % 3 == 1
    }
    var isFirstDayOfWeek: Bool {
        Calendar.current.component(.weekday, from: self) % 7 == 1 // 表示周日
    }
    var monthInYear: Int {
        Calendar.current.component(.month, from: self)
    }
    var year: Int {
        Calendar.current.component(.year, from: self)
    }
    var weekInMonth: Int {
        Calendar.current.component(.weekOfMonth, from: self)
    }
    var dayInMonth: Int {
        Calendar.current.component(.day, from: self)
    }
    
    func isEqual(to date: Date, toGranularity component: Calendar.Component, in calendar: Calendar = .current) -> Bool {
        calendar.isDate(self, equalTo: date, toGranularity: component)
    }
    
    func isInSameYear(as date: Date) -> Bool {
        isEqual(to: date, toGranularity: .year)
    }
    func isInSameMonth(as date: Date) -> Bool {
        isEqual(to: date, toGranularity: .month)
    }
    func isInSameWeek(as date: Date) -> Bool {
        isEqual(to: date, toGranularity: .weekOfYear)
    }
    
    func isInSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }
    
    var isInThisYear:  Bool { isInSameYear(as: Date()) }
        var isInThisMonth: Bool { isInSameMonth(as: Date()) }
        var isInThisWeek:  Bool { isInSameWeek(as: Date()) }

        var isInYesterday: Bool { Calendar.current.isDateInYesterday(self) }
        var isInToday:     Bool { Calendar.current.isDateInToday(self) }
        var isInTomorrow:  Bool { Calendar.current.isDateInTomorrow(self) }

        var isInTheFuture: Bool { self > Date() }
        var isInThePast:   Bool { self < Date() }
}
