//
//  Book.swift
//  BookTime
//
//  Created by Liu Rui on 2021/11/30.
//

import Combine
import CoreImage
import CoreData

class Book:NSManagedObject , Identifiable{
    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var author: String?
    @NSManaged var tags: String?
    @NSManaged var image: Data
    @NSManaged var isDone: Bool
    
    @NSManaged var status: Int16
    
    @NSManaged var readMinutes: Int64
    @NSManaged var createTime: Date
    @NSManaged var firstReadTime: Date?
    @NSManaged var lastReadTime: Date?
    @NSManaged var doneTime: Date?
    @NSManaged var rating: Int16
    @NSManaged var readDays: Int16
}

enum BookStatus:Int16{
    case reading = 1
    case readed = 2
    case archive = 9
}
