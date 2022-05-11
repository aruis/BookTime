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
    
    static func add(hour:Int,minute:Int){
        cancel()
        
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Reading Reminder")
        content.subtitle = String(localized: "Reading time is here, let's read it.😄") 
        content.sound = UNNotificationSound.default

        // show this notification five seconds from now
//                            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        
        
        var date = DateComponents()
        date.hour = hour
        date.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
                
        // choose a random identifier
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)

    }
    
    static func cancel(){
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
