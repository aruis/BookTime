//
//  Persistence.swift
//  BookTime
//
//  Created by Liu Rui on 2021/11/30.
//

import CoreData
import CloudKit
import UIKit

struct BookPersistenceController {
    let privateDB = CKContainer.default().privateCloudDatabase
    static let shared = BookPersistenceController()
    
    let store = NSUbiquitousKeyValueStore()
    
    static var preview: BookPersistenceController = {
        let result = BookPersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
                
        let book = Book(context:viewContext)
        book.image = (UIImage(named: "python")?.jpegData(compressionQuality: 1.0))!
        book.name = "漫画Python：编程入门超简单"
        book.author = "[日]菅谷充"
        book.isDone = false
        book.readMinutes = 200
        book.createTime = Date()
//
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }

        
        let book2 = Book(context:viewContext)
        book2.image = (UIImage(named: "tongji")?.jpegData(compressionQuality: 1.0))!
        book2.name = "统计学图鉴"
        book2.author = "[日]栗原伸一 [日]丸山敦史"
        //        book2.isDone = true
        book2.readMinutes = 200
        book2.createTime = Date()
//        
//        
//        let book3 = Book(context:viewContext)
//        book3.image = (UIImage(named: "xiandai")?.jpegData(compressionQuality: 1.0))!
//        book3.name = "简单线性代数：漫画线性代数入门"
//        book3.author = "[日]键本聪"
//        book3.isDone = false
//        book3.readMinutes = 2000
//        book3.createTime = Date()
        
        
        let now = Date()
        for i in 0...40{
            let randomInt = Int.random(in: 1...10)
            
            
            if(randomInt > 1){
                let d =  Calendar.current.date(byAdding: .day, value: 0 - i, to: now)!.start()
                
                let readLog = ReadLog(context: viewContext)
                readLog.readMinutes =  Int16.random(in: 5...100)
                readLog.day = d
                
            }
            
        }
        
        
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
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "BookTime")
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
    
     func checkAndBuildTodayLog() -> ReadLog{
         let context = container.viewContext
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
    
    func  fetchBooksFromICloud () async ->[CKRecord] {
        var bookRecords:[CKRecord] = []
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Book", predicate: predicate)
        
        do {
            let results = try await privateDB.records(matching: query)
            
            for record in results.matchResults {
                bookRecords.append( try record.1.get())
            }
            
            return bookRecords
            
            // Process the records
            
        } catch {
            // Handle the error
        }
        
        return bookRecords
    }
    
    func fetchLogsFromICloud () async ->[CKRecord] {
        var bookRecords:[CKRecord] = []
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "ReadLog", predicate: predicate)
        
        do {
            let results = try await privateDB.records(matching: query)
            
            for record in results.matchResults {
                bookRecords.append( try record.1.get())
            }
            
            return bookRecords
            
            // Process the records
            
        } catch {
            // Handle the error
        }
        
        return bookRecords
    }
    
    func cleanCloud() async{
        
        
        let cloudContainer = CKContainer.default()
        let privateDB = cloudContainer.privateCloudDatabase
        
        let predicate = NSPredicate(value: true)
        let queryBook = CKQuery(recordType: "Book", predicate: predicate)
        let queryLog = CKQuery(recordType: "ReadLog", predicate: predicate)
        
        do {
            let results = try await privateDB.records(matching: queryBook)
            for record in results.matchResults {
                try await privateDB.deleteRecord(withID: record.1.get().recordID)
            }
            
            let results2 = try await privateDB.records(matching: queryLog)
            for record in results2.matchResults {
                try await privateDB.deleteRecord(withID: record.1.get().recordID)
            }
            
        } catch {
            
        }
        
        store.removeObject(forKey: "lastBackupTime")
    }

    func saveBookInICloud(book:Book){
        let record = CKRecord(recordType: "Book")
        record.setValue(book.id, forKey: "id")
        record.setValue(book.name, forKey: "name")
        record.setValue(book.author, forKey: "author")
        record.setValue(book.isDone, forKey: "isDone")
        record.setValue(book.readMinutes, forKey: "readMinutes")
        record.setValue(book.createTime, forKey: "createTime")
        record.setValue(book.firstReadTime, forKey: "firstReadTime")
        record.setValue(book.lastReadTime, forKey: "lastReadTime")
        record.setValue(book.doneTime, forKey: "doneTime")
        record.setValue(book.rating, forKey: "rating")
        record.setValue(book.readDays, forKey: "readDays")
        
        
        let imageFilePath = NSTemporaryDirectory() + book.name
        let imageFileURL = URL(fileURLWithPath: imageFilePath)
        try? book.image.write(to: imageFileURL)
        
        let imageAsset = CKAsset(fileURL: imageFileURL)
        record.setValue(imageAsset, forKey: "image")
        
        privateDB.save(record, completionHandler: { (record, error) -> Void  in
            
            if error != nil {
                print(error.debugDescription)
            }
            
            // Remove temp file
            try? FileManager.default.removeItem(at: imageFileURL)
        })
        
    }
    
    func saveLogInICloud(log:ReadLog){
        let record = CKRecord(recordType: "ReadLog")
        record.setValue(log.day, forKey: "day")
        record.setValue(log.readMinutes, forKey: "readMinutes")
        
        privateDB.save(record, completionHandler: { (record, error) -> Void  in
            
            if error != nil {
                print(error.debugDescription)
            }
            
        })
        
    }

    func tapLastBackuptime(){
        store.set(Date().format(format:"yyyy-MM-dd HH:mm:ss"), forKey: "lastBackupTime")
    }    

}
