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
    @State var lastBackupTime:String? = nil
    
    @State private var iCloudCanUse = false
    
    @State private var showCleanSheet = false
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
                        Button(action: {
                            showCleanSheet = true
                        }){
                            Text("\(Image(systemName: "exclamationmark.triangle.fill"))\t清除所有数据\(useiCloud ? "（含iCloud）":"")")
                        }
                        
                        
                        Toggle(isOn: $useiCloud) {
                            Text("\(Image(systemName: "icloud"))\t使用iCloud备份")
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
                .toast(isPresenting: $showDeleteAllSucToast,duration: 3,tapToDismiss: true){
                    AlertToast( type: .complete(.green), title: "所有数据已删除")
                }
            }
            .confirmationDialog("数据无价，请谨慎选择！", isPresented: $showCleanSheet, titleVisibility : .visible, actions: {
                Button("我要清除所有数据", role: .destructive) {
                    Task{
                        await cleanAllData()
                    }
                }
                
                Button("取消", role: .cancel) {
                    self.showCleanSheet = false
                }
            })
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
                        await  ctrl.cleanCloud()
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
        refreshLastBackuptime()
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
        store.removeObject(forKey: "lastBackupTime")
        
        refreshLastBackuptime()

    }
    
    
}
