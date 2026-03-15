//
//  Tools.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/22.
//

import Foundation

struct Tools{
    static    func isCN() -> Bool {
        //        let defs = UserDefaults.standard
        //        let languages = defs.object(forKey: "AppleLanguages")
        //        let preferredLang = (languages! as AnyObject).object(0)
        let preferredLang = Bundle.main.preferredLocalizations.first! as NSString
        //
//        print(preferredLang)
        
        switch String(describing: preferredLang) {
        case "en-US", "en-CN":
            return false
        case "zh-Hans-US","zh-Hans-CN","zh-Hant-CN","zh-TW","zh-HK","zh-Hans":
            return true
        default:
            return false
        }
    }
    
}

struct TimerSessionLogic {
    static func elapsedMinutes(since beginDate: Date, now: Date) -> Int {
        max(Int(now.timeIntervalSince(beginDate)) / 60, 0)
    }

    static func addedMinutes(elapsedMinutes: Int, persistedSessionMinutes: Int) -> Int {
        elapsedMinutes - persistedSessionMinutes
    }

    static func pendingMinutes(since beginDate: Date, now: Date, persistedSessionMinutes: Int) -> Int {
        let elapsedMinutes = elapsedMinutes(since: beginDate, now: now)
        return addedMinutes(elapsedMinutes: elapsedMinutes, persistedSessionMinutes: persistedSessionMinutes)
    }

    static func activeLogDay(for now: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: now)
    }

    static func didDayChange(activeLogDay: Date, now: Date, calendar: Calendar = .current) -> Bool {
        !calendar.isDate(activeLogDay, inSameDayAs: now)
    }

    static func isGoalHit(targetMinutesPerDay: Int, readMinutes: Int) -> Bool {
        targetMinutesPerDay > 0 && readMinutes >= targetMinutesPerDay
    }
}
