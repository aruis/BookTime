//
//  TimerView.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/1.
//

import SwiftUI
import LocalAuthentication
import AlertToast
import WidgetKit

struct TimerView: View {
    
    @AppStorage("isRemind") var isRemind = false
    
    @AppStorage("remindDateHour") var reminDateHour = -1
    @AppStorage("remindDateMin") var reminDateMin = -1
    
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    @State private var count = 0
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @AppStorage("targetMinPerday") var targetMinPerday = 45
    
    @State private var orientation = UIDeviceOrientation.unknown
    
    @ObservedObject var book: Book
       
    
    @State private var thisMinute:Int  = 0
    
    @State private var beginDate  = Date()
    
    
    @State private var changeTabAuto = false
    @State private var lastShowTab:ShowTimeType? = nil
    
    @State private var isHit:Bool = false
    
    @State private var showToast = false
    
    @State private var oldLight:CGFloat = 0
    @State private var lowLight:Bool = false
    
    let generator = UINotificationFeedbackGenerator()
    
    enum ShowTimeType : Int,CaseIterable{
        case timer
        case time
        case today
    }
    
    @Binding var handShowTimer:Bool
    
    @State var isShowButtons:Bool = true
    
    @State private var tabSelected = ShowTimeType.timer
    
    @State private var tabSelectedStore = ShowTimeType.timer
        
    var body: some View {
        TabView(selection: $tabSelected){
            TimelineView(.periodic(from: beginDate, by: 1)) { context in
                let date = context.date
                let components = Calendar.current.dateComponents([.hour,.minute,.second], from: beginDate, to: date)
                let thisMinute = Int( BookPersistenceController.shared.checkAndBuildTodayLog().readMinutes)

                let s = "\(components.second!)".count == 1 ? "0\(components.second!)" : "\(components.second!)"
                let hour = String( thisMinute.asString().split(separator: ":")[0])
                let min = String( thisMinute.asString().split(separator: ":")[1])
                
                let process = targetMinPerday > 0 ? CGFloat( thisMinute)/CGFloat( targetMinPerday) : CGFloat( thisMinute)/CGFloat( 45)
                let batteryLevel = Int(round(UIDevice.current.batteryLevel * 100))
                
                ClockView(hour: hour, min: min, second: s ,headTitle:  targetMinPerday > 0 ? String(localized: "\( Int( round( process * 100))) % of the Plan Completed") : String(localized: "Today"),batteryLevel: batteryLevel,inCharging: UIDevice.current.batteryState == .charging)
                
            }
            .tag(ShowTimeType.today)
                        
            TimelineView(.periodic(from: beginDate, by: 1)) { context in
                let date = context.date
                let components = Calendar.current.dateComponents([.hour,.minute,.second], from: beginDate, to: date)
                
                let s = "\(components.second!)".count == 1 ? "0\(components.second!)" : "\(components.second!)"
                let hour = String( thisMinute.asString().split(separator: ":")[0])
                let min = String( thisMinute.asString().split(separator: ":")[1])
                let batteryLevel = Int(round(UIDevice.current.batteryLevel * 100))
                ClockView(hour: hour, min: min, second: s,batteryLevel: batteryLevel,inCharging: UIDevice.current.batteryState == .charging)
                
            }
            .tag(ShowTimeType.timer)
            
            
            
            TimelineView(.periodic(from: beginDate, by: 1)) { context in
                let date = context.date
                let dataArr  = date.format("HH:mm:ss").split(separator: ":")
                let h = String(dataArr[0])
                let m = String(dataArr[1])
                let s = String(dataArr[2])
                let batteryLevel = Int(round(UIDevice.current.batteryLevel * 100))
                
                ClockView(hour: h, min: m, second: s,headTitle: date.dayString(),batteryLevel: batteryLevel,inCharging: UIDevice.current.batteryState == .charging)
                
                
                
            }
            .tag(ShowTimeType.time)
            
        }
        .onTapGesture(count: 2) {
            isShowButtons.toggle()
        }
        .overlay{
            VStack {
                Spacer()
                HStack(spacing:15){
                    if handShowTimer{
                        Button(action: {
                            dismiss()
                        }, label: {
                            Image(systemName: "clear")
                        })
                        .font(.system(size: 23))
                        .buttonStyle(.bordered)
                        
                        
                    }
                                       
                    if handShowTimer && UIDevice.current.userInterfaceIdiom == .phone {
                        Button(action: {
                            if  verticalSizeClass == .compact{
                                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                            }else{
                                UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                            }
                            
                        }, label: {
                            ZStack(alignment: .bottomTrailing){
                                if  verticalSizeClass == .compact{
                                    Image( systemName: "iphone")
                                    Image( systemName: "iphone.landscape").opacity(0.35)
                                }else{
                                    Image( systemName: "iphone.landscape")
                                    Image( systemName: "iphone").opacity(0.35)
                                }
                                
                            }
                            
                        })
                        .font(.system(size: 23))
                        .buttonStyle(.bordered)
                    }
                    
                    Button(action: {
                        if lowLight{
                            UIScreen.main.brightness = oldLight
                        }else{
                            oldLight = UIScreen.main.brightness
                            UIScreen.main.brightness = CGFloat(0.05)
                        }
                        lowLight.toggle()
                        
                    }, label: {
                        Image(systemName: lowLight ? "lightbulb":"lightbulb.fill")
                    })
                    .font(.system(size: 23))
                    .buttonStyle(.bordered)
                                        
                    
                }
            }
            .padding(.bottom,60)
            .opacity(isShowButtons ? 1 : 0)
            .animation(.default, value: isShowButtons)
            
        }
        .onRotate { newOrientation in
            
            if newOrientation.isFlat{
                return
            }

                        
            if orientation != .unknown && orientation.isPortrait == newOrientation.isPortrait {
                return
            }
            
            orientation = newOrientation
            
            tabSelectedStore = tabSelected
            if tabSelected != .today{
                tabSelected = .today
            }else{
                tabSelected = .time
            }
            
            
            DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
                tabSelected = tabSelectedStore
            })
        }
        
        .onChange(of: tabSelected, perform: { _ in
            changeTabAuto = false
        })
        .animation(.easeInOut, value: tabSelected)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: isShowButtons ? .always : .never))
        .foregroundColor(isHit ? Color("AccentColor") : .white)
        .background(.black)
        .animation(.linear, value: verticalSizeClass)
        .toast(isPresenting: $showToast,duration: 6,tapToDismiss: true){
            AlertToast( type: .complete(.green), title: String(localized: "Today's goal has been reached"))
        }
        .onAppear(perform: {
            
            UIApplication.shared.isIdleTimerDisabled = true
            UIDevice.current.isBatteryMonitoringEnabled = true
            oldLight = UIScreen.main.brightness
            
            if(targetMinPerday>0 && BookPersistenceController.shared.checkAndBuildTodayLog().readMinutes
               >= targetMinPerday
            ){
                isHit = true
            }

        })
        .onDisappear(perform: {
            UIScreen.main.brightness = oldLight
            UIApplication.shared.isIdleTimerDisabled = false
            UIDevice.current.isBatteryMonitoringEnabled = false
            
            timer.upstream.connect().cancel()
            
            if isRemind {
                NotificationTool.add(hour: reminDateHour, minute: reminDateMin,readedToday :thisMinute > 0)
            }
            
        })
        .onReceive(timer, perform: { now in
//            count += 10
            
//            let nowStr = now.format("mm:ss")
//            if (nowStr == "29:59" || nowStr == "59:59" ) && tabSelected != .time {
//                lastShowTab = tabSelected
//                tabSelected  = .time
//                DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {
//                    changeTabAuto = true
//                })
//            }
//
//            if (nowStr == "31:00" || nowStr == "01:00" ) && changeTabAuto {
//                if let lastShowTab = lastShowTab {
//                    tabSelected = lastShowTab
//                }
//                changeTabAuto = false
//            }
                        
            thisMinute += 1
            
            print("thisMinute: \(thisMinute)")
            
            let readLog = BookPersistenceController.shared.checkAndBuildTodayLog()
            
            
            if book.readMinutes == 0 { //第一次读
                book.firstReadTime = now
            }
            book.readMinutes += 1
            if let lastReadTime = book.lastReadTime {
                if(lastReadTime.format("YYYY-MM-dd") != now.format("YYYY-MM-dd")){
                    book.readDays += 1
                }
            }else{
                book.readDays  = 1
            }
            book.lastReadTime = now
            readLog.readMinutes += 1
            
            if(targetMinPerday>0 && targetMinPerday == readLog.readMinutes){
                generator.notificationOccurred(.success)
                isHit = true
                showToast = true
            }
            
            UserDefaults(suiteName:"group.com.aruistar.BookTime")!.set(readLog.readMinutes, forKey: "todayReadMin")
            UserDefaults(suiteName:"group.com.aruistar.BookTime")!.set(targetMinPerday, forKey: "targetMinPerday")
            UserDefaults(suiteName:"group.com.aruistar.BookTime")!.set(now.format("YYYY-MM-dd"), forKey: "lastReadDateString")
            UserDefaults(suiteName:"group.com.aruistar.BookTime")!.set(now, forKey: "lastReadDate")
            WidgetCenter.shared.reloadAllTimelines()
            
            DispatchQueue.main.async {
                do{
                    try context.save()
                }catch{
                    print(error)
                }
            }
            
        })
        
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        //        NavigationView {
        TimerView(book: (BookPersistenceController.testData?.first)!,handShowTimer : .constant(true) )
            .environment(\.managedObjectContext, BookPersistenceController.preview.container.viewContext)
            .previewInterfaceOrientation(.portrait)
        //        }
        
        
    }
}


struct ClockView: View {
    var hour:String
    var min:String
    var second:String
    var headTitle:String?
    var foot:String?
    var batteryLevel:Int
    var inCharging:Bool
    
    var batteryImg:Image{
        get {
            if inCharging {
                return Image(systemName: "battery.100.bolt")
            }else  if batteryLevel < 13 {
                return Image(systemName: "battery.0")
            } else if batteryLevel < 38{
                return Image(systemName: "battery.25")
            }else if batteryLevel < 63{
                return Image(systemName: "battery.50")
            }else if batteryLevel < 88{
                return Image(systemName: "battery.75")
            }else{
                return Image(systemName: "battery.100")
            }
            
        }
    }
    
    @AppStorage("timerShowSec") private var timerShowSec = true
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        HStack(alignment: .firstTextBaseline){
            
            Text(hour)
                .monospacedDigit()
            
            Text(":")
                .opacity(Int(second)!%2==0 ? 1 : 0)
            
            
            Text(min)
                .monospacedDigit()
            
            if(timerShowSec){
                Text(":")
                    .opacity(Int(second)!%2==0 ? 1 : 0)
                
                
                Text(second)
                    .monospacedDigit()
                
            }
            
            //
        }
        .overlay(
            VStack{
                Text(headTitle ?? "")
                    .font(.system(  verticalSizeClass == .compact ? .title3 : .caption ,design:.rounded))
                    .frame(width: 300)
            }.padding(.top,-30)
            
            ,alignment:.top
        )
        .overlay(
            VStack{
                Text("\(batteryLevel)% \(batteryImg)")
                    .monospacedDigit()
                    .font(.subheadline)
                //                Label{
                //                    Text("\(batteryLevel)")
                //                } icon: {batteryImg}
                //                Label(,icon: batteryImg)
            }.padding(.bottom,-100)
            ,alignment: .bottom
        )
        
        .animation(.easeInOut, value: timerShowSec)
        //        .font(.custom("AzeretMono-Thin", size: verticalSizeClass == .compact ? 100: 55,relativeTo: .largeTitle).monospacedDigit())
        .font(.system(size: verticalSizeClass == .compact ? 100: 55,design: .serif))
        .padding(.bottom,20)
        .onTapGesture {
            timerShowSec.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        
    }
}
