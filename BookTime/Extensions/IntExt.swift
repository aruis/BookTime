//
//  IntExt.swift
//  BookTime
//
//  Created by Liu Rui on 2021/11/30.
//

import Foundation

extension Int{
    func asString() -> String{
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        //formatter.unitsStyle = .full
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad

        let formattedString = formatter.string(from: TimeInterval(self*60))!
        return formattedString.replacingOccurrences(of: "h", with: "小时")
                .replacingOccurrences(of: "m", with: "分钟")
        

    }
}


extension Int64{
    func asString() -> String{
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        //formatter.unitsStyle = .full
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad

        let formattedString = formatter.string(from: TimeInterval(self*60))!
        return formattedString.replacingOccurrences(of: "h", with: "小时")
                .replacingOccurrences(of: "m", with: "分钟")
        

    }
}
