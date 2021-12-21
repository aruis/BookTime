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
    
    @FetchRequest(entity: Book.entity(), sortDescriptors:[])
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
                return "总共"
            case .year:
                return "本年"
            case .month:
                return "本月"
            }
        }
    }
    
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
            
            Slogan(title: todayReadMin > 0 ? "今天是您坚持阅读的第":"您已坚持阅读", unit: "天", value: Int64(totalReadDay))
            
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
                            
                            Text("今日您已阅读 \(todayReadMin) 分")
                                .font(.title2)
                            if targetMinPerday > 0{
                                Text("完成计划的 \( Int( round( process * 100))) %")
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
                
                Report( todayReadMin: todayReadMin, totalReadDay: totalReadDay, totalReadMin: totalReadMin, totalReadBook: totalReadBook, longHit: longHit)
                    .id(1).tag(SumType.all)
                
                
                
                Report(  todayReadMin: todayReadMin, totalReadDay: totalReadDay_year, totalReadMin: totalReadMin_year, totalReadBook: totalReadBook_year, longHit: longHit_year)
                    .id(2) .tag(SumType.year)
                
                
                
                
                Report(  todayReadMin: todayReadMin, totalReadDay: totalReadDay_month, totalReadMin: totalReadMin_month, totalReadBook: totalReadBook_month, longHit: longHit_month)
                    .id(3) .tag(SumType.month)
                
                
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.linear, value: sumType)
            .frame( height: 160)
            
        }
    }
    
    @ViewBuilder
    var exportBox:some View{
        //        VStack{
        VStack(){
            VStack{
                Text("BookTime").font(.largeTitle)
                reportView
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 10.0)
                    .stroke(lineWidth: 3.0)
                    .foregroundColor(Color("AccentColor"))
            )
            Text("test").font(.title)
                .opacity(0)
        }
        .foregroundColor(.black)
        .padding(.all,15)
    }
    
    var body: some View {
        
        
        //        return exportBox
        
        NavigationView {
            //            ScrollView{
            
            ScrollView {
                VStack (){
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
                .navigationTitle("成就")
                //                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    Button(action: {
                        let image = exportBox.snapshot()
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)                                                
                        showToast = true
                    }){
                        Image(systemName: "square.and.arrow.up")
                    }
                })
                .toast(isPresenting: $showToast,duration: 3,tapToDismiss: true){
                    AlertToast( type: .complete(.green), title: "导出成功\n去相册看看吧")
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
                if( Date().format(format: "YYYY") != doneTime.format(format: "YYYY")) {
                    isShowYear = true //存在非本年数据
                    
                    //说明不是本年，不参与计算
                    if(sumType == .year ){
                        continue
                    }                }
                if(Date().format(format: "YYYY-MM") != doneTime.format(format: "YYYY-MM")) {
                    isShowMonth = true //存在非本月数据
                    
                    //说明不是本月，不参与计算
                    if(sumType == .month ){
                        continue
                    }
                }
                
                if(book.isDone){
                    totalReadBook += 1
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
        
    
    var body: some View{
        VStack ( spacing:15)        {
            
            Slogan(title: "累计阅读", unit: "分钟", value: Int64( totalReadMin))
            Slogan(title: "读完了", unit: "本书", value: Int64(totalReadBook))
            Slogan(title: "最长连续打卡", unit: "天", value: Int64(longHit))
            
        }
        
    }
}


