//
//  DateExt.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/8.
//

import Foundation

extension Date {
    func text() -> String{
        return format("yyyy-MM-dd")
    }
    
    func format(_ format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        return dateformat.string(from: self)
    }
    
    func dayString() -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
//        dateFormatter.locale
        return dateFormatter.string(from: self)
    }
    
    func start() -> Date{
        var calendar = Calendar.current
        calendar.timeZone = NSTimeZone.local
        return calendar.startOfDay(for: self)
    }
    
    var dayOfYear: Int {
        return Calendar.current.ordinality(of: .day, in: .year, for: self)!
    }
    
    init (_ str:String){
           let dateFormatter = DateFormatter()
           dateFormatter.dateFormat = "yyyy-MM-dd"
           
           let target = dateFormatter.date(from: String(str))!
           self.init(timeIntervalSince1970: target.timeIntervalSince1970)
    }
    
    func getDaysInMonth() -> Int{
        let calendar = Calendar.current

        let dateComponents = DateComponents(year: calendar.component(.year, from: self), month: calendar.component(.month, from: self))
        let date = calendar.date(from: dateComponents)!

        let range = calendar.range(of: .day, in: .month, for: date)!
        let numDays = range.count

        return numDays
    }

}
