//
//  Setting.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/4.
//

import SwiftUI
import CloudKit
import UniformTypeIdentifiers
import AlertToast

struct Setting: View {
    let monkeyStr = "$#*#$"
    let ctrl = BookPersistenceController.shared
    let generator = UINotificationFeedbackGenerator()
    let dateFormatter = ISO8601DateFormatter()
    
    @Environment(\.managedObjectContext) var context
    
    let store = NSUbiquitousKeyValueStore()
    
    @FetchRequest(entity: Book.entity(), sortDescriptors:[])
    var books: FetchedResults<Book>
    
    @FetchRequest(entity: ReadLog.entity(), sortDescriptors:[
        NSSortDescriptor(keyPath: \ReadLog.day, ascending: true)
    ])
    var logs: FetchedResults<ReadLog>
    
    @AppStorage("isRemind") var isRemind = false
    
    @AppStorage("remindDateHour") var reminDateHour = -1
    @AppStorage("remindDateMin") var reminDateMin = -1
    
    @State private var remindDate = Date().start()
    
    @AppStorage("targetMinPerday") var targetMinPerday = 45
    //    @AppStorage("useiCloud") var useiCloud = false
    private var useiCloud = false
    @AppStorage("isFirstBookCard") var isFirstBookCard = true
    @AppStorage("hasViewdWalkthrough") var hasViewdWalkthrough = false
    
    @State var showAbout = false
    @State var isShowToast = false
    @State var showDeleteCloudSucToast = false
    @State var showDeleteAllSucToast = false
    
    @State var sliderIsChange = false
    
    @AppStorage("lastBackupTime") var lastBackupTime:String = ""
    
    @State private var iCloudCanUse = false
    
    @State private var showCleanSheet = false
    @State private var showCloudSheet = false
    @State private var showDeleteCloudSheet = false
    
    @State private var document: BookTimeFileDoc = BookTimeFileDoc(message: "Hello, World!")
    @State private var isExporting: Bool = false
    @State private var isImporting: Bool = false
    
    @State private var toastString:String = ""
    
    @Environment(\.scenePhase) var scenePhase
    
    @State private var todayReadMin:Int16 = 0
    
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

                                                
                        Toggle("Reading Reminder", isOn: $isRemind).onChange(of: isRemind, perform: {value in
                            if value{
                                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                                    if success {
                                        if reminDateHour > -1 && reminDateMin > -1 {
                                            NotificationTool.add(hour: reminDateHour, minute: reminDateMin ,readedToday: todayReadMin > 0)
                                        }
                                    } else {
                                        isRemind = false
                                        Task{
                                            if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
                                                 await UIApplication.shared.open(appSettings)
                                            }
                                        }
                                    }
                                }
                            } else {
                                NotificationTool.cancel()
                            }
                                                        
                        })
                        .foregroundColor(.accentColor)
                        .onAppear{
                            checkNotificationAuth()
                        }
                        .onChange(of: scenePhase) { newPhase in
                                       if newPhase == .active {
                                           checkNotificationAuth()
                                       }
                        }
                        
                        if isRemind {
                            DatePicker("Reminder Time", selection: $remindDate, displayedComponents: .hourAndMinute)
                                .foregroundColor(.accentColor)
                                .onChange(of: remindDate, perform: {date in
                                    let calendar = Calendar.current
                                    
                                    reminDateHour = calendar.component(.hour, from: date)
                                    reminDateMin = calendar.component(.minute, from: date)
                                    
                                    NotificationTool.add(hour: reminDateHour, minute: reminDateMin,readedToday: todayReadMin > 0)
                                                                        
                                })
                                .onAppear{
                                    if reminDateMin > -1 && reminDateHour > -1 {
                                        remindDate  = Calendar.current.date(bySettingHour: reminDateHour, minute: reminDateMin,second: 0, of: Date())!
                                    }                                    
                                }
                        }
                        
//                                    .labelsHidden()

                    }
                    //                    Section(header: Text("About data"),footer: Text(!iCloudCanUse ? "iCloud is not enabled on your device" : lastBackupTime.isEmpty ? "" : "Last backup time: \(lastBackupTime)")) {
                    Section(header: Text("About data"),footer: Text(!iCloudCanUse ? "iCloud is not enabled on your device" : "Your data is automatically syncing via iCloud")) {
                        
                        Button(action: exportData){
                            Label("Export Data",systemImage: "arrow.up.doc")
                        }
                        
                        Button( action: {
                            isImporting = true
                        }){
                            Label("Import Data",systemImage: "arrow.down.doc")

                        }
                        
                        
                        Button(role: .destructive,action: {
                            generator.notificationOccurred(.warning)
                            showCleanSheet = true
                        }){
                            Label(String(localized:"Clear All Data") + (useiCloud ? String(localized: "(Include iCloud)")  :""),systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.red.opacity(0.85))
                        }


                        
                        
                        //                        Toggle(isOn: $useiCloud) {
                        //                            Text("\(Image(systemName: "icloud"))\tUse iCloud to backup data")
                        //                        }.onChange(of: useiCloud, perform: { value in
                        //                            if(useiCloud){
                        //                                Task{
                        //                                    await  iCloudStart()
                        //                                }
                        //                            }else{
                        //                                showDeleteCloudSheet = true
                        //                            }
                        //                        }).disabled(!iCloudCanUse)
                    }
                    
                }
                .onAppear(perform: {
//                    UIScrollView.appearance().bounces = false
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
                .toast(isPresenting: $isShowToast,duration: 3,tapToDismiss: true){
                    AlertToast( type: .complete(.green), title:toastString)
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
            .fileExporter(
                isPresented: $isExporting,
                document: document,
                contentType: UTType.commaSeparatedText,
                defaultFilename: "books"
            ) { result in
                if case .success = result {
//                    print(result)
                    // Handle success.
                } else {
                    // Handle failure.
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [UTType.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                do {
                    guard let selectedFile: URL = try result.get().first else { return }
                    
                    //trying to get access to url contents
                    if (CFURLStartAccessingSecurityScopedResource(selectedFile as CFURL)) {
                        
                        guard let message = String(data: try Data(contentsOf: selectedFile), encoding: .utf8) else { return }
                        
                        let lines = message.split(separator: "\n")
                        
                        if(lines.count == 2) {return}
                        
                        var importBookCount = 0
                        
                        for str in  lines[1...]{
                            let cells = str.split(separator: ",",omittingEmptySubsequences: false).map{String($0)}
                            
                            if(cells[0] == "day"){
                                continue
                            }
                            
                            if(cells.count > 2){ // 书籍信息
                                let id = cells[0]
                                let name = cells[1].replacingOccurrences(of: monkeyStr, with: ",")
                                let author = cells[2].replacingOccurrences(of: monkeyStr, with: ",")
                                let image = Data(base64Encoded: String(cells[3])) ?? UIImage(named: "camera")!.pngData()!
                                let isDone = cells[4] == "true"
                                let readMinutes = Int64( cells[5]) ?? 0
                                let createTime =  dateFormatter.date(from: String(cells[6]))
                                let firstReadTime =  dateFormatter.date(from: String(cells[7]))
                                let lastReadTime =  dateFormatter.date(from: String(cells[8]))
                                let doneTime =  dateFormatter.date(from: String(cells[9]))
                                let rating = Int16( cells[10]) ?? 0
                                let readDays = Int16(cells[11]) ?? 0
                                let status = Int16(cells[13]) ?? 1
                                
                                let matchBook = books.first(where: {$0.id == id})
                                
                                if let book = matchBook { //书存在
                                    if readMinutes > book.readMinutes
                                        && readDays >= book.readDays{
                                        book.readMinutes = readMinutes
                                        book.lastReadTime = lastReadTime
                                        
                                        book.isDone = isDone
                                        book.rating = rating
                                        book.readDays = readDays
                                        book.status = status
                                        
                                    }
                                } else {//书不存在
                                    let book  = Book(context: context)
                                    book.id = id
                                    book.name = name
                                    book.author = author
                                    book.image = image
                                    book.isDone = isDone
                                    book.readMinutes = readMinutes
                                    book.createTime = createTime ?? Date()
                                    book.firstReadTime = firstReadTime
                                    book.lastReadTime = lastReadTime
                                    book.doneTime = doneTime
                                    book.rating = rating
                                    book.readDays = readDays
                                    book.status = status
                                    
                                    if(cells.count == 13){
                                        book.tags = cells[12].replacingOccurrences(of: monkeyStr, with: ",")
                                    }
                                    
                                    importBookCount+=1
                                }
                                                                
                            }else{ // 日志信息
                                let day = dateFormatter.date(from: String(cells[0]))
                                let readMinutes = Int16(cells[1]) ?? 0
                                
                                if let day = day {
                                    let matchLog = logs.first(where: {$0.day == day})
                                    
                                    if let log = matchLog{
                                        if(readMinutes > log.readMinutes){
                                            log.readMinutes = readMinutes
                                        }
                                        
                                    }else {
                                        let log = ReadLog(context:context)
                                        log.day = day
                                        log.readMinutes = readMinutes
                                        
                                    }

                                }
                            }
                                                                                                         
                            
                        }
                        
                        DispatchQueue.main.async {
                            do{
                                try context.save()
                                showToast(String(localized: "\(importBookCount) book has been imported"))
                            }catch{
                                print(error)
                            }
                        }
                                                                       
                        
                        //done accessing the url
                        CFURLStopAccessingSecurityScopedResource(selectedFile as CFURL)
                    }
                    else {
                        print("Permission error!")
                    }
                } catch {
                    // Handle failure.
//                    print(error.localizedDescription)
                }
            }
        }
        .navigationViewStyle(.stack)
        .task {
            checkIfICloudCanUse()
        }
        .onAppear{
            let readLog = BookPersistenceController.shared.checkAndBuildTodayLog()
            todayReadMin = readLog.readMinutes
        }
        
        
    }
    
    func checkNotificationAuth(){
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            if isRemind && settings.authorizationStatus != .authorized{
                isRemind = false
            }
        }
    }
    
    func exportData(){
        var str = "id,name,author,image,isDone,readMinutes,createTime,firstReadTime,lastReadTime,doneTime,rating,readDays,tags,status\n"
        for book in books{
            str.append("\(book.id),")
            str.append("\(book.name.replacingOccurrences(of: ",", with: monkeyStr)),")
            if let author = book.author{
                str.append("\(author.replacingOccurrences(of: ",", with: monkeyStr))")
            }
            str.append(",")
            str.append(book.image.base64EncodedString())
            str.append(",")
            str.append("\(book.isDone),")
            str.append("\(book.readMinutes),")
            str.append("\(dateFormatter.string(from: book.createTime)),")
            if let firstReadTime = book.firstReadTime {
                str.append("\(dateFormatter.string(from: firstReadTime))")
            }
            str.append(",")
            if let lastReadTime = book.lastReadTime {
                str.append("\(dateFormatter.string(from: lastReadTime))")
            }
            str.append(",")

            if let doneTime = book.doneTime {
                str.append("\(dateFormatter.string(from: doneTime))")
            }
            str.append(",")

            str.append("\(book.rating),")
            str.append("\(book.readDays),")
            if let tags = book.tags{
                str.append("\(tags.replacingOccurrences(of: ",", with: monkeyStr))")
            }
            str.append(",")
            str.append("\(book.status)")
            
            str.append("\n")
        }
        
        str.append("day,readMinutes")
        str.append("\n")
        
        for log in logs {
            str.append("\(dateFormatter.string(from: log.day))")
            str.append(",")
            str.append("\(log.readMinutes)")
            str.append("\n")
        }
        
        document.message = str
        
        isExporting = true

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
            book.tags = bookRecord.object(forKey: "tags") as? String
            
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
//                showToast = true
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
//        showToast = true
    }
    
    
    func cleanAllData() async{
        if(useiCloud){
            await ctrl.cleanCloud()
        }
        cleanLocal()
        showDeleteAllSucToast = true
        targetMinPerday = 45
        isFirstBookCard = true
        hasViewdWalkthrough = false
        isRemind = false
        reminDateHour = -1
        reminDateMin = -1
        NotificationTool.cancel()
        ctrl.cleanTodayLog()
        
        store.removeObject(forKey: "targetMinPerday")
        UserDefaults.standard.removeSuite(named: "group.com.aruistar.BookTime")
        
    }
    
    func showToast(_ text:String){
        toastString = text
        isShowToast  = true
    }
    
    
}
