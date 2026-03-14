//
//  Setting.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/4.
//

import SwiftUI
import CloudKit
import CoreData
import WidgetKit
import UniformTypeIdentifiers
import AlertToast

struct Setting: View {
    let monkeyStr = "$#*#$"
    let ctrl = BookPersistenceController.shared
    let generator = UINotificationFeedbackGenerator()
    let dateFormatter = ISO8601DateFormatter()
    
    @Environment(\.managedObjectContext) var context
    
    let keyStore = NSUbiquitousKeyValueStore()
    
    @AppStorage("isRemind") var isRemind = false
    
    @AppStorage("remindDateHour") var reminDateHour = -1
    @AppStorage("remindDateMin") var reminDateMin = -1
    
    @State private var remindDate = Date().start()
    
    @AppStorage("targetMinPerday") var targetMinPerday = 45
    @State private var _targetReadMin:CGFloat = 0
    
    @AppStorage("todayReadMin") var todayReadMin = 0
    //    @AppStorage("useiCloud") var useiCloud = false
    private var useiCloud = false
    @AppStorage("isFirstBookCard") var isFirstBookCard = true
    @AppStorage("hasViewdWalkthrough") var hasViewdWalkthrough = false
    
    @State var showAbout = false
    @State var isShowToast = false
    @State var showDeleteCloudSucToast = false
    
    @State var sliderIsChange = false
    
    @AppStorage("lastBackupTime") var lastBackupTime:String = ""
    
    @State private var iCloudCanUse = false
    
    @State private var showClearDataConfirmation = false
    @State private var showCloudSheet = false
    @State private var showDeleteCloudSheet = false
    
    @State private var document: BookTimeFileDoc = BookTimeFileDoc(message: "Hello, World!")
    @State private var isExporting: Bool = false
    @State private var isImporting: Bool = false
    @State private var isImportingData = false
    @State private var importProgress: Double = 0
    @State private var importProgressText = ""
    @State private var importPhase: ImportPhase = .idle
    @State private var successStatusCard: SuccessStatusCard? = nil
    @State private var successStatusCardTask: Task<Void, Never>? = nil
    
    @State private var toastString:String = ""
    
    @Environment(\.scenePhase) var scenePhase
    
    private let recommendedApps: [RecommendedApp] = [
        .init(
            name: "PinTime",
            taglineKey: "Mark your important moments",
            appStoreURL: URL(string: "https://apps.apple.com/app/id6757686170")!,
            assetName: "PinTimeLogo",
            tintColor: .indigo
        ),
        .init(
            name: "TimeBank",
            taglineKey: "Time is the only thing you truly own",
            appStoreURL: URL(string: "https://apps.apple.com/app/id6474505609")!,
            assetName: "TimeBankLogo",
            tintColor: .orange
        )
    ]
    
    
    
    private var greeting:String{
        get {
            let value = _targetReadMin
            if(value > 240){
                return String(localized: "setting.greeting.over240")
            }
            if(value > 180){
                return String(localized: "setting.greeting.over180")
            }
            if(value > 120){
                return String(localized: "setting.greeting.over120")
            }
            if(value > 90){
                return String(localized: "setting.greeting.over90")
            }
            if(value > 60){
                return String(localized: "setting.greeting.over60")
            }
            if(value > 45){
                return String(localized: "setting.greeting.over45")
            }
            if(value > 30){
                return String(localized: "setting.greeting.over30")
            }
            if(value > 15){
                return String(localized: "setting.greeting.over15")
            }
            if(value > 1){
                return String(localized: "setting.greeting.over1")
            }
            if(value == 0){
                return String(localized: "setting.greeting.zero")
            }
            return ""
        }
    }
    
    private var activeStatusCard: StatusCardState? {
        if isImportingData {
            return .progress(
                title: String(localized: "Importing Data"),
                message: importProgressText,
                phase: importPhase,
                progress: importProgress
            )
        }
        
        if let successStatusCard {
            return .success(successStatusCard)
        }
        
        return nil
    }
    
    
    var intProxy: Binding<Double>{
        Binding<Double>(get: {
            return Double(targetMinPerday)
        }, set: {
            targetMinPerday = Int($0)
            keyStore.set(targetMinPerday, forKey: "targetMinPerday")
        })
    }
    
    var body: some View {
        NavigationView {
            
            VStack {
                VStack(){
                    Text(Int(_targetReadMin).asString())
                        .font(.system(size: 100)).fontWeight(.light).monospacedDigit()
                    
                    Text(greeting)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .opacity(sliderIsChange ? 0 : 1)
//                        .animation(.default, value: targetMinPerday)
                    
                    
                }
                .frame(height:170,alignment: .top)
                
                
                Form {
                    
                    Section(header: Text("Daily reading goal")) {
                        Slider(value: $_targetReadMin, in: 0...360, step: 5,onEditingChanged: { editing in
                            self.sliderIsChange = editing
                            if !editing{
                                targetMinPerday = Int(_targetReadMin)
                                keyStore.set(targetMinPerday, forKey: "targetMinPerday")
                            }
                        })
                        .onAppear{
                            _targetReadMin = CGFloat(targetMinPerday)
                        }
                        .onChange(of: _targetReadMin, {
                            if Int(_targetReadMin) % 60 == 0 {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        })
                                                
                        Toggle("Reading Reminder", isOn: $isRemind).onChange(of: isRemind, {
                            if isRemind{
                                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                                    if success {
                                        if reminDateHour > -1 && reminDateMin > -1 {
                                            NotificationTool.add(hour: reminDateHour, minute: reminDateMin ,readedToday: todayReadMin > 0)
                                        }
                                    } else {
                                        isRemind = false
                                        Task { @MainActor in
                                            if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
                                                let reuslt = await UIApplication.shared.open(appSettings)
                                                print(reuslt)
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
                        .onChange(of: scenePhase) {
                                       if scenePhase == .active {
                                           checkNotificationAuth()
                                       }
                        }
                        
                        if isRemind {
                            DatePicker("Reminder Time", selection: $remindDate, displayedComponents: .hourAndMinute)
                                .foregroundColor(.accentColor)
                                .onChange(of: remindDate, {
                                    let calendar = Calendar.current
                                    
                                    reminDateHour = calendar.component(.hour, from: remindDate)
                                    reminDateMin = calendar.component(.minute, from: remindDate)
                                    
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
                    Section(header: Text(String(localized: "More Apps"))) {
                        ForEach(recommendedApps) { app in
                            Link(destination: app.appStoreURL) {
                                RecommendedAppRow(app: app)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    //                    Section(header: Text("About data"),footer: Text(!iCloudCanUse ? "iCloud is not enabled on your device" : lastBackupTime.isEmpty ? "" : "Last backup time: \(lastBackupTime)")) {
                    Section(
                        header: Text("About data"),
                        footer: Text(
                            !iCloudCanUse
                            ? String(localized: "iCloud is not enabled on your device")
                            : String(localized: "Your data is automatically syncing via iCloud")
                        )
                    ) {
                        
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
                            withAnimation(.spring(response: 0.22, dampingFraction: 0.92)) {
                                showClearDataConfirmation = true
                            }
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
                .overlay(alignment: .center) {
                    if showClearDataConfirmation {
                        ZStack {
                            Rectangle()
                                .fill(.black.opacity(0.16))
                                .ignoresSafeArea()
                            
                            ClearDataConfirmationCard(
                                onConfirm: {
                                    withAnimation(.easeOut(duration: 0.16)) {
                                        showClearDataConfirmation = false
                                    }
                                    Task {
                                        await cleanAllData()
                                    }
                                },
                                onCancel: {
                                    withAnimation(.easeOut(duration: 0.16)) {
                                        showClearDataConfirmation = false
                                    }
                                }
                            )
                            .padding(.horizontal, 24)
                        }
                        .transition(.opacity)
                    } else if let activeStatusCard {
                        ZStack {
                            Rectangle()
                                .fill(.black.opacity(activeStatusCard.blocksInteraction ? 0.12 : 0.02))
                                .ignoresSafeArea()
                                .allowsHitTesting(activeStatusCard.blocksInteraction)
                            
                            StatusCardView(state: activeStatusCard)
                                .padding(.horizontal, 24)
                        }
                        .transition(.opacity)
                    }
                }
                .toast(isPresenting: $isShowToast,duration: 3,tapToDismiss: true){
                    AlertToast( type: .complete(.green), title:toastString)
                }
                .toast(isPresenting: $showDeleteCloudSucToast,duration: 3,tapToDismiss: true){
                    AlertToast( type: .complete(.green), title: String(localized: "Data in iCloud has been deleted",comment:  "iCloud数据已删除") )
                }
            }
                .confirmationDialog("Data is priceless, please choose carefully!", isPresented: $showCloudSheet, titleVisibility : .visible, actions: {
                    Button("Overwrite local data to the cloud", role: .destructive) {
                        Task{
                            await local2Cloud()
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
                        do {
                            try await ctrl.cleanCloud()
                            showDeleteCloudSucToast = true
                        } catch {
                            showToast(String(localized: "Failed to delete iCloud data"))
                        }
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
                switch result {
                case .success:
                    showSuccessStatusCard(
                        title: String(localized: "Export Completed"),
                        message: String(localized: "Your reading data has been exported successfully.")
                    )
                case .failure:
                    showToast(String(localized: "Export failed"))
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
                        isImportingData = true
                        importProgress = 0
                        importPhase = .reading
                        importProgressText = String(localized: "Reading file...")
                        
                        Task {
                            defer {
                                CFURLStopAccessingSecurityScopedResource(selectedFile as CFURL)
                            }
                            
                            do {
                                await Task.yield()
                                let messageData = try Data(contentsOf: selectedFile)
                                
                                await MainActor.run {
                                    importPhase = .preparing
                                    importProgressText = String(localized: "Preparing import data...")
                                }
                                
                                guard let message = String(data: messageData, encoding: .utf8) else {
                                    throw ImportError.invalidFormat
                                }
                                
                                let parsedRows = try parseImportRows(from: message)
                                let importedBookCount = try await MainActor.run {
                                    try applyImportedRows(parsedRows)
                                }
                                
                                await MainActor.run {
                                    isImportingData = false
                                    importProgress = 1
                                    importPhase = .idle
                                    showSuccessStatusCard(
                                        title: String(localized: "Import Completed"),
                                        message: String(localized: "\(importedBookCount) book has been imported")
                                    )
                                }
                            } catch {
                                await MainActor.run {
                                    isImportingData = false
                                    importPhase = .idle
                                    showToast(String(localized: "Import failed"))
                                }
                                print(error.localizedDescription)
                            }
                        }
                    }
                    else {
                        print("Permission error!")
                    }
                } catch {
                    isImportingData = false
                    // Handle failure.
                    print(error.localizedDescription)
                }
            }
        }
        .navigationViewStyle(.stack)
        .task {
            checkIfICloudCanUse()
        }
        .onDisappear{
            successStatusCardTask?.cancel()
            keyStore.synchronize()
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
        let books = fetchBooks()
        let logs = fetchLogs()
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
        let minute = keyStore.longLong(forKey: "targetMinPerday")
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
        do {
            let bookRecords = try await ctrl.fetchBooksFromICloud()
            
            if(bookRecords.count == 0 ){ // 云端没数据，无脑local->cloud
                await local2Cloud()
                
            }else if(fetchBookCount() == 0){ // 本地无数据，无脑cloud->local
                await cloud2Local()
            }else{ // 用户选择
                showCloudSheet = true
            }
        } catch {
            showToast(String(localized: "Failed to access iCloud data"))
        }
    }
    
    func cleanLocal(){
        let books = fetchBooks()
        let logs = fetchLogs()
        
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

        do {
            let bookRecords = try await ctrl.fetchBooksFromICloud()
            let logRecords = try await ctrl.fetchLogsFromICloud()
            
            for bookRecord in bookRecords {
                let book  = Book(context: context)
                book.id = bookRecord.object(forKey: "id") as! String
                book.name = bookRecord.object(forKey: "name") as! String
                book.author = bookRecord.object(forKey: "author") as? String
                
                book.isDone = bookRecord.object(forKey: "isDone") as! Bool
                book.readMinutes = bookRecord.object(forKey: "readMinutes") as! Int
                book.createTime = bookRecord.object(forKey: "createTime") as! Date
                book.firstReadTime = bookRecord.object(forKey: "firstReadTime") as? Date
                book.lastReadTime = bookRecord.object(forKey: "lastReadTime") as? Date
                book.doneTime = bookRecord.object(forKey: "doneTime") as? Date
                book.rating = bookRecord.object(forKey: "rating") as! Int
                book.readDays = bookRecord.object(forKey: "readDays") as! Int
                book.tags = bookRecord.object(forKey: "tags") as? String
                
                let imageFile:CKAsset? = bookRecord.object(forKey: "image") as? CKAsset
                let thumbnailFile:CKAsset? = bookRecord.object(forKey: "thumbnailImage") as? CKAsset
                
                if let file = imageFile {
                    if let data = NSData(contentsOf: file.fileURL!){
                        book.image = data as Data
                        if let thumbnailFile,
                           let thumbnailData = NSData(contentsOf: thumbnailFile.fileURL!) {
                            book.thumbnailImage = thumbnailData as Data
                        } else {
                            book.thumbnailImage = (data as Data).makeThumbnailData()
                        }
                    }
                }
            }

            for logRecord in logRecords {
                let log = ReadLog(context:context)
                log.day = logRecord.object(forKey: "day") as! Date
                log.readMinutes = logRecord.object(forKey: "readMinutes") as! Int
            }
            
            DispatchQueue.main.async {
                do{
                    try context.save()
                }catch{
                    print(error)
                }
            }
        } catch {
            showToast(String(localized: "Failed to download iCloud data"))
        }
    }
    
    func local2Cloud() async{
        do {
            try await ctrl.cleanCloud()
            let books = fetchBooks()
            let logs = fetchLogs()
            
            for book in books{
                try await ctrl.saveBookInICloud(book: book)
            }
            
            for log in logs{
                try await ctrl.saveLogInICloud(log: log)
            }
            
            ctrl.tapLastBackuptime()
        } catch {
            showToast(String(localized: "Failed to upload iCloud data"))
        }
    }
    
    
    func cleanAllData() async{
        if(useiCloud){
            do {
                try await ctrl.cleanCloud()
            } catch {
                showToast(String(localized: "Failed to delete iCloud data"))
                return
            }
        }
        cleanLocal()
        targetMinPerday = 45
        _targetReadMin = 45
        todayReadMin = 0
        isFirstBookCard = true
        hasViewdWalkthrough = false
        isRemind = false
        reminDateHour = -1
        reminDateMin = -1
        NotificationTool.cancel()
        ctrl.cleanTodayLog()
        
        keyStore.removeObject(forKey: "targetMinPerday")
        keyStore.removeObject(forKey: "todayReadMin")        
        keyStore.removeObject(forKey: "lastReadDate")
        
        keyStore.removeObject(forKey: "logInYear")
                
        
        keyStore.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
        await MainActor.run {
            showSuccessStatusCard(
                title: String(localized: "Data Cleared"),
                message: String(localized: "All your reading data has been cleared.")
            )
        }
    }
    
    func showToast(_ text:String){
        toastString = text
        isShowToast  = true
    }
    
    private func showSuccessStatusCard(title: String, message: String) {
        successStatusCardTask?.cancel()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            successStatusCard = SuccessStatusCard(title: title, message: message)
        }
        
        successStatusCardTask = Task {
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    successStatusCard = nil
                }
            }
        }
    }
    
    private func fetchBooks() -> [Book] {
        let request = NSFetchRequest<Book>(entityName: "Book")
        
        do {
            return try context.fetch(request)
        } catch {
            print("Could not fetch books. \(error)")
            return []
        }
    }
    
    private func fetchLogs() -> [ReadLog] {
        let request = NSFetchRequest<ReadLog>(entityName: "ReadLog")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ReadLog.day, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Could not fetch logs. \(error)")
            return []
        }
    }
    
    private func fetchBookCount() -> Int {
        let request = NSFetchRequest<Book>(entityName: "Book")
        
        do {
            return try context.count(for: request)
        } catch {
            print("Could not count books. \(error)")
            return 0
        }
    }
    
    @MainActor
    private func applyImportedRows(_ rows: [ImportRow]) throws -> Int {
        var existingBooksByID = Dictionary(uniqueKeysWithValues: fetchBooks().map { ($0.id, $0) })
        var existingLogsByDay = Dictionary(uniqueKeysWithValues: fetchLogs().map { ($0.day, $0) })
        let totalRows = max(rows.count, 1)
        var importBookCount = 0
        importPhase = .importing
        
        for (index, row) in rows.enumerated() {
            switch row {
            case .book(let payload):
                if let book = existingBooksByID[payload.id] {
                    if payload.readMinutes > book.readMinutes && payload.readDays >= book.readDays {
                        book.readMinutes = payload.readMinutes
                        book.lastReadTime = payload.lastReadTime
                        book.isDone = payload.isDone
                        book.rating = payload.rating
                        book.readDays = payload.readDays
                        book.status = payload.status
                        book.tags = payload.tags
                    }
                } else {
                    let book = Book(context: context)
                    book.id = payload.id
                    book.name = payload.name
                    book.author = payload.author
                    book.image = payload.image
                    book.thumbnailImage = payload.image.makeThumbnailData()
                    book.isDone = payload.isDone
                    book.readMinutes = payload.readMinutes
                    book.createTime = payload.createTime ?? Date()
                    book.firstReadTime = payload.firstReadTime
                    book.lastReadTime = payload.lastReadTime
                    book.doneTime = payload.doneTime
                    book.rating = payload.rating
                    book.readDays = payload.readDays
                    book.status = payload.status
                    book.tags = payload.tags
                    existingBooksByID[payload.id] = book
                    importBookCount += 1
                }
            case .log(let payload):
                if let log = existingLogsByDay[payload.day] {
                    if payload.readMinutes > log.readMinutes {
                        log.readMinutes = payload.readMinutes
                    }
                } else {
                    let log = ReadLog(context: context)
                    log.day = payload.day
                    log.readMinutes = payload.readMinutes
                    existingLogsByDay[payload.day] = log
                }
            }
            
            importProgress = Double(index + 1) / Double(totalRows)
            importProgressText = String(localized: "Importing \(index + 1) / \(totalRows)")
        }
        
        try context.save()
        return importBookCount
    }
    
    private func parseImportRows(from message: String) throws -> [ImportRow] {
        let lines = message.split(separator: "\n")
        guard lines.count > 2 else { return [] }
        
        var rows: [ImportRow] = []
        rows.reserveCapacity(lines.count - 1)
        
        for line in lines[1...] {
            let cells = line.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
            guard !cells.isEmpty else { continue }
            
            if cells[0] == "day" {
                continue
            }
            
            if cells.count > 13 {
                let payload = BookImportPayload(
                    id: cells[0],
                    name: cells[1].replacingOccurrences(of: monkeyStr, with: ","),
                    author: cells[2].replacingOccurrences(of: monkeyStr, with: ","),
                    image: Data(base64Encoded: cells[3]) ?? UIImage(named: "camera")!.pngData()!,
                    isDone: cells[4] == "true",
                    readMinutes: Int(cells[5]) ?? 0,
                    createTime: dateFormatter.date(from: cells[6]),
                    firstReadTime: dateFormatter.date(from: cells[7]),
                    lastReadTime: dateFormatter.date(from: cells[8]),
                    doneTime: dateFormatter.date(from: cells[9]),
                    rating: Int(cells[10]) ?? 0,
                    readDays: Int(cells[11]) ?? 0,
                    tags: cells[12].replacingOccurrences(of: monkeyStr, with: ","),
                    status: Int16(cells[13]) ?? 1
                )
                rows.append(.book(payload))
            } else if cells.count > 1, let day = dateFormatter.date(from: cells[0]) {
                rows.append(.log(LogImportPayload(day: day, readMinutes: Int(cells[1]) ?? 0)))
            }
        }
        
        return rows
    }
    
    
}

private enum ImportError: Error {
    case invalidFormat
}

private enum ImportPhase {
    case idle
    case reading
    case preparing
    case importing
}

private enum ImportRow {
    case book(BookImportPayload)
    case log(LogImportPayload)
}

private struct BookImportPayload {
    let id: String
    let name: String
    let author: String?
    let image: Data
    let isDone: Bool
    let readMinutes: Int
    let createTime: Date?
    let firstReadTime: Date?
    let lastReadTime: Date?
    let doneTime: Date?
    let rating: Int
    let readDays: Int
    let tags: String
    let status: Int16
}

private struct LogImportPayload {
    let day: Date
    let readMinutes: Int
}

private struct SuccessStatusCard {
    let title: String
    let message: String
}

private enum StatusCardState {
    case progress(title: String, message: String, phase: ImportPhase, progress: Double)
    case success(SuccessStatusCard)
    
    var blocksInteraction: Bool {
        if case .progress = self {
            return true
        }
        
        return false
    }
}

private struct StatusCardView: View {
    let state: StatusCardState
    
    var body: some View {
        VStack(spacing: 16) {
            iconView
            
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            footerView
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.24), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 24, y: 12)
    }
    
    @ViewBuilder
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.16),
                            accentColor.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 68, height: 68)
            
            switch state {
            case .progress(_, _, let phase, _):
                if phase == .importing {
                    Image(systemName: "square.and.arrow.down.on.square")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(accentColor)
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(accentColor)
                        .scaleEffect(1.15)
                }
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(accentColor)
            }
        }
    }
    
    @ViewBuilder
    private var footerView: some View {
        switch state {
        case .progress(_, _, let phase, let progress):
            VStack(spacing: 8) {
                if phase == .importing {
                    ProgressView(value: progress, total: 1)
                        .progressViewStyle(.linear)
                        .tint(accentColor)
                    
                    HStack {
                        Text("\(Int(progress * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "hourglass")
                            .font(.caption.weight(.semibold))
                        Text(String(localized: "Please keep this screen open"))
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .frame(width: 220)
            
        case .success:
            Text(String(localized: "Done"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
    }
    
    private var title: String {
        switch state {
        case .progress(let title, _, _, _):
            return title
        case .success(let card):
            return card.title
        }
    }
    
    private var message: String {
        switch state {
        case .progress(_, let message, _, _):
            return message
        case .success(let card):
            return card.message
        }
    }
    
    private var accentColor: Color {
        switch state {
        case .progress:
            return .accentColor
        case .success:
            return .green
        }
    }
}

private struct ClearDataConfirmationCard: View {
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.red.opacity(0.16),
                                Color.orange.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 68, height: 68)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.red)
            }
            
            VStack(spacing: 8) {
                Text(String(localized: "Data is priceless, please choose carefully!"))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                
                Text(String(localized: "This action cannot be undone."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 10) {
                Button(role: .destructive, action: onConfirm) {
                    Text(String(localized: "I want to clear all data"))
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                
                Button(action: onCancel) {
                    Text(String(localized: "Cancel"))
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.24), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 24, y: 12)
    }
}

private struct RecommendedApp: Identifiable {
    let id = UUID()
    let name: String
    let taglineKey: String
    let appStoreURL: URL
    let assetName: String
    let tintColor: Color
}

private struct RecommendedAppRow: View {
    let app: RecommendedApp
    
    var body: some View {
        HStack(spacing: 10) {
            Image(app.assetName)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(app.name)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(LocalizedStringKey(app.taglineKey))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer(minLength: 8)
            
            Image(systemName: "arrow.up.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(app.tintColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}
