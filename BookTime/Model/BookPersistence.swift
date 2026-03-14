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

struct StatisticsSummary {
    let todayReadMin: Int
    let totalReadDay: Int
    let totalReadMin: Int
    let totalReadBook: Int
    let longHit: Int
    let fishDay: Int
    let totalReadDayYear: Int
    let totalReadMinYear: Int
    let totalReadBookYear: Int
    let totalReadDayMonth: Int
    let totalReadMinMonth: Int
    let totalReadBookMonth: Int
    let suggestedCustomDateBegin: Date?
    let suggestedCustomDateEnd: Date?
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
    
    private var todayLogObjectID: NSManagedObjectID? = nil
    
    func cleanTodayLog(){
        todayLogObjectID = nil
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
    
    func fetchStatisticsSummary(for date: Date = Date()) async -> StatisticsSummary {
        let context = container.newBackgroundContext()
        let now = date
        
        return await context.perform {
            let logRequest = NSFetchRequest<NSDictionary>(entityName: "ReadLog")
            logRequest.resultType = .dictionaryResultType
            logRequest.propertiesToFetch = ["day", "readMinutes"]
            logRequest.sortDescriptors = [
                NSSortDescriptor(key: "day", ascending: true)
            ]
            
            let bookRequest = NSFetchRequest<NSDictionary>(entityName: "Book")
            bookRequest.resultType = .dictionaryResultType
            bookRequest.propertiesToFetch = ["doneTime", "isDone"]
            bookRequest.predicate = NSPredicate(format: "isDone == YES AND doneTime != nil")
            
            var todayReadMin = 0
            var totalReadDay = 0
            var totalReadMin = 0
            var totalReadBook = 0
            var longHit = 0
            var fishDay = 0
            var totalReadDayYear = 0
            var totalReadMinYear = 0
            var totalReadBookYear = 0
            var totalReadDayMonth = 0
            var totalReadMinMonth = 0
            var totalReadBookMonth = 0
            var lastHitDay: Date? = nil
            var suggestedCustomDateBegin: Date? = nil
            var suggestedCustomDateEnd: Date? = nil
            
            do {
                let logResults = try context.fetch(logRequest)
                
                for result in logResults {
                    guard
                        let day = result["day"] as? Date,
                        let readMinutes = result["readMinutes"] as? Int,
                        readMinutes > 0
                    else { continue }
                    
                    if Calendar.current.isDateInToday(day) && readMinutes > todayReadMin {
                        todayReadMin = readMinutes
                    }
                    
                    if now.isSameYear(day) {
                        totalReadDayYear += 1
                        totalReadMinYear += readMinutes
                        
                        if now.isSameMonth(day) {
                            if suggestedCustomDateBegin == nil {
                                suggestedCustomDateBegin = day
                            }
                            totalReadDayMonth += 1
                            totalReadMinMonth += readMinutes
                        }
                    }
                    
                    totalReadDay += 1
                    totalReadMin += readMinutes
                    
                    if let lastHitDay {
                        let begin = lastHitDay.start()
                        let end = day.start()
                        let components = Calendar.current.dateComponents([.day], from: begin, to: end)
                        if components.day == 0 || components.day == 1 {
                            longHit += 1
                        } else {
                            longHit = 1
                        }
                    } else {
                        longHit = 1
                    }
                    
                    lastHitDay = day
                    suggestedCustomDateEnd = day
                }
                
                if let lastHitDay {
                    fishDay = Calendar.current.dateComponents([.day], from: lastHitDay, to: now).day ?? 0
                }
                
                let bookResults = try context.fetch(bookRequest)
                for result in bookResults {
                    guard let doneTime = result["doneTime"] as? Date else { continue }
                    
                    totalReadBook += 1
                    
                    if now.isSameYear(doneTime) {
                        totalReadBookYear += 1
                        
                        if now.isSameMonth(doneTime) {
                            totalReadBookMonth += 1
                        }
                    }
                }
            } catch let error as NSError {
                print("Could not fetch statistics summary. \(error), \(error.userInfo)")
            }
            
            return StatisticsSummary(
                todayReadMin: todayReadMin,
                totalReadDay: totalReadDay,
                totalReadMin: totalReadMin,
                totalReadBook: totalReadBook,
                longHit: longHit,
                fishDay: fishDay,
                totalReadDayYear: totalReadDayYear,
                totalReadMinYear: totalReadMinYear,
                totalReadBookYear: totalReadBookYear,
                totalReadDayMonth: totalReadDayMonth,
                totalReadMinMonth: totalReadMinMonth,
                totalReadBookMonth: totalReadBookMonth,
                suggestedCustomDateBegin: suggestedCustomDateBegin,
                suggestedCustomDateEnd: suggestedCustomDateEnd
            )
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
        let context = container.viewContext
        let today = Date().start()
        
        if let todayLogObjectID,
           let cachedLog = try? context.existingObject(with: todayLogObjectID) as? ReadLog,
           !cachedLog.isDeleted,
           cachedLog.day.isSameDay(today) {
            return cachedLog
        }
        
        let fetchReq = ReadLog.fetchRequest() as! NSFetchRequest<ReadLog>
        fetchReq.predicate = NSPredicate(format: "day = %@", today as NSDate)
        fetchReq.sortDescriptors = [NSSortDescriptor(keyPath: \ReadLog.day, ascending: true)]
                
        do {
            let todays = try context.fetch(fetchReq)
            if let primaryLog = todays.first {
                if todays.count > 1 {
                    let totalReadMin = todays.reduce(0) { $0 + $1.readMinutes }
                    primaryLog.readMinutes = totalReadMin
                    
                    for redundantLog in todays.dropFirst() {
                        context.delete(redundantLog)
                    }
                    
                    if context.hasChanges {
                        try? context.save()
                    }
                }
                
                todayLogObjectID = primaryLog.objectID
                return primaryLog
            } else {
                let readLog = ReadLog(context: context)
                readLog.readMinutes = 0
                readLog.day = today
                todayLogObjectID = readLog.objectID
                return readLog
            }
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        let readLog = ReadLog(context: context)
        readLog.readMinutes = 0
        readLog.day = today
        todayLogObjectID = readLog.objectID
        return readLog
    }
    
    func fetchBooksFromICloud() async throws -> [CKRecord] {
        try await fetchAllRecords(recordType: "Book")
    }
    
    func fetchLogsFromICloud() async throws -> [CKRecord] {
        try await fetchAllRecords(recordType: "ReadLog")
    }
    
    func cleanCloud() async throws {
        try await deleteAllRecords(recordType: "Book")
        try await deleteAllRecords(recordType: "ReadLog")
        
        store.removeObject(forKey: "lastBackupTime")
        lastBackupTime = ""
    }
    
    func saveBookInICloud(book: Book) async throws {
        let record = CKRecord(recordType: "Book", recordID: CKRecord.ID(recordName: book.id))
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
        
        defer {
            try? FileManager.default.removeItem(at: imageFileURL)
            if let thumbnailFileURL {
                try? FileManager.default.removeItem(at: thumbnailFileURL)
            }
        }
        
        _ = try await privateDB.modifyRecords(saving: [record], deleting: [], atomically: true)
    }
    
    func saveLogInICloud(log: ReadLog) async throws {
        let record = CKRecord(recordType: "ReadLog", recordID: CKRecord.ID(recordName: log.day.format("yyyy-MM-dd")))
        record.setValue(log.day, forKey: "day")
        record.setValue(log.readMinutes, forKey: "readMinutes")
        
        _ = try await privateDB.modifyRecords(saving: [record], deleting: [], atomically: true)
    }
    
    func tapLastBackuptime(){
        let time = Date().format("yyyy-MM-dd HH:mm:ss")
        store.set(time, forKey: "lastBackupTime")
        lastBackupTime = time
    }
    
    private func fetchAllRecords(recordType: String) async throws -> [CKRecord] {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        var records: [CKRecord] = []
        var nextBatch = try await privateDB.records(matching: query)
        
        while true {
            for matchResult in nextBatch.matchResults {
                records.append(try matchResult.1.get())
            }
            
            guard let cursor = nextBatch.queryCursor else {
                break
            }
            
            nextBatch = try await privateDB.records(continuingMatchFrom: cursor)
        }
        
        return records
    }
    
    private func deleteAllRecords(recordType: String) async throws {
        let records = try await fetchAllRecords(recordType: recordType)
        guard !records.isEmpty else { return }
        
        let recordIDs = records.map(\.recordID)
        _ = try await privateDB.modifyRecords(saving: [], deleting: recordIDs, atomically: false)
    }
    
}
