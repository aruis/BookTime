//
//  Persistence.swift
//  BookTime
//
//  Created by Liu Rui on 2021/11/30.
//

import CoreData
import CloudKit
import UIKit
import SwiftUI

struct BookReadSummary {
    let todayReadMin: Int
    let logInYear: [Int]
}

class BookPersistenceController {
    @AppStorage("lastBackupTime") var lastBackupTime:String = ""
    
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
        book.createTime = Date().addingTimeInterval(-1000)
        
        
        
        let book2 = Book(context:viewContext)
        book2.image = (UIImage(named: "tongji")?.jpegData(compressionQuality: 1.0))!
        book2.name = "统计学图鉴"
        book2.author = "[日]栗原伸一 [日]丸山敦史"
        book2.isDone = true
        book2.readMinutes = 200
        book2.createTime = Date().addingTimeInterval(-2000)
        
        
        let book3 = Book(context:viewContext)
        book3.image = (UIImage(named: "xiandai")?.jpegData(compressionQuality: 1.0))!
        book3.name = "简单线性代数：漫画线性代数入门"
        book3.author = "[日]键本聪"
        book3.isDone = false
        book3.readMinutes = 2000
        book3.createTime = Date()
        
        
        let now = Date()
        for i in 0...0{
            let randomInt = Int.random(in: 1...10)
            
            let d =  Calendar.current.date(byAdding: .day, value: 0 - i, to: now)!.start()
            
            let readLog = ReadLog(context: viewContext)
            readLog.readMinutes =  Int.random(in: 5...60)
            readLog.day = d
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
    
    let container: NSPersistentCloudKitContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "BookTime")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        //        guard let description = container.persistentStoreDescriptions.first else {
        //            fatalError("###\(#function): Failed to retrieve a persistent store description.")
        //        }
        container.persistentStoreDescriptions.forEach {
            $0.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
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
        
        //添加如下代码
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            fatalError("Failed to pin viewContext to the current generation:\(error)")
        }
    }
    
    private var todayLog:ReadLog? = nil
    
    func cleanTodayLog(){
        todayLog = nil
    }
    
    func fetchTags() async -> [Tag] {
        let context = container.newBackgroundContext()
        
        return await context.perform {
            let request = NSFetchRequest<NSDictionary>(entityName: "Book")
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = ["tags"]
            request.predicate = NSPredicate(format: "tags != nil AND tags != ''")
            
            do {
                let results = try context.fetch(request)
                var seen = Set<String>()
                var tags = [Tag]()
                
                for result in results {
                    guard let tagString = result["tags"] as? String else { continue }
                    
                    for rawTag in tagString.split(separator: ",") {
                        let name = String(rawTag).trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty, seen.insert(name).inserted else { continue }
                        tags.append(Tag(name: name))
                    }
                }
                
                return tags.sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
            } catch let error as NSError {
                print("Could not fetch tags. \(error), \(error.userInfo)")
                return []
            }
        }
    }
    
    func fetchReadSummary(for date: Date = Date()) async -> BookReadSummary {
        let context = container.newBackgroundContext()
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: date)) ?? date.start()
        let startOfNextYear = calendar.date(byAdding: .year, value: 1, to: startOfYear) ?? date
        
        return await context.perform {
            let request = NSFetchRequest<NSDictionary>(entityName: "ReadLog")
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = ["day", "readMinutes"]
            request.predicate = NSPredicate(
                format: "readMinutes > 0 AND day >= %@ AND day < %@",
                startOfYear as NSDate,
                startOfNextYear as NSDate
            )
            request.sortDescriptors = [
                NSSortDescriptor(key: "day", ascending: true)
            ]
            
            var logInYear = [Int](repeating: 0, count: 366)
            var todayReadMin = 0
            
            do {
                let results = try context.fetch(request)
                
                for result in results {
                    guard let day = result["day"] as? Date else { continue }
                    let readMinutes = result["readMinutes"] as? Int ?? 0
                    let index = day.dayOfYear - 1
                    
                    if index >= 0 && index < logInYear.count && readMinutes > logInYear[index] {
                        logInYear[index] = readMinutes
                    }
                    
                    if calendar.isDateInToday(day) && readMinutes > todayReadMin {
                        todayReadMin = readMinutes
                    }
                }
            } catch let error as NSError {
                print("Could not fetch read summary. \(error), \(error.userInfo)")
            }
            
            return BookReadSummary(todayReadMin: todayReadMin, logInYear: logInYear)
        }
    }
        
    func getAllTags() -> [Tag]{
        var tags:[Tag] = []
        
        let context = container.viewContext
        let fetchReq = Book.fetchRequest()

        do {
            let books =  try context.fetch(fetchReq)
            books.forEach({book in
                if let book = (book as? Book){
                    if let tagString = book.tags ,!tagString.isEmpty {
                        tagString.split(separator: ",").forEach{
                            let _tag = Tag(name: String($0))
                            if(tags.firstIndex(where: { tag in
                                tag.name == _tag.name
                            }) == nil){
                                tags.append(_tag)
                            }
                        }

                    }
                }
            })
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        
        return tags
    }
    
    func checkAndBuildTodayLog() -> ReadLog{
        if let todayLog = todayLog {
            if todayLog.day.isSameDay(Date()) && todayLog.readMinutes > 0{
                return todayLog
            }
        }
        
        let context = container.viewContext
        let fetchReq = ReadLog.fetchRequest()
        
        
        fetchReq.predicate =  NSPredicate(format: "day = %@",  Date().start() as NSDate)
                
        do {
            let todays = try context.fetch(fetchReq)
            if todays.count > 0 {
                
                var logs:[ReadLog] = []
                var totalReadMin = 0
                
                todays.forEach{ it in
                    let log:ReadLog = it as! ReadLog
                    totalReadMin += log.readMinutes
                    logs.append(log)
                }
                
                logs.first!.readMinutes = totalReadMin
                
                while logs.count > 1{
                    context.delete(logs.removeLast())
                }
                
                self.todayLog = logs.first
                return self.todayLog!
            } else {
                let readLog = ReadLog(context: context)
                readLog.readMinutes = 0
                readLog.day = Date().start()
                self.todayLog = readLog
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
        lastBackupTime = ""
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
        
        
        let tempBase = UUID().uuidString
        let imageFilePath = NSTemporaryDirectory() + tempBase + "-image"
        let imageFileURL = URL(fileURLWithPath: imageFilePath)
        try? book.image.write(to: imageFileURL)
        
        let imageAsset = CKAsset(fileURL: imageFileURL)
        record.setValue(imageAsset, forKey: "image")
        
        var thumbnailFileURL: URL? = nil
        if let thumbnail = book.thumbnailImage ?? book.image.makeThumbnailData() {
            let thumbnailFilePath = NSTemporaryDirectory() + tempBase + "-thumb"
            let url = URL(fileURLWithPath: thumbnailFilePath)
            try? thumbnail.write(to: url)
            record.setValue(CKAsset(fileURL: url), forKey: "thumbnailImage")
            thumbnailFileURL = url
        }
        
        privateDB.save(record, completionHandler: { (record, error) -> Void  in
            
            if error != nil {
                print(error.debugDescription)
            }
            
            // Remove temp file
            try? FileManager.default.removeItem(at: imageFileURL)
            if let thumbnailFileURL {
                try? FileManager.default.removeItem(at: thumbnailFileURL)
            }
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
        let time = Date().format("yyyy-MM-dd HH:mm:ss")
        store.set(time, forKey: "lastBackupTime")
        lastBackupTime = time
    }
    
}
