//
//  TimerView.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/1.
//

import SwiftUI

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
    
    @State private var showColon:Bool = true
    @State private var showDate:Bool = false
    @State private var now  = Date()
    
    @State private var isHit:Bool = false
    
    @State private var showToast = false
    
    let generator = UINotificationFeedbackGenerator()
    
    var body: some View {
        VStack{
            
            HStack(alignment: .center){
                
                Text((showDate ? now.format(format: "HH:mm") : thisMinute.asString()).split(separator: ":")[0])
                
                Text(":")
                    .baselineOffset(14)
                    .opacity(showColon ? 1 : 0)
                    .animation(.easeInOut, value: showColon)
                    .font(.system(size: verticalSizeClass == .compact ? 110 : 55))
//                    .foregroundColor(isHit ? .red : nil)
                
                
                Text((showDate ? now.format(format: "HH:mm") : thisMinute.asString()).split(separator: ":")[1])
                
            }

            .foregroundColor(isHit ? Color("AccentColor") : nil)
            .overlay(alignment: .bottom, content: {
                if showDate {
                    Text(now.format(format: "YYYY-MM-dd"))
                        .font(.system(size: verticalSizeClass == .compact ? 40 : 20))
//                        .font(.subheadline,size: (verticalSizeClass == .compact ? 140 : 60))
                        .foregroundColor(.gray)
                }
            })
            .font(.custom("Courier New",size: verticalSizeClass == .compact ? 180 : 90)            )
            .onAppear(perform: {
                UIApplication.shared.isIdleTimerDisabled = true
                DispatchQueue.main.async {
                    Tool.hiddenTabBar()
                }
            })
            .onDisappear(perform: {
                UIApplication.shared.isIdleTimerDisabled = false
                DispatchQueue.main.async {
                    Tool.showTabBar()
                }
                
            })
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()               
                self.showDate.toggle()
            }
            .animation(.linear, value: verticalSizeClass)

        }
        .toast(isPresenting: $showToast,duration: 6,tapToDismiss: true){
            AlertToast( type: .complete(.green), title: String(localized: "Today's goal has been reached"))
        }

        .onAppear(perform: {
            if(targetMinPerday>0 && BookPersistenceController.shared.checkAndBuildTodayLog().readMinutes
            >= targetMinPerday
            ){
//                generator.notificationOccurred(.success)
                isHit = true
            }
            
            timerTrack.start { count in
                now = Date()
                self.showColon.toggle()
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
