//
//  Statistics.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/3.
//

import SwiftUI

struct Statistics: View {
    @AppStorage("targetMinPerday") var targetMinPerday = 0
    
    @Environment(\.managedObjectContext) var context
    
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
    
    enum SumType: String,CaseIterable{
        case all
        case year
        case month
    }
    
    @State private var sumType = SumType.all
    
    var  process:CGFloat{
        get{
            if(targetMinPerday>0){
                return CGFloat( todayReadMin)/CGFloat( targetMinPerday)
            }else{
                return CGFloat( todayReadMin)/CGFloat( 45)
            }
            
        }
    }
    
    
    
    var mainView:some View{
        ScrollView {
            VStack ( spacing:15)        {
                
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
                .animation(.linear, value: todayReadMin)
                
                Slogan(title: "累计阅读", unit: "分钟", value: Int64( totalReadMin))
                Slogan(title: "读完了", unit: "本书", value: Int64(totalReadBook))
                Slogan(title: "最长连续打卡", unit: "天", value: Int64(longHit))
                
            }
            .padding(.bottom,30)
        }
    }
    
    var body: some View {
        NavigationView {
            //            ScrollView{
            
            VStack ( spacing:15)        {
                Picker(selection: $sumType, label: Text("DayPiker")) {
                    Text("全部").tag(SumType.all)
                    Text("本年").tag(SumType.year)
                    Text("本月").tag(SumType.month)
                }.labelsHidden()
                    .pickerStyle(SegmentedPickerStyle())
                                        .onChange(of: sumType, perform: { val in
                                            initAllLog()
                                        })
                
                TabView(selection: $sumType){
                    mainView.id(1) .tag(SumType.all)
                    mainView.id(2) .tag(SumType.year)
                    mainView.id(3) .tag(SumType.month)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.linear, value: sumType)
                .onChange(of: sumType, perform: {val in
                    initAllLog()
                })
                
            }
            .padding()
            .task {
                todayReadMin = ReadLogPersistence.checkAndBuildTodayLog(context:context).readMinutes
                initAllLog()
            }
            
            
            //            }
            .navigationTitle("成就")
            .navigationBarTitleDisplayMode(.inline)
//            .toolbar(content: {
//                Button(action: {
//                    let image = mainView.snapshot()
//
//                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
//                }){
//                    Image(systemName: "square.and.arrow.up")
//                }
//            })
            
            
        }
        
    }
    
    func initAllLog(){
        totalReadDay = 0
        totalReadMin = 0
        totalReadBook = 0
        
        longHit = 0
        
        var lastHitDay:Date? = nil
        
        for log:ReadLog in logs{
            print(log)
            if(log.readMinutes>0){
                
                if(sumType == .year && Date().format(format: "YYYY") != log.day.format(format: "YYYY")) {
                    //说明不是本年，不参与计算
                    continue
                }
                if(sumType == .month && Date().format(format: "YYYY-MM") != log.day.format(format: "YYYY-MM")) {
                    //说明不是本月，不参与计算
                    continue
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
                        longHit = 0
                    }
                    
                }else{
                    
                    longHit += 1
                }
                
                lastHitDay = log.day
            }
            
        }
        
        for book:Book in books{
            if let doneTime = book.doneTime {
                if(sumType == .year && Date().format(format: "YYYY") != doneTime.format(format: "YYYY")) {
                    //说明不是本年，不参与计算
                    continue
                }
                if(sumType == .month && Date().format(format: "YYYY-MM") != doneTime.format(format: "YYYY-MM")) {
                    //说明不是本月，不参与计算
                    continue
                }
                
                
                totalReadBook += 1
            }
            if(book.isDone){
                
            }
        }
    }
    
}

struct Statistics_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{
            Statistics()
        }
        
    }
}




