//
//  BookTimeWidget.swift
//  BookTimeWidget
//
//  Created by Liu Rui on 2022/5/9.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> BookTimeWidgetEntry {
        BookTimeWidgetEntry(date: Date(), latReadDate:nil, todayReadMin: 0,targetMinPerday: 45)
    }

    func getSnapshot(in context: Context, completion: @escaping (BookTimeWidgetEntry) -> ()) {
        completion(buildEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let nextUpdateDate = Calendar.current.date(byAdding: .day, value: 1, to: Date().start())!

        let timeline = Timeline(entries: [buildEntry()], policy: .after(nextUpdateDate))
        
        completion(timeline)
    }
    
    func buildEntry(_ date:Date? = nil)->BookTimeWidgetEntry{
        
        let userDefaults =  UserDefaults(suiteName: "group.com.aruistar.BookTime")
        var now = Date()
        
        if let date = date {
            now = date
        }
        
        if let  userDefaults = userDefaults {
                                    
            var todayReadMin  = userDefaults.integer(forKey: "todayReadMin")
            let targetMinPerday  = userDefaults.integer(forKey: "targetMinPerday")
            let lastReadDateString = userDefaults.string(forKey: "lastReadDateString")
            let latReadDate:Date? =  userDefaults.object(forKey: "lastReadDate") as? Date

            if(lastReadDateString != now.format("YYYY-MM-dd")){
                todayReadMin = 0
            }
            
            return BookTimeWidgetEntry(date: now,latReadDate:latReadDate, todayReadMin: todayReadMin,targetMinPerday: targetMinPerday)
        }else{
            return BookTimeWidgetEntry(date: now,latReadDate:nil, todayReadMin: 0,targetMinPerday: 45)
        }
       
    }
}

struct BookTimeWidgetEntry: TimelineEntry {
    let date: Date
    
    let latReadDate:Date?
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
                    if let latReadDate = entry.latReadDate{
                        HStack{
                            Text("Since Last:")
                            Text(latReadDate,style: .relative)
                        }
                        .font(.system(.caption,design: .rounded))
                    }
                }
                
                
//                Text("\(Int( round( process * 100))) % of the Plan Completed")
                
            }
            
            
//            Spacer()
            
            
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
        .padding(.leading,10)
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
        BookTimeWidgetEntryView(entry: BookTimeWidgetEntry(date: Date(),latReadDate: Date().start(), todayReadMin: 0,targetMinPerday: 90))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
