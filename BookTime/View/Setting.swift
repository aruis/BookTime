//
//  Setting.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/4.
//

import SwiftUI
import CloudKit

struct Setting: View {
    let ctrl = BookPersistenceController.shared
    let generator = UINotificationFeedbackGenerator()
//    let privateDB = CKContainer.default().privateCloudDatabase
    
    @Environment(\.managedObjectContext) var context
    
    let store = NSUbiquitousKeyValueStore()
    
    @FetchRequest(entity: Book.entity(), sortDescriptors:[])
    var books: FetchedResults<Book>
    
    @FetchRequest(entity: ReadLog.entity(), sortDescriptors:[])
    var logs: FetchedResults<ReadLog>
    
    @AppStorage("targetMinPerday") var targetMinPerday = 45
    @AppStorage("useiCloud") var useiCloud = false
    @AppStorage("isFirstBookCard") var isFirstBookCard = true
    
    @State var showAbout = false
    @State var showToast = false
    @State var showDeleteCloudSucToast = false
    @State var showDeleteAllSucToast = false
    
    @State var sliderIsChange = false
    
    @AppStorage("lastBackupTime") var lastBackupTime:String = ""
    
    @State private var iCloudCanUse = false
    
    @State private var showCleanSheet = false
    @State private var showCloudSheet = false
    @State private var showDeleteCloudSheet = false
    
    private var greeting:String{
        get {
            if !Tools.isCN(){
                return ""
            }
            
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
                    
                    Section(header: Text("Daily reading goal")) {
                        Slider(value: intProxy, in: 0...360, step: 5,onEditingChanged: { editing in
                            self.sliderIsChange = editing
                        })
                    }
                    
                    Section(header: Text("About data"),footer: Text(!iCloudCanUse ? "iCloud is not enabled on your device" : lastBackupTime.isEmpty ? "" : "Last backup time: \(lastBackupTime)")) {
                        Button(action: {
                            generator.notificationOccurred(.warning)
                            showCleanSheet = true
                        }){
                            Text("\(Image(systemName: "exclamationmark.triangle.fill"))\tClear all data\(useiCloud ? String(localized: "（Include iCloud）")  :"")")
                        }
                        
                        
                        Toggle(isOn: $useiCloud) {
                            Text("\(Image(systemName: "icloud"))\tUse iCloud to backup data")
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
                .navigationTitle("Setting")
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
                    AlertToast( type: .complete(.green), title:String(localized: "Synchronization complete" ,comment: "同步完成"))
                }
                .toast(isPresenting: $showDeleteCloudSucToast,duration: 3,tapToDismiss: true){
                    AlertToast( type: .complete(.green), title: String(localized: "Data in iCloud has been deleted",comment:  "iCloud数据已删除") )
                }
                .toast(isPresenting: $showDeleteAllSucToast,duration: 3,tapToDismiss: true){
                    AlertToast( type: .complete(.green), title: String(localized: "All data has been deleted" ,comment: "所有数据已删除") )
                }
            }
            .confirmationDialog("Data is priceless, please choose carefully!", isPresented: $showCleanSheet, titleVisibility : .visible, actions: {
                Button("I want to clear all data", role: .destructive) {
                    Task{
                        await cleanAllData()
                    }
                }
                
                Button("Cancel", role: .cancel) {
                    self.showCleanSheet = false
                }
            })
            .confirmationDialog("Data is priceless, please choose carefully!", isPresented: $showCloudSheet, titleVisibility : .visible, actions: {
                Button("Overwrite local data to the cloud", role: .destructive) {
                    Task{
                        await  local2Cloud()
                    }
                    
                }
                Button("Overwrite cloud data to local", role: .destructive) {
                    Task{
                        await cloud2Local()
                    }
                }
                Button("Cancel", role: .cancel) {
                    self.showCloudSheet = false
                    //                    useiCloud = false
                }
            })
            .confirmationDialog("After turning off iCloud, delete the data on iCloud at the same time?", isPresented: $showDeleteCloudSheet, titleVisibility : .visible, actions: {
                Button("Delete", role: .destructive) {
                    Task{
                        await  ctrl.cleanCloud()
                        showDeleteCloudSucToast = true
                    }
                }
                Button("Keep", role: .destructive) {
                    
                }
                Button("Cancel", role: .cancel) {
                    self.showDeleteCloudSheet = false
                    //                    useiCloud = true
                }
            })
            
        }
        .navigationViewStyle(.stack)
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
        
    func checkIfICloudCanUse(){
        CKContainer.default().accountStatus { accountStatus, error in
            iCloudCanUse =  accountStatus == .available
            if(iCloudCanUse){
                getTargetMinPerdayFromICloud()
            }
        }
        
    }
    
    func iCloudStart() async{
        let bookRecords = await ctrl.fetchBooksFromICloud()
        
        if(bookRecords.count == 0 ){ // 云端没数据，无脑local->cloud
            await  local2Cloud()
            
        }else if(books.count == 0){ // 本地无数据，无脑cloud->local
            await cloud2Local()
        }else{ // 用户选择
            showCloudSheet = true
        }
    }
    
    func cleanLocal(){
        for book in books {
            context.delete(book)
        }
        
        for log in logs{
            context.delete(log)
        }
        
        DispatchQueue.main.async {
            do{
                try context.save()
            }catch{
                print(error)
            }
        }
    }
    
    
    func cloud2Local() async{
        cleanLocal()
        
        let bookRecords = await ctrl.fetchBooksFromICloud()
        let logRecords = await ctrl.fetchLogsFromICloud()
        
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
        await  ctrl.cleanCloud()
        
        for book in books{
            ctrl.saveBookInICloud(book: book)
        }
        
        for log in logs{
            ctrl.saveLogInICloud(log: log)
        }
        
        ctrl.tapLastBackuptime()
        showToast = true
    }
                
    
    func cleanAllData() async{
        if(useiCloud){
            await ctrl.cleanCloud()
        }
        cleanLocal()
        showDeleteAllSucToast = true
        targetMinPerday = 45
        isFirstBookCard = true
        
        store.removeObject(forKey: "targetMinPerday")

    }
    
    
}
