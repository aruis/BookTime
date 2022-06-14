//
//  BookTimeWidget.swift
//  BookTimeWidget
//
//  Created by Liu Rui on 2022/5/9.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
        
    let keyStore = NSUbiquitousKeyValueStore()
    
    func placeholder(in context: Context) -> BookTimeWidgetEntry {
        BookTimeWidgetEntry(date: Date(), lastReadDate:nil, todayReadMin: 0,targetMinPerday: 45)
    }

    func getSnapshot(in context: Context, completion: @escaping (BookTimeWidgetEntry) -> ()) {
        completion(buildEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let now = Date()
        let nextUpdateDate = Calendar.current.date(byAdding: .day, value: 1, to: now.start())!

        var entries:[BookTimeWidgetEntry] = []
        
        for i in 1...23{
            let entryDate = Calendar.current.date(byAdding: .hour, value: i, to: now)!
            entries.append(buildEntry(entryDate))
        }
        
        let timeline = Timeline(entries: entries, policy: .after(nextUpdateDate))
        
        completion(timeline)
    }
    
    func buildEntry(_ date:Date? = nil)->BookTimeWidgetEntry{
                                
        let userDefaults =  UserDefaults(suiteName: "group.com.aruistar.BookTime")
        var now = Date()
        
        if let date = date {
            now = date
        }
        
        
        
        if let userDefaults = userDefaults {

            var todayReadMin  = userDefaults.integer(forKey: "todayReadMin")
            var targetMinPerday  = userDefaults.integer(forKey: "targetMinPerday")
            let lastReadDateString = userDefaults.string(forKey: "lastReadDateString")
            var lastReadDate:Date? =  userDefaults.object(forKey: "lastReadDate") as? Date

            if lastReadDateString != now.format("YYYY-MM-dd"){ // 不是今天的
                todayReadMin = 0
            }

            
            let todayReadMinCloud  =  keyStore.object(forKey: "todayReadMin") as! Int?
            
            if let todayReadMinCloud = todayReadMinCloud {
                let targetMinPerdayCloud  = keyStore.object(forKey: "targetMinPerday") as! Int
                let lastReadDateStringCloud = keyStore.string(forKey: "lastReadDateString")
                let lastReadDateCloud =  keyStore.object(forKey: "lastReadDate") as? Date

                if lastReadDateStringCloud == now.format("YYYY-MM-dd") && todayReadMinCloud > todayReadMin{
                    todayReadMin = todayReadMinCloud
                    targetMinPerday = targetMinPerdayCloud
                    lastReadDate = lastReadDateCloud
                }
            }
            

            return BookTimeWidgetEntry(date: now,lastReadDate:lastReadDate, todayReadMin: todayReadMin,targetMinPerday: targetMinPerday)
        } else{
            return BookTimeWidgetEntry(date: now,lastReadDate:nil, todayReadMin: 0,targetMinPerday: 45)
        }
       
    }
}

struct BookTimeWidgetEntry: TimelineEntry {
    let date: Date
    
    let lastReadDate:Date?
    let todayReadMin:Int
    let targetMinPerday:Int
}


struct BookTimeWidgetEntryView : View {
    var process:CGFloat{
        get{
            if(entry.targetMinPerday>0){
                return CGFloat( entry.todayReadMin)/CGFloat( entry.targetMinPerday)
            }else{
                return CGFloat( entry.todayReadMin)/CGFloat( 45)
            }
            
        }
    }
    
    @Environment(\.widgetFamily) var family: WidgetFamily
    
    var entry: Provider.Entry
    let circleDia = 130.0

    @ViewBuilder
    var smallView:some View{
        ZStack{
            Circle()
                .trim(from: 0.0, to:1.0)
                .stroke(Color("AccentColor"), style: StrokeStyle(lineWidth: 12, lineCap: CGLineCap.round))
                .frame(width:circleDia)
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
                ), style: StrokeStyle(lineWidth: 12, lineCap: CGLineCap.round))
                .frame(width:circleDia)
                .rotationEffect(.degrees(-90))
                .padding()
            
            
            
        }
        .frame(width: circleDia,height: circleDia)
        .overlay{
            Text("\(entry.todayReadMin) Min")
                .font(.system(.headline ,design: .rounded).bold())
        }

    }

    @ViewBuilder
    var mediumView:some View{
        HStack{
            
            VStack(alignment: .leading,spacing: 2){
                if entry.todayReadMin > 0 {
                    Text("\(entry.todayReadMin) Minutes Today")
                        .font(.system(.title2,design: .rounded))
                }else{
                    Text("No Reading Today")
                        .font(.system(.title2,design: .rounded))
                    if let lastReadDate = entry.lastReadDate{
                        HStack(spacing:0){
                            Text("Since Last:")
                            Text(lastReadDate,style: .relative)
                        }
                        .font(.system(.caption,design: .rounded))
                        .opacity(0.8)
                    }
                }
                
                
//                Text("\(Int( round( process * 100))) % of the Plan Completed")
                
            }
            
            
            Spacer()
            
            
            ZStack{
                Circle()
                    .trim(from: 0.0, to:1.0)
                    .stroke(Color("AccentColor"), style: StrokeStyle(lineWidth: 12, lineCap: CGLineCap.round))
                    .frame(width:circleDia)
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
                    ), style: StrokeStyle(lineWidth: 12, lineCap: CGLineCap.round))
                    .frame(width:circleDia)
                    .rotationEffect(.degrees(-90))
                    .padding()
                
                
                
            }
            .frame(width: circleDia,height: circleDia)
            .overlay{
                Text("\(Int( round( process * 100)))%")
                    .font(.system(.headline ,design: .rounded).bold())
            }
            
        }
        .padding(.leading, 12)
    }


    
    var body: some View {
        switch self.family {
           case .systemSmall:
             smallView
           case .systemMedium:
             mediumView
           default:
             smallView
           }

        
//        VStack{
//            let encodedData  = UserDefaults(suiteName: "group.com.aruistar.BookTime")!.object(forKey: "sharedata") as? Data
//            /* Decoding it using JSONDecoder*/
//            if let carEncoded = encodedData {
//                 let carDecoded = try? JSONDecoder().decode(ShareData.self, from: carEncoded)
//                if let car = carDecoded{
//                    Text("\(car.todayReadMin)")
//                    // You successfully retrieved your car object!
//                }
//            }
//
//
//            Text(entry.date, style: .time)
//        }.onAppear{
//        }
        

        
    }
}
@main
struct BookTimeWidget: Widget {
    let kind: String = "BookTimeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BookTimeWidgetEntryView(entry: entry)
        }        
        .configurationDisplayName("BookTime")
        .description("Reading timing buddy")
        .supportedFamilies([.systemMedium,.systemSmall])
    }
}

struct BookTimeWidget_Previews: PreviewProvider {
    static var previews: some View {
        BookTimeWidgetEntryView(entry: BookTimeWidgetEntry(date: Date(),lastReadDate: Date().start(), todayReadMin: 25,targetMinPerday: 90))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
