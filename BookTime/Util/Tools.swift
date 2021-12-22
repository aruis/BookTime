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
        print(preferredLang)
        
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
