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
        BookTimeWidgetEntry(date: Date(), lastReadDate:nil, todayReadMin: 0,targetMinPerday: 45,logInYear:  [Int](repeating: 0, count: 365))
    }

    func getSnapshot(in context: Context, completion: @escaping (BookTimeWidgetEntry) -> ()) {
        completion(buildEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let now = Date()
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: now)!

        let entries:[BookTimeWidgetEntry] = [
            buildEntry(now),
            buildEntry(nextUpdateDate)
        ]
        
//        for i in 1...23{
//            let entryDate = Calendar.current.date(byAdding: .hour, value: i, to: now)!
//            entries.append(buildEntry(entryDate))
//        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        
        completion(timeline)
    }
    
    func isSameDay(date1: Date, date2: Date) -> Bool {
        return Calendar.current.isDate(date1, equalTo: date2, toGranularity: .day)
        
//        let diff = Calendar.current.dateComponents([.day], from: date1, to: date2)
//        if diff.day == 0 {
//            return true
//        } else {
//            return false
//        }
    }
    
    func buildEntry(_ date:Date? = nil)->BookTimeWidgetEntry{
        
        var now = Date()
        
        if let date = date {
            now = date
        }
        
        let todayReadMinCloud  =  keyStore.object(forKey: "todayReadMin") as? Int                
        
        let logInYear:[Int] = keyStore.object(forKey: "logInYear") as? [Int] ??  [Int](repeating: 0, count: 365)
        
        if var todayReadMinCloud = todayReadMinCloud {
            let targetMinPerdayCloud  = keyStore.object(forKey: "targetMinPerday") as? Int ?? 45
            let lastReadDateCloud =  keyStore.object(forKey: "lastReadDate") as? Date ?? nil
            
            if let lastReadDateCloud = lastReadDateCloud {
                if  !Calendar.current.isDateInToday(lastReadDateCloud){
                    todayReadMinCloud = 0
                }
                
//                if !isSameDay(date1: lastReadDateCloud, date2: now) {
//                    todayReadMinCloud = 0
//                }
            }else{
                todayReadMinCloud = 0
            }
            
            return BookTimeWidgetEntry(date: now,lastReadDate:lastReadDateCloud, todayReadMin: todayReadMinCloud,targetMinPerday: targetMinPerdayCloud,logInYear: logInYear)

        } else{
            return BookTimeWidgetEntry(date: now,lastReadDate:nil, todayReadMin: 0,targetMinPerday: 45,logInYear: logInYear)
        }
       
    }
}

struct BookTimeWidgetEntry: TimelineEntry {
    let date: Date
    
    let lastReadDate:Date?
    let todayReadMin:Int
    let targetMinPerday:Int
    let logInYear:[Int]
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
    var targetMinPerday:Int
    
    init(entry:BookTimeWidgetEntry){
        self.entry = entry
        
        if(entry.targetMinPerday>0){
            targetMinPerday = entry.targetMinPerday
        }else{
            targetMinPerday = 45
        }
    }
    
    
    var remainDays:Int {
        let today = Date()
        let allDays = Date(Date().format("yyyy") + "-12-31").dayOfYear
        return allDays - today.dayOfYear
    }


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
    func mediumView(isInLarge:Bool = false) -> some View{
        HStack{
            
            VStack(alignment: .leading,spacing: 4){
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
                
                if(isInLarge){
                    Text("\(remainDays) days left this year")
                        .font(.system(.caption,design: .rounded))
                        .opacity(0.8)
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

    @ViewBuilder
    var largeView:some View{
        VStack(spacing:0){
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 9),spacing: 2),],spacing: 2) {
                ForEach(0...(Date(Date().format("yyyy") + "-12-31").dayOfYear - 1),id: \.self){index in
                    Rectangle()
                        .frame(width: 9,height: 9)
                        .foregroundColor(Color("AccentColor").opacity(squareOpacity(entry.logInYear[index])))
//                        .foregroundColor(Color("AccentColor").opacity(1.0))
                        
                    
                }
            }
            .clipShape(Rectangle())
            .padding(10)

            Spacer()
            mediumView(isInLarge: true)
        }
        .padding(.vertical,10)

    }
    
    @ViewBuilder
    var circularView:some View{

            
            ZStack{
                Circle()
                    .trim(from: 0.0, to:1.0)
                    .stroke(.white, style: StrokeStyle(lineWidth: 12, lineCap: .round))
//                    .frame(width:100)
                    .rotationEffect(.degrees(-90))
                    .opacity(0.3)
                //                        .opacity(0)
//                    .padding()
                
                Circle()
                    .trim(from: 0.0, to: process)
                //                        .trim(from: 0.0,to:  1.0)
                    .stroke( AngularGradient(
                        gradient: Gradient(colors: [.white,.white]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees( 360 * process )
                    ), style: StrokeStyle(lineWidth: 12, lineCap: .butt))
//                    .frame(width:100)
                    .rotationEffect(.degrees(-90))
//                    .padding()
                
                
                
            }
//            .padding(4)
//            .frame(width: 100,height: 100)
            .overlay{
                VStack{
                    Text("\(entry.todayReadMin)")
                        .font(.system(.headline ,design: .rounded).bold())
                    Text("min")
                        .font(.footnote.bold())
                }
                
            }
        

    }
                                         
    
    func squareOpacity(_ min:Int) -> Double{
        if min == 0{
            return 0.1
        }else {
            let per =  Double(min)/Double(targetMinPerday)
            if per < 0.3 {
                return 0.3
            } else if per >= 1.0{
                return 1.0
            }else {
                return per
            }
        }
        
    }
    

                                         
                                        
    

    
    var body: some View {
        switch self.family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView()
        case .systemLarge:
            largeView
        case .accessoryCircular:
            circularView

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

    var families: [WidgetFamily] {
        var f: [WidgetFamily] = [.systemMedium,.systemSmall,.systemLarge,]
        if #available(iOSApplicationExtension 16.0, *) {
            f.append(.accessoryCircular)
        }
        return f
    }
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BookTimeWidgetEntryView(entry: entry)
        }        
        .configurationDisplayName("BookTime")
        .description("Reading timing buddy")
        .supportedFamilies(families)
    }
}

struct BookTimeWidget_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOSApplicationExtension 16.0, *) {
            BookTimeWidgetEntryView(entry: BookTimeWidgetEntry(date: Date(),lastReadDate: Date().start(), todayReadMin: 125,targetMinPerday: 90,logInYear: [Int](repeating: 0, count: 366)))
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
        } else {
            BookTimeWidgetEntryView(entry: BookTimeWidgetEntry(date: Date(),lastReadDate: Date().start(), todayReadMin: 25,targetMinPerday: 90,logInYear: [Int](repeating: 0, count: 366)))
                .previewContext(WidgetPreviewContext(family: .systemMedium))

            // Fallback on earlier versions
        }
    }
}
