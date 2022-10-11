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
import FlipView
import PacmanProgress

struct TimerView: View {
    let keyStore = NSUbiquitousKeyValueStore()
    
    @AppStorage("isRemind") var isRemind = false
    
    @AppStorage("remindDateHour") var reminDateHour = -1
    @AppStorage("remindDateMin") var reminDateMin = -1
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var count = 0
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @AppStorage("targetMinPerday") var targetMinPerday = 45
    
    @State private var orientation = UIDeviceOrientation.unknown
    
    @ObservedObject var book: Book
    
    @State private var thisMinute:Int  = 0
    
    @State private var beginDate  = Date()
    
    @State private var readSecond = 0
    
    @State private var showRealTime = false
    
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
    
    @State private var isShowProgress = true
    
    @State private var landscapeRight:Bool?
    
    var body: some View {
//        TabView(selection: $tabSelected){
//            TimelineView(.periodic(from: beginDate, by: 1)) { context in
//                let date = context.date
//                let components = Calendar.current.dateComponents([.hour,.minute,.second], from: beginDate, to: date)
//                let thisMinute = Int( BookPersistenceController.shared.checkAndBuildTodayLog().readMinutes)
//
//                let s = "\(components.second!)".count == 1 ? "0\(components.second!)" : "\(components.second!)"
//                let hour = String( thisMinute.asString().split(separator: ":")[0])
//                let min = String( thisMinute.asString().split(separator: ":")[1])
//
//                let process = targetMinPerday > 0 ? CGFloat( thisMinute)/CGFloat( targetMinPerday) : CGFloat( thisMinute)/CGFloat( 45)
//                let batteryLevel = Int(round(UIDevice.current.batteryLevel * 100))
//
//                ClockView(hour: hour, min: min, second: s ,headTitle:  targetMinPerday > 0 ? String(localized: "\( Int( round( process * 100))) % of the Plan Completed") : String(localized: "Today"),batteryLevel: batteryLevel,inCharging: UIDevice.current.batteryState == .charging)
//
//            }
//            .ignoresSafeArea()
//            .tag(ShowTimeType.today)
//
//            TimelineView(.periodic(from: beginDate, by: 1)) { context in
//                let date = context.date
//                let components = Calendar.current.dateComponents([.hour,.minute,.second], from: beginDate, to: date)
//
//                let s = "\(components.second!)".count == 1 ? "0\(components.second!)" : "\(components.second!)"
//                let hour = String( thisMinute.asString().split(separator: ":")[0])
//                let min = String( thisMinute.asString().split(separator: ":")[1])
//                let batteryLevel = Int(round(UIDevice.current.batteryLevel * 100))
//                ClockView(hour: hour, min: min, second: s,batteryLevel: batteryLevel,inCharging: UIDevice.current.batteryState == .charging)
//
//            }
//            .ignoresSafeArea()
//            .tag(ShowTimeType.timer)
//
//
//
//            TimelineView(.periodic(from: beginDate, by: 1)) { context in
//                let date = context.date
//                let dataArr  = date.format("HH:mm:ss").split(separator: ":")
//                let h = String(dataArr[0])
//                let m = String(dataArr[1])
//                let s = String(dataArr[2])
//                let batteryLevel = Int(round(UIDevice.current.batteryLevel * 100))
//
//                ClockView(hour: h, min: m, second: s,headTitle: date.dayString(),batteryLevel: batteryLevel,inCharging: UIDevice.current.batteryState == .charging)
//
//
//
//            }
//            .ignoresSafeArea()
//            .tag(ShowTimeType.time)
//
//        }
        TimelineView(.periodic(from: beginDate, by: 1)) { context in
            let date = context.date
            
            // 当前时间
            let dataArr  = date.format("HH:mm:ss").split(separator: ":")
            
            let hh = String(dataArr[0])
            let mm = String(dataArr[1])
            let ss = String(dataArr[2])

            // 本次阅读时间

            let thisS = "\(readSecond%60)".count == 1 ? "0\(readSecond%60)" : "\(readSecond%60)"
            let thisH = String( thisMinute.asString().split(separator: ":")[0])
            let thisM = String( thisMinute.asString().split(separator: ":")[1])
            let batteryLevel = Int(round(UIDevice.current.batteryLevel * 100))
                                                
            // 今日已阅读时间
            let thisMinute = Int( BookPersistenceController.shared.checkAndBuildTodayLog().readMinutes)
            
            let todayS = thisS
            let todayH = String( thisMinute.asString().split(separator: ":")[0])
            let todayM = String( thisMinute.asString().split(separator: ":")[1])
                        
            let process = targetMinPerday > 0 ? Float( thisMinute)/Float( targetMinPerday) : Float( thisMinute)/Float( 45)
            
            let hour = isShowProgress ? todayH : showRealTime ? hh : thisH
            let min = isShowProgress ? todayM : showRealTime ? mm : thisM
            let second = isShowProgress ? todayS : showRealTime ? ss : thisS
            
            let title = isShowProgress ? String(localized: "\( Int( round( process * 100))) % of the Plan Completed")  :  date.dayString()
                        
            ClockView(hour: hour, min:  min, second: second,headTitle: title, batteryLevel: batteryLevel,inCharging: UIDevice.current.batteryState == .charging,progress: .constant(process),isShowProgress:$isShowProgress,clockTap:{
                showRealTime.toggle()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            })
                .onTapGesture(count: 2) {
                    isShowButtons.toggle()
                }
                .onTapGesture {
                    if !isShowProgress {
                        isShowProgress = true
                        DispatchQueue.main.asyncAfter(deadline: .now()+3, execute: {
                            isShowProgress = false
                        })
                    } else {
                        isShowProgress = false
                    }
                    

                }

        }
        .ignoresSafeArea()
        .gesture(DragGesture().onEnded{value in
            
            if abs( value.translation.width) > 20 {
                showRealTime.toggle()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }else if value.translation.height > 20 {
                dismiss()
            }
            
        })
        .overlay{
            
            GeometryReader{geometry in
                HStack(spacing:15){
                    if handShowTimer{
                        
                        Button{
                            dismiss()
                            
                            if let landscapeRight = landscapeRight {
                                if landscapeRight{
                                    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                                    self.landscapeRight = false
                                }
                            }

                        } label: {
                            Image(systemName:"clear")
                                
                                .padding()
                                .frame(width: 50, height: 50)
                                .font(.title2)
                                .foregroundColor(.clockText)
                                .background(Color.clock)
                                .clipShape(Circle())

                        }
                        
//                        Circle()
//                            .frame(width: 50, height: 50)
//                            .foregroundColor(.clock)
//                            .overlay(
//                                Image(systemName:"clear")
//                                    .font(.title2)
//                                    .foregroundColor(.clockText)
//                            )
//                            .onTapGesture {
//                                dismiss()
//
//                                if let landscapeRight = landscapeRight {
//                                    if landscapeRight{
//                                        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
//                                        self.landscapeRight = false
//                                    }
//                                }
//
//                            }
                        
                    }
                    
                    if handShowTimer && UIDevice.current.userInterfaceIdiom == .phone {
                        
                        Button{
                            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                            
                            if  verticalSizeClass == .compact{
                                if #available(iOS 16.0, *) {
                                    windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                                } else {
                                    // Fallback on earlier versions
                                    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                                }
                                                                
                                landscapeRight = false
                            }else{

                                if #available(iOS 16.0, *) {
                                    windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
                                } else {
                                    // Fallback on earlier versions
                                    UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                                }

//
                                landscapeRight = true
                            }

                        }label: {
                            ZStack(alignment: .bottomTrailing){
                                if  verticalSizeClass == .compact{
                                    Image( systemName: "iphone")
                                    Image( systemName: "iphone.landscape").opacity(0.35)
                                }else{
                                    Image( systemName: "iphone.landscape")
                                    Image( systemName: "iphone").opacity(0.35)
                                }
                            }
                            
                            .padding()
                            .frame(width: 50, height: 50)
                            .font(.title2)
                            .foregroundColor(.clockText)
                            .background(Color.clock)
                            .clipShape(Circle())

                        }
                        
                    }
                    
                    Button{
                        if lowLight{
                            UIScreen.main.brightness = oldLight
                        }else{
                            oldLight = UIScreen.main.brightness
                            UIScreen.main.brightness = CGFloat(0.05)
                            
                        }
                        lowLight.toggle()

                    } label: {
                        Image(systemName: lowLight ? "lightbulb":"lightbulb.fill")
                            
                            .padding()
                            .frame(width: 50, height: 50)
                            .font(.title2)
                            .foregroundColor(.clockText)
                            .background(Color.clock)
                            .clipShape(Circle())

                    }
                    
                        
                    
                }
                .position(x: geometry.size.width/2, y: geometry.size.height/8 * 7)
            }
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
        .foregroundColor(.clockText)
        //        .background(.black)
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
            
            DispatchQueue.main.asyncAfter(deadline: .now()+3, execute: {
                isShowProgress = false
            })
        })
        .onDisappear(perform: {
            UIScreen.main.brightness = oldLight
            UIApplication.shared.isIdleTimerDisabled = false
            UIDevice.current.isBatteryMonitoringEnabled = false
            
            timer.upstream.connect().cancel()
            if isRemind {
                NotificationTool.add(hour: reminDateHour, minute: reminDateMin,readedToday :thisMinute > 0 || BookPersistenceController.shared.checkAndBuildTodayLog().readMinutes > 0)
            }
                                    
            WidgetCenter.shared.reloadAllTimelines()
            
        })
        .onReceive(timer, perform: { now in
            readSecond += 1
                        
                        
            if readSecond%60 != 0 {
                return
            } else {
                self.thisMinute += 1
            }
                        
            
            let readLog = BookPersistenceController.shared.checkAndBuildTodayLog()
            
            
            if book.readMinutes == 0 { //第一次读
                book.firstReadTime = now
            }
            book.readMinutes += 1
            if let lastReadTime = book.lastReadTime {
                if(!Calendar.current.isDateInToday(lastReadTime)){
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
            
            
            var logInYear =  keyStore.array(forKey: "logInYear")
            
            if var _ = logInYear {
                let dayIndex = now.dayOfYear
                if readLog.readMinutes > logInYear![dayIndex] as! Int {
                    logInYear![dayIndex-1] = readLog.readMinutes
                }
            }
            
            keyStore.set(readLog.readMinutes, forKey: "todayReadMin")
            keyStore.set(targetMinPerday, forKey: "targetMinPerday")            
            keyStore.set(now, forKey: "lastReadDate")
            keyStore.set(logInYear, forKey: "logInYear")
            
            keyStore.synchronize()
            
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
    var headTitle:String
    var foot:String?
    var batteryLevel:Int
    var inCharging:Bool
    
    @Binding var progress:Float
    
    @Binding var isShowProgress:Bool
    
    var clockTap:()->()
    
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
    
    
    var body: some View {
        
        Color.black.overlay{
            
            GeometryReader{ geometry in
                let width =  geometry.frame(in: .global).size.width/9
                let particles = width/20
                let gap = particles/2
                     
                
                HStack(spacing: width/4 ){

                    HStack(spacing: -gap ){
                        
                        FlipView(.constant(hour[0]), flipColor: .constant(.clock))
                            .foregroundColor(.clockText)
                            .frame(width: width, height: width*2)
                        
                        FlipView(.constant(hour[1]), flipColor: .constant(.clock))
                            .foregroundColor(.clockText)
                            .frame(width: width, height: width*2)
                        
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))


                    HStack(spacing: -gap ){
                        FlipView(.constant(min[0]), flipColor: .constant(.clock))
                            .foregroundColor(.clockText)
                            .frame(width: width, height: width*2)
                        
                        FlipView(.constant(min[1]), flipColor: .constant(.clock))
                            .foregroundColor(.clockText)
                            .frame(width: width, height: width*2)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))


                    
                    HStack(spacing: -gap ){
                        FlipView(.constant(second[0]), flipColor: .constant(.clock))
                            .foregroundColor(.clockText)
                            .frame(width: width, height: width*2)
                        
                        FlipView(.constant(second[1]), flipColor: .constant(.clock))
                            .foregroundColor(.clockText)
                            .frame(width: width, height: width*2)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))


                }
                .onTapGesture {
                    clockTap()
                }
                .overlay(alignment:.top){
                    VStack{
                        HStack{
                            Text(headTitle)
                            Spacer()
                            Text("\(batteryLevel)% \(batteryImg)")
                                .monospacedDigit()
                        }
                        .foregroundColor(.clockText)
                        .font(.system(.subheadline,design:.rounded))
                    }
                        .padding(.top, -30)
                    
                }
                .overlay(alignment: .bottom){
                    
                    VStack{
                        if isShowProgress{
                            PacmanProgress(progress: $progress,displayType: .mini(pacmanColor: .accentColor,dotColor: .clockText))
                        }

                    }
                    .padding(.bottom, -25)
                    .animation(.easeIn(duration: 0.25),value: isShowProgress)
                    
                   
                }
                
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            
            
        }
        
    }
}
