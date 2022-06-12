//
//  NotificationTool.swift
//  BookTime
//
//  Created by Liu Rui on 2022/5/11.
//

import Foundation
import UserNotifications

struct NotificationTool{
    
    private static let identifier = "booktime-remind"    
    
    static func add(hour:Int,minute:Int,readedToday:Bool = false){
        cancel()
        
        if hour == -1 || minute == -1 {
            return
        }
        
        let now = Date()
        
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Reading Reminder")
        content.subtitle = String(localized: "You haven't read today. Take some time to read.😄")
        content.sound = UNNotificationSound.default
      
                
        var date = DateComponents()
        date.hour = hour
        date.minute = minute
        
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        
        var  first =  trigger.nextTriggerDate()

        if readedToday {
            // 下一次就是今天的
            if first!.formatted(.dateTime.dayOfYear()) == now.formatted(.dateTime.dayOfYear()){
                first = first?.advanced(by: 86400 )
            }
            
        }
        
        if let first = first{
            for i in 0...6 {
                let day =  first.advanced(by: TimeInterval(86400 * i) )
                let str = day.formatted(.iso8601.year().month().day().dateSeparator(.dash))
                            
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: day.timeIntervalSinceNow, repeats: false)
                let request = UNNotificationRequest(identifier: "\(identifier)-\(str)", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request)
            }
        }

    }
    
    static func  cancelToday(){
        let str = Date().formatted(.iso8601.year().month().day().dateSeparator(.dash))
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers:  ["\(identifier)-\(str)"])
    }
    
    static func cancel(){
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
