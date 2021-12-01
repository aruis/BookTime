//
//  Persistence.swift
//  BookTime
//
//  Created by Liu Rui on 2021/11/30.
//

import CoreData
import UIKit

struct BookPersistenceController {
    static let shared = BookPersistenceController()

    static var preview: BookPersistenceController = {
        let result = BookPersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        let book = Book(context:viewContext)
        
        book.image = (UIImage(named: "python")?.jpegData(compressionQuality: 1.0))!
        book.name = "漫画Python：编程入门超简单"
        book.author = "[日]菅谷充"
        book.isDone = true
        book.readMinutes = 10000
        book.createTime = Date()
        
        let book2 = Book(context:viewContext)
        
        book2.image = (UIImage(named: "tongji")?.jpegData(compressionQuality: 1.0))!
        book2.name = "统计学图鉴"
        book2.author = "[日]栗原伸一 [日]丸山敦史"
//        book2.isDone = true
        book2.readMinutes = 1000
        book2.createTime = Date()

        
        let book3 = Book(context:viewContext)
        
        book3.image = (UIImage(named: "xiandai")?.jpegData(compressionQuality: 1.0))!
        book3.name = "简单线性代数：漫画线性代数入门"
        book3.author = "[日]键本聪"
        book3.isDone = false
        book3.readMinutes = 2000
        book3.createTime = Date()

        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    static var testData:[Book]? = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Book")
        return try? BookPersistenceController.preview.container.viewContext.fetch(fetchRequest) as? [Book]
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "BookTime")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                Typical reasons for an error here include:
                * The parent directory does not exist, cannot be created, or disallows writing.
                * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                * The device is out of space.
                * The store could not be migrated to the current model version.
                Check the error message to determine what the actual problem was.
                */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }
}
