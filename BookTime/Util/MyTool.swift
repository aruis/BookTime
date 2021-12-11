//
//  Tool.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/10.
//

import Foundation
import SwiftUI
import CoreData

struct MyTool{
//    @Environment(\.managedObjectContext) var context
    
    static func checkAndBuildTodayLog(context:NSManagedObjectContext) -> ReadLog{
        let fetchReq = ReadLog.fetchRequest()
        
        
        fetchReq.predicate =  NSPredicate(format: "day = %@",  Date().start() as NSDate)
        fetchReq.fetchLimit = 1
        
        do {
            let today =  try context.fetch(fetchReq).first
            if let today = (today as? ReadLog){
                return today
            } else {
                let readLog = ReadLog(context: context)
                readLog.readMinutes = 0
                readLog.day = Date().start()

                return readLog
            }
            
        } catch let error as NSError {
          print("Could not fetch. \(error), \(error.userInfo)")
        }

        return ReadLog()
    }

}
