//
//  TimerView.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/1.
//

import SwiftUI
import LocalAuthentication
//import Foundation

struct TimerView: View {
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @AppStorage("targetMinPerday") var targetMinPerday = 45
    
    @ObservedObject var book: Book
    @ObservedObject private var timerTrack:TimerTrack = TimerTrack.shared
    
    @State var uiTabarController: UITabBarController?
    @State var nowDate: Date = Date()
    
    @State private var myRed = 0.2
    @State private var myGreen = 0.2
    @State private var myBlue = 0.2
    
    @State private var thisMinute:Int  = 0
    
    @State private var now  = Date()
    
    private let begin = Date()
    
    @State private var changeTabAuto = false
    @State private var lastShowTab:ShowTimeType? = nil
    
    @State private var isHit:Bool = false
    
    @State private var showToast = false
    
    let generator = UINotificationFeedbackGenerator()
    
    enum ShowTimeType : String,CaseIterable{
        case timer
        case time
        case today
    }
    
    @State private var tabSelected = ShowTimeType.timer
    
    var body: some View {
        //        VStack{
        
        TabView(selection: $tabSelected){
            TimelineView(.periodic(from: begin, by: 1)) { context in
                let date = context.date
                let components = Calendar.current.dateComponents([.hour,.minute,.second], from: begin, to: date)
                let thisMinute = Int( BookPersistenceController.shared.checkAndBuildTodayLog().readMinutes)
                //                let dataArr  = context.date.format(format: "HH:mm:ss").split(separator: ":")
                //                let h = "\(components.hour!)".count == 1 ? "0\(components.hour!)" : "\(components.hour!)"
                //                let m = "\(components.minute!)".count == 1 ? "0\(components.minute!)" : "\(components.minute!)"
                let s = "\(components.second!)".count == 1 ? "0\(components.second!)" : "\(components.second!)"
                let hour = String( thisMinute.asString().split(separator: ":")[0])
                let min = String( thisMinute.asString().split(separator: ":")[1])
                
                let process = targetMinPerday > 0 ? CGFloat( thisMinute)/CGFloat( targetMinPerday) : CGFloat( thisMinute)/CGFloat( 45)
                let batteryLevel = Int(round(UIDevice.current.batteryLevel * 100))
                
                ClockView(hour: hour, min: min, second: s ,headTitle:  targetMinPerday > 0 ? String(localized: "\( Int( round( process * 100))) %  of the plan completed") : "",batteryLevel: batteryLevel,inCharging: UIDevice.current.batteryState == .charging)
                
            }
            .tag(ShowTimeType.today)
            
            
            TimelineView(.periodic(from: begin, by: 1)) { context in
                let date = context.date
                let components = Calendar.current.dateComponents([.hour,.minute,.second], from: begin, to: date)
                
                //                let dataArr  = context.date.format(format: "HH:mm:ss").split(separator: ":")
                //                let h = "\(components.hour!)".count == 1 ? "0\(components.hour!)" : "\(components.hour!)"
                //                let m = "\(components.minute!)".count == 1 ? "0\(components.minute!)" : "\(components.minute!)"
                let s = "\(components.second!)".count == 1 ? "0\(components.second!)" : "\(components.second!)"
                let hour = String( thisMinute.asString().split(separator: ":")[0])
                let min = String( thisMinute.asString().split(separator: ":")[1])
                let batteryLevel = Int(round(UIDevice.current.batteryLevel * 100))
                ClockView(hour: hour, min: min, second: s,batteryLevel: batteryLevel,inCharging: UIDevice.current.batteryState == .charging)
                
            }
            .tag(ShowTimeType.timer)
            
            
            
            TimelineView(.periodic(from: Date(), by: 1)) { context in
                let date = context.date
                let dataArr  = date.format(format: "HH:mm:ss").split(separator: ":")
                let h = String(dataArr[0])
                let m = String(dataArr[1])
                let s = String(dataArr[2])
                let batteryLevel = Int(round(UIDevice.current.batteryLevel * 100))
                
                ClockView(hour: h, min: m, second: s,headTitle: date.dayString(),batteryLevel: batteryLevel,inCharging: UIDevice.current.batteryState == .charging)
                
                
                
            }
            .tag(ShowTimeType.time)
            
        }
        .onChange(of: tabSelected, perform: { _ in
            changeTabAuto = false
        })
        .animation(.easeInOut, value: tabSelected)
        .onTapGesture {
            //            if tabSelected == .timer {
            //                tabSelected = .time
            //            }else{
            //                tabSelected = .timer
            //            }
        }
        .padding(.bottom,20)
        .ignoresSafeArea()
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .foregroundColor(isHit ? Color("AccentColor") : .white)
        .background(.black)
        //        .font(.custom("Courier New",size: verticalSizeClass == .compact ? 180 : 90)            )
        .onAppear(perform: {
            DispatchQueue.main.async {
                Tool.hiddenTabBar()
            }
            UIApplication.shared.isIdleTimerDisabled = true
            UIDevice.current.isBatteryMonitoringEnabled = true
            
//            Tool.hiddenTabBar()
//            DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
//                Tool.hiddenTabBar()
//            })
            DispatchQueue.main.asyncAfter(deadline: .now()+0.6, execute: {
                tabSelected = .time
            })
            DispatchQueue.main.asyncAfter(deadline: .now()+2.6, execute: {
                tabSelected = .timer
            })
        })
        .onDisappear(perform: {
            DispatchQueue.main.async {
                Tool.showTabBar()
            }
            
            UIApplication.shared.isIdleTimerDisabled = false
            UIDevice.current.isBatteryMonitoringEnabled = false
          
//            Tool.showTabBar()

            
        })
        .animation(.linear, value: verticalSizeClass)
        
        //        }
        .toast(isPresenting: $showToast,duration: 6,tapToDismiss: true){
            AlertToast( type: .complete(.green), title: String(localized: "Today's goal has been reached"))
        }
        
        .onAppear(perform: {
            if(targetMinPerday>0 && BookPersistenceController.shared.checkAndBuildTodayLog().readMinutes
               >= targetMinPerday
            ){
                isHit = true
            }
            
            timerTrack.start { count in
                now = Date()
                let nowStr = now.format(format: "mm:ss")
                if (nowStr == "30:00" || nowStr == "00:00" ) && tabSelected != .time {
                    lastShowTab = tabSelected
                    tabSelected  = .time
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {
                        changeTabAuto = true
                    })
                }
                
                if (nowStr == "31:00" || nowStr == "01:00" ) && changeTabAuto {
                    if let lastShowTab = lastShowTab {
                        tabSelected = lastShowTab
                    }
                    changeTabAuto = false
                }
                
                let min = count / 60
                
                if thisMinute != min{
                    
                    let readLog = BookPersistenceController.shared.checkAndBuildTodayLog()
                    
                    thisMinute = min
                    if book.readMinutes == 0 { //第一次读
                        book.firstReadTime = now
                    }
                    book.readMinutes += 1
                    if let lastReadTime = book.lastReadTime {
                        if(lastReadTime.format(format: "YYYY-MM-dd") != now.format(format: "YYYY-MM-dd")){
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
                    
                    
                    DispatchQueue.main.async {
                        do{
                            try context.save()
                        }catch{
                            print(error)
                        }
                    }
                }
            }
        })
        .onDisappear(perform: {
            timerTrack.stop()
        })
        
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        //        NavigationView {
        TimerView(book: (BookPersistenceController.testData?.first)! )
            .environment(\.managedObjectContext, BookPersistenceController.preview.container.viewContext)
            .previewInterfaceOrientation(.portrait)
        //        }
        
        
    }
}

extension UIView {
    
    func allSubviews() -> [UIView] {
        var res = self.subviews
        for subview in self.subviews {
            let riz = subview.allSubviews()
            res.append(contentsOf: riz)
        }
        return res
    }
}

struct Tool {
    static func showTabBar() {
        //           UIWindowScene
        UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }?
            .allSubviews().forEach({ (v) in
                if let view = v as? UITabBar {
                    view.isHidden = false
                }
            })
    }
    
    static func hiddenTabBar() {
        UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }?
        
            .allSubviews().forEach({ (v) in
                if let view = v as? UITabBar {
                    view.isHidden = true
                }
            })
    }
}

struct ShowTabBar: ViewModifier {
    func body(content: Content) -> some View {
        return content.padding(.zero).onAppear {
            Tool.showTabBar()
        }
    }
}
struct HiddenTabBar: ViewModifier {
    func body(content: Content) -> some View {
        return content.padding(.zero).onAppear {
            Tool.hiddenTabBar()
        }
    }
}

extension View {
    func showTabBar() -> some View {
        return self.modifier(ShowTabBar())
    }
    func hiddenTabBar() -> some View {
        return self.modifier(HiddenTabBar())
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
                    .font(.system(  verticalSizeClass == .compact ? .title2 : .title3 ,design:.rounded))
                    .frame(width: 200)
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
            }
            .padding(.bottom,-100)
            ,alignment: .bottom
        )
        
        .animation(.easeInOut, value: timerShowSec)
        .font(.system(size: verticalSizeClass == .compact ? 100: 55,design: .serif))
        .padding(.bottom,20)
        .onTapGesture {
            timerShowSec.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        
    }
}
