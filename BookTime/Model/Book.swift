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
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var author: String?
    @NSManaged var image: Data
    @NSManaged var isDone: Bool
    @NSManaged var readMinutes: Int64
    @NSManaged var createTime: Date
    @NSManaged var firstReadTime: Date?
    @NSManaged var lastReadTime: Date?
    @NSManaged var doneTime: Date?
    @NSManaged var rating: Int16
    @NSManaged var readDays: Int16
}
