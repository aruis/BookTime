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
    
    var body: some View {
        VStack{
            
            HStack(alignment: .center){
                Text((showDate ? now.format(format: "HH:mm") : thisMinute.asString()).split(separator: ":")[0])
                
                Text(":")
                    .baselineOffset(14)
                    .opacity(showColon ? 1 : 0)
                    .animation(.easeInOut, value: showColon)
                    .font(.system(size: 60))
                
                
                Text((showDate ? now.format(format: "HH:mm") : thisMinute.asString()).split(separator: ":")[1])
                
            }
            .font(.custom("Courier New",size:  100)            )
            .onAppear(perform: {
                UIApplication.shared.isIdleTimerDisabled = true
                DispatchQueue.main.async {
                    Tool.hiddenTabBar()
                }
                
                //TODO 检查有无今天的数据
                
            })
            .onDisappear(perform: {
                UIApplication.shared.isIdleTimerDisabled = true
                DispatchQueue.main.async {
                    Tool.showTabBar()
                }
                
            })
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()               
                self.showDate.toggle()
            }
            .scaleEffect(verticalSizeClass == .compact ? 2.2 : 1)
        }
        .onAppear(perform: {
            timerTrack.start { count in
                now = Date()
                self.showColon.toggle()
                let min = count / 60
                if thisMinute != min{
                    thisMinute = min
                    book.readMinutes += 1
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
            print("close")
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
