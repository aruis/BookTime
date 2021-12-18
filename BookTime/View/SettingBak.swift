//
//  Setting.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/4.
//

import SwiftUI
import CloudKit

struct SettingBak: View {
    let privateDB = CKContainer.default().privateCloudDatabase
    
    
    @Environment(\.managedObjectContext) var context
    
    let store = NSUbiquitousKeyValueStore()
    
    @FetchRequest(entity: Book.entity(), sortDescriptors:[])
    var books: FetchedResults<Book>
    
    @FetchRequest(entity: ReadLog.entity(), sortDescriptors:[])
    var logs: FetchedResults<ReadLog>
    
    @AppStorage("targetMinPerday") var targetMinPerday = 45
    @AppStorage("useiCloud") var useiCloud = false
    
    
    @State var showAbout = false
    @State var showToast = false
    @State var showDeleteCloudSucToast = false
    
    @State var sliderIsChange = false
    @State var lastBackupTime:String? = nil
    
    @State private var iCloudCanUse = false
    
    @State private var showCloudSheet = false
    @State private var showDeleteCloudSheet = false
    
    private var greeting:String{
        get {
            let value = targetMinPerday
            if(value > 240){
                return "书籍是人类进步的阶梯，\n但阶梯不是目的，两侧的风景才是。"
            }
            if(value > 180){
                return "为革命，保护视力，眼保健操，请自行脑补。"
            }
            if(value > 120){
                return "自古英雄惜英雄，请收下作者的膝盖。"
            }
            if(value > 90){
                return "道之所在，虽千万人吾往矣。"
            }
            if(value > 60){
                return "路漫漫其修远兮，吾将上下而求索。 "
            }
            if(value > 45){
                return "真的猛士，敢于直面惨淡的人生，敢于正视淋漓的鲜血。"
            }
            if(value > 30){
                return "您已经打败了全国99%的非用户。"
            }
            if(value > 15){
                return "不积跬步，无以至千里。"
            }
            if(value > 1){
                return "好的开始=成功*1/2，好的目标=好的开始*1/2。"
            }
            if(value == 0){
                return "菩提本无树，明镜亦非台。"
            }
            return ""
        }
    }
    
    
    var intProxy: Binding<Double>{
        Binding<Double>(get: {
            return Double(targetMinPerday)
        }, set: {
            targetMinPerday = Int($0)
            store.set(Int64( targetMinPerday), forKey: "targetMinPerday")
        })
    }
    
    var body: some View {
        NavigationView {
            
            VStack {
                VStack(){
                    Text(targetMinPerday.asString())
                        .font(.system(size: 100)).fontWeight(.light).monospacedDigit()
                    
                    Text(greeting)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .opacity(sliderIsChange ? 0 : 1)
                    
                    
                }
                .frame(height:170,alignment: .top)
                .animation(.default, value: targetMinPerday)
                
                Form {
                    
                    Section(header: Text("每日阅读目标")) {
                        Slider(value: intProxy, in: 0...360, step: 5,onEditingChanged: { editing in
                            self.sliderIsChange = editing
                        })
                    }
                    
                    Section(header: Text("数据相关"),footer: Text(!iCloudCanUse ? "iCloud在您的设备上未启用" : lastBackupTime == nil ? "" : "上次备份时间：\(lastBackupTime!)")) {
                        Toggle(isOn: $useiCloud) {
                            Text("使用iCloud备份")
                        }.onChange(of: useiCloud, perform: { value in
                            if(useiCloud){
                                Task{
                                    await  iCloudStart()
                                }
                            }else{
                                showDeleteCloudSheet = true
                            }
                        }).disabled(!iCloudCanUse)
                    }
                    
                }
                .onAppear(perform: {
                    UIScrollView.appearance().bounces = false
                })
                .navigationTitle("设置")
                .toolbar{
                    Button(action: {
                        self.showAbout = true
                    }){
                        Image(systemName: "lightbulb")
                    }
                    
                }
                .sheet(isPresented: $showAbout){
                    About()
                }
                .toast(isPresenting: $showToast,duration: 3,tapToDismiss: true){
                    AlertToast( type: .complete(.green), title: "同步完成")
                }
                .toast(isPresenting: $showDeleteCloudSucToast,duration: 3,tapToDismiss: true){
                    AlertToast( type: .complete(.green), title: "iCloud数据已删除")
                }
            }
            
            .confirmationDialog("数据无价，请谨慎选择！", isPresented: $showCloudSheet, titleVisibility : .visible, actions: {
                Button("本地向覆盖云端", role: .destructive) {
                    Task{
                        await  local2Cloud()
                    }
                    
                }
                Button("云端向本地覆盖", role: .destructive) {
                    Task{
                        await cloud2Local()
                    }
                }
                Button("取消", role: .cancel) {
                    self.showCloudSheet = false
//                    useiCloud = false
                }
            })
            .confirmationDialog("关闭iCloud后，同时删除iCloud上的数据？", isPresented: $showDeleteCloudSheet, titleVisibility : .visible, actions: {
                Button("删除", role: .destructive) {
                    Task{
                        await  cleanCloud()
                        showDeleteCloudSucToast = true
                        store.removeObject(forKey: "lastBackupTime")
                        refreshLastBackuptime()
                    }
                }
                Button("保留", role: .destructive) {
                    
                }
                Button("取消", role: .cancel) {
                    self.showDeleteCloudSheet = false
//                    useiCloud = true
                }
            })
            
        }
        .task {
            checkIfICloudCanUse()
        }
        
        
    }
    
    func getTargetMinPerdayFromICloud(){
        let minute = store.longLong(forKey: "targetMinPerday")
        if(minute>0){
            targetMinPerday = Int(minute)
        }
        
    }
    
    func refreshLastBackuptime(){
        lastBackupTime =  store.string(forKey: "lastBackupTime")
    }
    
    func checkIfICloudCanUse(){
        CKContainer.default().accountStatus { accountStatus, error in
            iCloudCanUse =  accountStatus == .available
            if(iCloudCanUse){
                getTargetMinPerdayFromICloud()
                refreshLastBackuptime()
            }
        }
        
    }
    
    func iCloudStart() async{
        let bookRecords = await fetchBooksFromICloud()
        
        if(bookRecords.count == 0 ){ // 云端没数据，无脑local->cloud
            await  local2Cloud()
            
        }else if(books.count == 0){ // 本地无数据，无脑cloud->local
            await cloud2Local()
        }else{ // 用户选择
            showCloudSheet = true
        }
    }
    
    
    func cloud2Local() async{
        let bookRecords = await fetchBooksFromICloud()
        let logRecords = await fetchLogsFromICloud()
        for book in books {
            context.delete(book)
        }
        
        for log in logs{
            context.delete(log)
        }
        
        for bookRecord in bookRecords {
            let book  = Book(context: context)
            book.id = bookRecord.object(forKey: "id") as! String
            book.name = bookRecord.object(forKey: "name") as! String
            book.author = bookRecord.object(forKey: "author") as? String
            
            book.isDone = bookRecord.object(forKey: "isDone") as! Bool
            book.readMinutes = bookRecord.object(forKey: "readMinutes") as! Int64
            book.createTime = bookRecord.object(forKey: "createTime") as! Date
            book.firstReadTime = bookRecord.object(forKey: "firstReadTime") as? Date
            book.lastReadTime = bookRecord.object(forKey: "lastReadTime") as? Date
            book.doneTime = bookRecord.object(forKey: "doneTime") as? Date
            book.rating = bookRecord.object(forKey: "rating") as! Int16
            book.readDays = bookRecord.object(forKey: "readDays") as! Int16
            
            let imageFile:CKAsset? = bookRecord.object(forKey: "image") as? CKAsset
            
            if let file = imageFile {
                if let data = NSData(contentsOf: file.fileURL!){
                    book.image = data as Data
                }
            }
        }
        
        for logRecord in logRecords {
            let log = ReadLog(context:context)
            log.day = logRecord.object(forKey: "day") as! Date
            log.readMinutes = logRecord.object(forKey: "readMinutes") as! Int16
        }
        
        
        DispatchQueue.main.async {
            do{
                try context.save()
                showToast = true
            }catch{
                print(error)
            }
        }
        
        
    }
    
    func local2Cloud() async{
        await cleanCloud()
        
        for book in books{
            saveBookInICloud(book: book)
        }
        
        for log in logs{
            saveLogInICloud(log: log)
        }
        
        store.set(Date().format(format:"yyyy-MM-dd HH:mm:ss"), forKey: "lastBackupTime")
        refreshLastBackuptime()
        showToast = true
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
    
}
