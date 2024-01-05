//
//  Statistics.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/3.
//

import SwiftUI
import AlertToast
import Charts

struct Statistics: View {
    @AppStorage("targetMinPerday") var targetMinPerday = 45
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.colorScheme) var colorScheme
    
    let keyStore = NSUbiquitousKeyValueStore()
    
    @FetchRequest(entity: ReadLog.entity(), sortDescriptors:[
        NSSortDescriptor(keyPath: \ReadLog.day, ascending: true)
    ])
    var logs: FetchedResults<ReadLog>
    
    @FetchRequest(entity: Book.entity(), sortDescriptors:[
        NSSortDescriptor(keyPath: \Book.doneTime, ascending: true)
    ])
    var books: FetchedResults<Book>
    
    @State private var showCover = false
    
    @State private var todayReadMin:Int = 0
    
    
    @State private var totalReadDay = 0
    @State private var totalReadMin = 0
    @State private var totalReadBook = 0
    @State private var longHit = 0
    @State private var fishDay = 0
    
    @State private var totalReadMin_year = 0
    @State private var totalReadBook_year = 0
    @State private var totalReadDay_year = 0
    
    @State private var totalReadMin_month = 0
    @State private var totalReadBook_month = 0
    @State private var totalReadDay_month = 0
    
    @State private var totalReadMin_custom = 0
    @State private var totalReadBook_custom = 0
    
    @State private var isShowMonth = false
    @State private var isShowYear = false
    
    @State private var isShowReadedBooks  = false
    @State private var showSharePic  = false
    
    @State private var shareImage:UIImage? = nil
    
    @State private var selectBookID:String = ""
    
    @State private var customDateBegin:Date = Date().start()
    @State private var customDateEnd:Date = Date().start()
    
    enum SumType: String,CaseIterable{
        case all
        case year
        case month
        case custom
    }
    
    @State private var sumType = SumType.year
    
    var process:CGFloat{
        get{
            if(targetMinPerday>0){
                return CGFloat( todayReadMin)/CGFloat( targetMinPerday)
            }else{
                return CGFloat( todayReadMin)/CGFloat( 45)
            }
            
        }
    }
    
    var totalTitle:String{
        get {
            switch sumType {
            case .all:
                return String(localized: "All")
            case .year:
                return String(localized: "This Year")
            case .month:
                return String(localized: "This Month")
            case .custom:
                return String("\(customDateBegin.text()) / \(customDateEnd.text())")
            }
        }
    }
    
    var readedBooks:[Book]{
        get{
            var _books:[Book] = []
            let now = Date()
            for book:Book in books{
                if(book.isDone){
                    if let doneTime = book.doneTime {
                        switch sumType {
                        case .all:
                            _books.append(book)
                        case .year:
                            if( now.isSameYear(doneTime)) {
                                _books.append(book)
                            }
                        case .month:
                            if(now.isSameMonth(doneTime)) {
                                _books.append(book)
                            }
                        case .custom:
                            if doneTime >= customDateBegin && doneTime <= customDateEnd || doneTime.isSameDay(customDateEnd) {
                                _books.append(book)
                            }
                            
                        }
                    }
                }
            }
            
            return _books
        }
    }
    
    var chartLogs:[Log]{
        
        let logInYear:[Int] = keyStore.object(forKey: "logInYear") as? [Int] ??  [Int](repeating: 0, count: 366)
        
        
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear =  "\(calendar.component(.year, from: currentDate))"
        
        
        switch sumType{
        case .all:
            return logs.map{Log(day: $0.day, readMinutes: $0.readMinutes)}
        case .year:
            return  (0...(Date(currentYear + "-12-31").dayOfYear - 1)).map{
                Log(day: Date(currentYear + "-01-01").advanced(by: TimeInterval($0 * 24 * 60 * 60)), readMinutes: logInYear[$0])
            }
        case .month:
            let mounthFirst = Date(Date().format("yyyy-MM") + "-01")
            return  (0...(Date().getDaysInMonth()-1)).map{
                Log(day: mounthFirst.advanced(by: TimeInterval($0 * 24 * 60 * 60)), readMinutes: logInYear[mounthFirst.dayOfYear +  $0 - 1])
            }
        case .custom:
            return logs.filter{
                return  $0.day >= customDateBegin && $0.day <= customDateEnd
            }
            .map{Log(day: $0.day, readMinutes: $0.readMinutes)}
        }
        
    }
    
    func processCustom(){
        totalReadMin_custom = 0
        totalReadBook_custom = 0
        
        logs.filter{
            $0.day >= customDateBegin && $0.day <= customDateEnd
        }.forEach{
            totalReadMin_custom += $0.readMinutes
        }
        
        totalReadBook_custom =   books.filter{
            $0.isDone && ( $0.doneTime! >= customDateBegin && $0.doneTime! <= customDateEnd
                           || $0.doneTime!.isSameDay(customDateEnd))
        }.count
        
    }
    
    
    
    @ViewBuilder
    func reportView(isRendererImage:Bool = false) -> some View{
        VStack{
            HStack{
                //                String(localized: "\(todayReadMin) Minutes Today")
                GroupBox(label: Label(String(localized: "Total Reading"),systemImage: "target").font(.footnote)){
                    HStack(alignment:.firstTextBaseline,spacing:2){
                        if(isRendererImage){
                            Text("\(totalReadDay)").font(.largeTitle).frame(height: 100)
                        }else{
                            RollingText(font: .largeTitle, weight: .medium, value: $totalReadDay)
                                .frame(height: 100)
                        }
                        if(totalReadDay>1){
                            Text(String(localized: "Days")).font(.footnote)
                        }else{
                            Text(String(localized: "Day")).font(.footnote)
                        }
                        
                    }
                    
                }
                
                
                GroupBox(label: Label(String(localized:fishDay > 0 ? "Unread" :"Persisted"),systemImage:fishDay > 0 ? "fish.circle": "checkmark.circle")
                    .font(.footnote)
                ){
                    HStack(alignment:.firstTextBaseline,spacing:2){
                        if(isRendererImage){
                            Text( "\(fishDay > 0 ? fishDay : longHit)").font(.largeTitle).frame(height: 100)
                        }else{
                            if fishDay > 0{
                                RollingText(font: .largeTitle, weight: .medium, value: $fishDay)
                                    .frame(height: 100)
                            }else{
                                RollingText(font: .largeTitle, weight: .medium, value: $longHit)
                                    .frame(height: 100)
                            }
                        }
                        if(fishDay>1 || longHit>1){
                            Text(String(localized: "Days")).font(.footnote)
                        }else{
                            Text(String(localized: "Day")).font(.footnote)
                        }
                    }
                }
            }
            
            
            GroupBox(label:Label(String(localized: "\( Int( round( process * 100))) % of the Plan Completed"),systemImage: "goforward").font(.footnote)){
                HStack{
                    Text(String(localized: "\(todayReadMin) Minutes Today"))
                        .font(.system(.title2,design: .rounded))
                    
                    Spacer()
                    
                    ProgressRingView(progress: .constant(process),
                                     thickness: 12,
                                     width: 100,
                                     gradient: Gradient(colors: [Color("AccentColor").opacity(0.6), Color("AccentColor")])
                    )
                    
                    
                    
                }
                .padding(.trailing,8)
                
            }
            
            
            if isRendererImage {
                GroupBox(label: Label(totalTitle,systemImage: "clock")
                    .font(.footnote)
                ){
                    Group{
                        switch sumType{
                        case .all :
                            Report(totalReadMin: $totalReadMin, totalReadBook: $totalReadBook, isRendererImage:isRendererImage)
                        case .year:
                            Report(totalReadMin: $totalReadMin_year, totalReadBook: $totalReadBook_year, isRendererImage:isRendererImage)
                            
                        case .month:
                            Report(totalReadMin: $totalReadMin_month, totalReadBook: $totalReadBook_month, isRendererImage:isRendererImage)
                        case .custom:
                            Report(totalReadMin: $totalReadMin_custom, totalReadBook: $totalReadBook_custom, isRendererImage:isRendererImage)
                        }
                    }
                    .frame(height:100)
                    
                    
                }
                
                
            }else {
                GroupBox(label: Label(totalTitle,systemImage: "clock")
                    .font(.footnote)
                ){
                    
                    VStack{
                        Chart {
                            
                            ForEach(chartLogs,id:\.day){
                                BarMark(
                                    x: .value("Day", $0.day,unit:.day),
                                    y: .value("Value", $0.readMinutes)
                                )
                            }
                            
                            
                        }
                        .frame(height: 160)
                        .animation(.easeOut, value: sumType)
                        .animation(.easeOut, value: customDateBegin)
                        .animation(.easeOut, value: customDateEnd)
                        
                        TabView(selection: $sumType){
                            
                            Report(totalReadMin: $totalReadMin, totalReadBook: $totalReadBook, isRendererImage:isRendererImage)
                                .id(1).tag(SumType.all)
                            
                            Report(totalReadMin: $totalReadMin_year, totalReadBook: $totalReadBook_year, isRendererImage:isRendererImage)
                                .id(2) .tag(SumType.year)
                            
                            Report(totalReadMin: $totalReadMin_month, totalReadBook: $totalReadBook_month, isRendererImage:isRendererImage)
                                .id(3) .tag(SumType.month)
                            
                            VStack{
                                HStack(){
                                    Spacer()
                                    DatePicker("", selection: $customDateBegin,in: ...Date(), displayedComponents:.date)
                                    DatePicker("-", selection: $customDateEnd,in: ...Date(), displayedComponents:.date)
                                    Spacer()
                                }
                                .onChange(of: customDateBegin, perform: { date in
                                    if customDateBegin > customDateEnd {
                                        customDateEnd = customDateBegin
                                    }
                                    
                                    processCustom()
                                    
                                })
                                .onChange(of: customDateEnd, perform: { date in
                                    if customDateBegin > customDateEnd {
                                        customDateBegin = customDateEnd
                                    }
                                    
                                    processCustom()
                                })
                                
                                
                                Report(totalReadMin: $totalReadMin_custom, totalReadBook: $totalReadBook_custom, isRendererImage:isRendererImage)
                                
                            }
                            .id(4).tag(SumType.custom)
                            
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .animation(.easeInOut, value: sumType)
                        //                        .frame(height: 150)
                        .frame( height: sumType == .custom ? 200 : 100)
                        
                    }
                }
                
            }
            
            
            if readedBooks.count > 0 {
                GroupBox(label: Label(String(localized: "Finished Book"),systemImage: "books.vertical")
                    .font(.footnote)
                ){
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 85),spacing: 20),],spacing: 15) {
                        ForEach(readedBooks){book in
                            let imageData = book.image
                            
                            Image(uiImage: UIImage(data: imageData) ?? UIImage())
                                .resizable()
                                .scaledToFill()
                                .overlay(
                                    Rectangle()
                                        .stroke(Color("image.border"), lineWidth: 1)
                                )
                                .shadow(color: Color( "image.border"), radius: 5,x:2,y:2)
                                .onTapGesture(perform: {
                                    if !isRendererImage{
                                        selectBookID = book.id
                                        showCover = true
                                    }
                                })
                            
                            
                        }
                    }
                    .padding(8)
                    .animation(.easeInOut, value: sumType)
                }
                
            }
        }
        
    }
    
    @ViewBuilder
    func exportBox(isRendererImage:Bool = false,isShow:Bool = false) -> some View{
        //        VStack{
        VStack(){
            VStack{
                Text("BookTime").font(.system(.title,design: .rounded))
                Text(String(localized: "Track your reading time")).font(.subheadline).opacity(0.8)
                reportView(isRendererImage:true)
                    .frame(width:380)
                
                
                
                Image("qr")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80,height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke( lineWidth: 1)
                            .foregroundColor(.black.opacity(0.6))
                    )
                
                
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 10.0)
                    .stroke(lineWidth: 3.0)
                    .foregroundColor(Color("AccentColor"))
                    .opacity(isShow ? 0 : 1)
            )
        }
        .preferredColorScheme(.light)
        //        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10.0))
        .padding()
        .ignoresSafeArea()
        
    }
    
    var body: some View {
        
        
        //        return exportBox
        
        NavigationView {
            //            ScrollView{
            
            ScrollView {
                reportView()
                    .padding()
                    .navigationTitle("Achievement")
                    .toolbar(content: {
                        Button{
                            showSharePic = true
                        }label:{
                            Image(systemName: "square.and.arrow.up")
                        }
                    })
                
            }
            
            
        }
        .sheet(isPresented: $showSharePic){
            ScrollView{
                VStack(){
                    exportBox(isRendererImage: true,isShow: true)
                    
                    Color.accentColor.frame(height:1)
                        .padding(.top,0)
                        .padding(.bottom,30)
                    
                    ShareLink(item: Image(uiImage: generateSnapshot()), preview: SharePreview("BookTime")){
                        Label( "Share",systemImage:"square.and.arrow.up.circle")
                            .font(.largeTitle)
                            .labelStyle(.iconOnly)
                        
                    }
                }
                
                
            }
            
        }
        
        .sheet(isPresented:  $showCover, content: {
            GeometryReader{reader in
                let scale = reader.size.height / 400 * 0.618
                TabView(selection: $selectBookID){
                    ForEach(readedBooks){book in
                        BookCardExport(book: book)
                            .scaleEffect(scale)
                            .tag(book.id)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            
        })
        
        .navigationViewStyle(.stack)
        .onAppear(perform: {
            todayReadMin = 0
        })
        .task {
            withAnimation(.easeInOut){
                initAllLog()
            }
        }
        
        
    }
    
    @MainActor
    private func generateSnapshot() -> UIImage {
        let renderer = ImageRenderer(content: exportBox(isRendererImage: true))
        renderer.scale = 2
        return  renderer.uiImage ?? UIImage()
    }
    
    func initAllLog(){
        
        totalReadDay = 0
        totalReadMin = 0
        totalReadBook = 0
        longHit = 0
        fishDay = 0
        
        totalReadDay_year = 0
        totalReadMin_year = 0
        totalReadBook_year = 0
        
        totalReadDay_month = 0
        totalReadMin_month = 0
        totalReadBook_month = 0
        
        todayReadMin = Int( BookPersistenceController.shared.checkAndBuildTodayLog().readMinutes)
        
        var lastHitDay:Date? = nil
        
        let now = Date()
        
        for log:ReadLog in logs{
            
            if(log.readMinutes>0){
                
                if( now.isSameYear(log.day)) {
                    totalReadDay_year += 1
                    totalReadMin_year +=  log.readMinutes
                    
                    if(now.isSameMonth(log.day)) {
                        if(totalReadDay_month == 0){
                            customDateBegin = log.day
                        }
                        
                        totalReadDay_month += 1
                        totalReadMin_month += log.readMinutes
                    }
                }
                
                
                totalReadDay += 1
                totalReadMin += log.readMinutes
                
                if let lastHitDay = lastHitDay {
                    let begin = lastHitDay.start()
                    let end = log.day.start()
                    let components = NSCalendar.current.dateComponents([.day], from: begin , to: end)
                    if(components.day == 0 || components.day == 1){ //间隔一天，连续的
                        longHit += 1
                    }else{
                        longHit = 1
                    }
                    
                }else{
                    longHit = 1
                }
                
                lastHitDay = log.day
            }
            
        }
        
        if let lastHitDay{
            let components = Calendar.current.dateComponents([.day], from: lastHitDay, to: .now)
            fishDay = components.day ?? 0
        }
        
        
        for book:Book in books{
            if let doneTime = book.doneTime {
                if book.isDone {
                    totalReadBook += 1
                    
                    if( now.isSameYear(doneTime)) {
                        totalReadBook_year += 1
                        
                        if(now.isSameMonth(doneTime)) {
                            totalReadBook_month += 1
                        }
                    }
                    
                }
            }
        }
        
        if !logs.isEmpty {
            customDateEnd = logs[logs.count-1].day
            processCustom()
        }
    }
    
    
    
}

//struct Statistics_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView{
//            Statistics()
//        }
//
//    }
//}

struct Report: View{
    
    @Binding var totalReadMin:Int
    @Binding var totalReadBook:Int
    
    var isRendererImage:Bool
    
    
    var body: some View{
        VStack ( spacing:15) {
            Slogan(title: String(localized: "A Total of",comment: "累计阅读") , unit: String(localized:"Minutes of Reading",comment: "分钟" )  , value: $totalReadMin,isRendererImage:isRendererImage)
            Slogan(title: String(localized: "Read",comment: "读完了"  ) , unit: String(localized:"Books in Total" ,comment: "本书")  , value: $totalReadBook,isRendererImage:isRendererImage)
        }
        
    }
}


struct Log{
    let day:Date
    let readMinutes:Int
}
