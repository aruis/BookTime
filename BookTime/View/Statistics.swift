//
//  Statistics.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/3.
//

import SwiftUI

struct Statistics: View {
    @AppStorage("targetMinPerday") var targetMinPerday = 45
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.colorScheme) var colorScheme
    
    @FetchRequest(entity: ReadLog.entity(), sortDescriptors:[
        NSSortDescriptor(keyPath: \ReadLog.day, ascending: true)
    ],predicate:NSPredicate(format: "readMinutes > 0"))
    var logs: FetchedResults<ReadLog>
    
    @FetchRequest(entity: Book.entity(), sortDescriptors:[
        NSSortDescriptor(keyPath: \Book.doneTime, ascending: true)
    ])
    var books: FetchedResults<Book>
    
    @State private var todayReadMin:Int16 = 0
    
    
    @State private var totalReadDay = 0
    @State private var totalReadMin:Int64 = 0
    @State private var totalReadBook = 0
    @State private var longHit = 0
    
    @State private var totalReadDay_year = 0
    @State private var totalReadMin_year:Int64 = 0
    @State private var totalReadBook_year = 0
    @State private var longHit_year = 0
    
    @State private var totalReadDay_month = 0
    @State private var totalReadMin_month:Int64 = 0
    @State private var totalReadBook_month = 0
    @State private var longHit_month = 0
    
    @State private var isShowMonth = false
    @State private var isShowYear = false
    
    @State private var showToast = false
    @State private var isLoading = false
    
    @State private var isShowReadedBooks  = false
    @State private var showOptions = false
    @State private var shareImage:UIImage? = nil
    
    enum SumType: String,CaseIterable{
        case all
        case year
        case month
    }
    
    @State private var sumType = SumType.all
    
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
            }
        }
    }
    
    var readedBooks:[Book]{
        get{
            var _books:[Book] = []
            
            for book:Book in books{
                if(book.isDone){
                    switch sumType {
                    case .all:
                        _books.append(book)
                    case .year:
                        if(Date().format(format: "YYYY") == book.doneTime?.format(format: "YYYY")) {
                            _books.append(book)
                        }
                    case .month:
                        if(Date().format(format: "YYYY-MM") == book.doneTime?.format(format: "YYYY-MM")) {
                            _books.append(book)
                        }
                    }
                }
            }
            
            return _books
        }
    }
    
    let columnGrid = [
        GridItem(.flexible(),spacing: 20),
        GridItem(.flexible(),spacing: 20),
        GridItem(.flexible(),spacing: 20)
    ]
    
    @ViewBuilder
    var reportView:some View{
        VStack {
            
            //                    Picker(selection: $sumType, label: Text("DayPiker")) {
            //                        Text("全部").tag(SumType.all)
            //
            //                        Text("本年").tag(SumType.year)
            //
            //                        Text("本月").tag(SumType.month)
            //
            //                    }.labelsHidden()
            //                        .pickerStyle(SegmentedPickerStyle())
            //                        .onChange(of: sumType, perform: { val in
            //                            initAllLog()
            //                        })
            
            
            Slogan(title: todayReadMin > 0 ? String(localized: "You have been reading for",comment: "今天是您坚持阅读的第"): String(localized: "You have been reading for",comment: "您已坚持阅读"), unit: totalReadDay>0 ? String(localized: "days") : String(localized: "day"), value: String(totalReadDay))
            
            
            
            
            ZStack{
                Circle()
                    .trim(from: 0.0, to:1.0)
                    .stroke(Color("AccentColor"), style: StrokeStyle(lineWidth: 25, lineCap: CGLineCap.round))
                    .frame(width:260)
                    .rotationEffect(.degrees(-90))
                    .opacity(0.25)
                //                        .opacity(0)
                    .padding()
                
                Circle()
                    .trim(from: 0.0, to: process)
                //                        .trim(from: 0.0,to:  1.0)
                    .stroke( AngularGradient(
                        gradient: Gradient(colors: [Color("AccentColor").opacity(0.6), Color("AccentColor")]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees( 360 * process )
                    ), style: StrokeStyle(lineWidth: 25, lineCap: CGLineCap.round))
                    .frame(width:260)
                    .rotationEffect(.degrees(-90))
                    .overlay(
                        VStack(spacing:6){
                            Text( "\(todayReadMin) minutes today")
                                .font(.title2)
                            if targetMinPerday > 0{
                                Text("\( Int( round( process * 100))) %  of the plan completed")
                                    .foregroundColor(.gray)
                            }
                            
                        }
                        
                    )
                    .padding()
                
                
                
            }
            .frame(width: 300,height: 300)
            //            .animation(.linear, value: todayReadMin)
            
            Text(totalTitle)
                .font(.title)
                .animation(.easeIn, value: sumType)
            
            TabView(selection: $sumType){
                
                Report( todayReadMin: todayReadMin, totalReadDay: totalReadDay, totalReadMin: totalReadMin, totalReadBook: totalReadBook, longHit: longHit,isShowReadedBooks:$isShowReadedBooks)
                    .id(1).tag(SumType.all)
                
                
                
                Report(  todayReadMin: todayReadMin, totalReadDay: totalReadDay_year, totalReadMin: totalReadMin_year, totalReadBook: totalReadBook_year, longHit: longHit_year,isShowReadedBooks:$isShowReadedBooks)
                    .id(2) .tag(SumType.year)
                
                
                
                
                Report(  todayReadMin: todayReadMin, totalReadDay: totalReadDay_month, totalReadMin: totalReadMin_month, totalReadBook: totalReadBook_month, longHit: longHit_month,isShowReadedBooks:$isShowReadedBooks)
                    .id(3) .tag(SumType.month)
                
                
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: sumType)
            .frame( height: 160)
        }
    }
    
    @ViewBuilder
    var exportBox:some View{
        //        VStack{
        VStack(){
            VStack{
                Text("BookTime").font(.system(.title,design: .rounded))
                Text("Reading Timing Buddy").font(.subheadline).opacity(0.8)
                reportView
                readedBookView
                    .frame(width: 400)
                
                
                
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
            )
        }        
        .foregroundColor(.black)
        .padding()
        .ignoresSafeArea()
        
    }
    
    @ViewBuilder
    var readedBookView:some View{
        LazyVGrid(columns: columnGrid,spacing: 15) {
            ForEach(readedBooks){book in
                if let imageData = book.image{
                    Image(uiImage: UIImage(data: imageData) ?? UIImage())
                        .resizable()
                        .scaledToFill()
                        .overlay(
                            Rectangle()
                                .stroke(Color("image.border"), lineWidth: 1)
                        )
                        .shadow(color: Color( "image.border"), radius: 5,x:2,y:2)
                }
            }
        }
        .padding(10)
        .padding([.leading,.trailing],12)
        
    }
    
    var body: some View {
        
        
        //        return exportBox
        
        NavigationView {
            //            ScrollView{
            
            ScrollView {
                ZStack (){
                    //                    ActivityView(activityItems: [])
                    //                    ActivityView(activityItems: [])
                    //                        .frame(width: 300, height: 300)
                    //                        .opacity(0)
                    reportView
                }
                .padding()
                .onAppear(perform: {
                    todayReadMin = 0
                })
                .task {
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {
                        withAnimation(.easeInOut){
                            todayReadMin = BookPersistenceController.shared.checkAndBuildTodayLog().readMinutes
                        }
                        
                    })
                    initAllLog()
                }
                .navigationTitle("Achievement")
                //                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    Button(action: {
                        showOptions = true
                    }){
                        Image(systemName: "square.and.arrow.up")
                    }
                })
                .sheet(isPresented: $showOptions) {
                    
                    VStack{
                        if let image = shareImage {
                            ActivityView(activityItems: [image])
                        }else{
                            Text("")
                                .toast(isPresenting: $showToast){
                                    AlertToast(type: .loading, title: "Rendering image")
                                }
                        }
                    }
                    .task {
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {
                            shareImage = exportBox.snapshot()
                            self.showToast = false
                        })
                        
                    }
                    .onAppear() {
                        self.showToast = true
                    }
                    .onDisappear(perform: {
                        shareImage = nil
                    })
                    
                }
                
            }
            .sheet(isPresented: $isShowReadedBooks){
                NavigationView{
                    ScrollView{
                        readedBookView
                    }
                    .navigationTitle("Finished book")
                }
            }
            
            
        }
        .navigationViewStyle(.stack)
        
    }
    
    func initAllLog(){
        
        
        
        totalReadDay = 0
        totalReadMin = 0
        totalReadBook = 0
        longHit = 0
        totalReadDay_year = 0
        totalReadMin_year = 0
        totalReadBook_year = 0
        longHit_year = 0
        totalReadDay_month = 0
        totalReadMin_month = 0
        totalReadBook_month = 0
        longHit_month = 0
        
        //        isShowYear = false
        //        isShowMonth = false
        //
        //        totalReadDay = 0
        //        totalReadMin = 0
        //        totalReadBook = 0
        //
        //        longHit = 0
        
        
        
        
        var lastHitDay:Date? = nil
        var lastHitDay_month:Date? = nil
        var lastHitDay_year:Date? = nil
        
        for log:ReadLog in logs{
            
            if(log.readMinutes>0){
                
                if( Date().format(format: "YYYY") == log.day.format(format: "YYYY")) {
                    totalReadDay_year += 1
                    totalReadMin_year += Int64( log.readMinutes)
                    
                    if let lastHitDay = lastHitDay_year {
                        let begin = lastHitDay.start()
                        let end = log.day.start()
                        let components = NSCalendar.current.dateComponents([.day], from: begin , to: end)
                        if(components.day == 1){ //间隔一天，连续的
                            longHit_year += 1
                        }else{
                            longHit_year = 1
                        }
                        
                    }else{
                        longHit_year = 1
                    }
                    
                    lastHitDay_year = log.day
                    
                }
                if( Date().format(format: "YYYY-MM") == log.day.format(format: "YYYY-MM")) {
                    totalReadDay_month += 1
                    totalReadMin_month += Int64( log.readMinutes)
                    
                    if let lastHitDay = lastHitDay_month {
                        let begin = lastHitDay.start()
                        let end = log.day.start()
                        let components = NSCalendar.current.dateComponents([.day], from: begin , to: end)
                        if(components.day == 1){ //间隔一天，连续的
                            longHit_month += 1
                        }else{
                            longHit_month = 1
                        }
                        
                    }else{
                        longHit_month = 1
                    }
                    
                    lastHitDay_month = log.day
                    
                }
                
                totalReadDay += 1
                totalReadMin += Int64( log.readMinutes)
                
                if let lastHitDay = lastHitDay {
                    let begin = lastHitDay.start()
                    let end = log.day.start()
                    let components = NSCalendar.current.dateComponents([.day], from: begin , to: end)
                    if(components.day == 1){ //间隔一天，连续的
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
        
        for book:Book in books{
            if let doneTime = book.doneTime {
                if book.isDone {
                    totalReadBook += 1
                    
                    if( Date().format(format: "YYYY") == doneTime.format(format: "YYYY")) {
                        totalReadBook_year += 1
                    }
                    
                    if( Date().format(format: "YYYY-MM") == doneTime.format(format: "YYYY-MM")) {
                        totalReadBook_month += 1
                    }
                    
                }
            }
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
    
    var todayReadMin:Int16
    
    var totalReadDay:Int
    var totalReadMin:Int64
    var totalReadBook:Int
    
    var longHit:Int
    
    @Binding var isShowReadedBooks:Bool
    
    
    var body: some View{
        VStack ( spacing:15) {
            Slogan(title: String(localized: "A total of",comment: "累计阅读") , unit: String(localized:"minutes of reading",comment: "分钟" )  , value: String( totalReadMin))
            Slogan(title: String(localized: "Read",comment: "读完了"  ) , unit: String(localized:"books in total" ,comment: "本书")  , value: String(totalReadBook))
                .onTapGesture {
                    if(totalReadBook>0){
                        isShowReadedBooks = true
                    }
                }
            Slogan(title: String(localized: "Longest consecutive hits for",comment: "最长连续打卡") , unit: String(localized: "days",comment: "天") , value: String(longHit))
        }
        
    }
}


