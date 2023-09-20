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
        
        
        let logInYear:[Int] = keyStore.object(forKey: "logInYear") as? [Int] ??  [Int](repeating: 0, count: 365)
        
        
        let targetMinPerdayCloud  = keyStore.object(forKey: "targetMinPerday") as? Int ?? 45
        let lastReadDateCloud =  keyStore.object(forKey: "lastReadDate") as? Date ?? nil
        
        let dayIndex = now.dayOfYear
        let todayReadMinCloud = logInYear[dayIndex-1]
        
        
        return BookTimeWidgetEntry(date: now,lastReadDate:lastReadDateCloud, todayReadMin: todayReadMinCloud,targetMinPerday: targetMinPerdayCloud,logInYear: logInYear)
        
        
        
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
    let circleDia = 108.0
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
        
        ProgressRingView(progress: .constant(process),
                         thickness: 12,
                         width: circleDia,
                         gradient: Gradient(colors: [Color("AccentColor").opacity(0.6), Color("AccentColor")])
        )
        .overlay{
            Text("\(entry.todayReadMin) Min")
                .font(.system(.subheadline ,design: .rounded).bold())
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
            
            
            ProgressRingView(progress: .constant(process),
                             thickness: 12,
                             width: circleDia,
                             gradient: Gradient(colors: [Color("AccentColor").opacity(0.6), Color("AccentColor")])
            )
            .overlay{
                Text("\(Int( round( process * 100)))%")
                    .font(.system(.subheadline ,design: .rounded).bold())
            }
            
        }

//        .padding(.leading, 12)
//        .padding(.trailing,20)
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
//            .padding(10)
            
            Spacer()
            mediumView(isInLarge: true)
        }
//        .padding(.vertical,10)
//        .padding(.bottom,15)
    }
    
    @ViewBuilder
    var circularView:some View{
        Gauge(value: process, label: {
            VStack{
                Text("\(entry.todayReadMin)")
                    .font(.system(.headline ,design: .rounded).bold())
                Text("min")
                    .font(.footnote.bold())
            }
            
        })
        .gaugeStyle(.accessoryCircularCapacity)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)    // << here !!
                .widgetBackground(Color("WidgetBackground"))
            
        case .systemMedium:
            mediumView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)    // << here !!
                .widgetBackground(Color("WidgetBackground"))
            
        case .systemLarge:
            largeView
                .frame(maxWidth: .infinity, maxHeight: .infinity)    // << here !!
                .widgetBackground(Color("WidgetBackground"))
            
        case .accessoryCircular:
            circularView
                .widgetBackground(Color("WidgetBackground"))
            
        default:
            smallView
        }
                
        
    }
}
@main
struct BookTimeWidget: Widget {
    let kind: String = "BookTimeWidget"
    
    var families: [WidgetFamily] {
        return [.systemMedium,.systemSmall,.systemLarge,.accessoryCircular]
    }
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BookTimeWidgetEntryView(entry: entry)
        }
        
        .configurationDisplayName("BookTime")
        .description("Track your reading time")
        .supportedFamilies(families)
    }
}

struct BookTimeWidget_Previews: PreviewProvider {
    static var previews: some View {
        BookTimeWidgetEntryView(entry: BookTimeWidgetEntry(date: Date(),lastReadDate: Date().start(), todayReadMin: 125,targetMinPerday: 90,logInYear: [Int](repeating: 0, count: 366)))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
        
    }
}

extension View {
    func widgetBackground(_ backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView).padding(15)
        }
    }
}
