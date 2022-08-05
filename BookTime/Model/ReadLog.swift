//
//  ReadLog.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/10.
//

import CoreData

class ReadLog:NSManagedObject{    
    @NSManaged var day:Date
    @NSManaged var readMinutes:Int
}
