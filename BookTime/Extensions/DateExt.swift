//
//  DateExt.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/8.
//

import Foundation

extension Date {
    func format(format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        return dateformat.string(from: self)
    }
    
    func start() -> Date{
        var calendar = Calendar.current
        calendar.timeZone = NSTimeZone.local
        return calendar.startOfDay(for: self)
    }
}
