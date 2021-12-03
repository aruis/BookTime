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
    
    
    @State var nowDate: Date = Date()
    
    @State private var myRed = 0.2
    @State private var myGreen = 0.2
    @State private var myBlue = 0.2
    
    @State private var thisMinute:Int  = 0
    
    @State private var showColon:Bool = true
    
    var body: some View {
        VStack{
            
            HStack(alignment: .center){
                Text( thisMinute.asString().split(separator: ":")[0])
                
                Text(":")
                    .baselineOffset(14)
                    .opacity(showColon ? 1 : 0)
                //                    .opacity(1)
                    .animation(.easeInOut, value: showColon)
                    .font(.system(size: 60))
                //                    .fixedSize()
                //                    .frame(height:150)
                
                Text( thisMinute.asString().split(separator: ":")[1])
                
            }
            .font(.custom("Courier New",size: 100)            )
            .onAppear(perform: {
                UIApplication.shared.isIdleTimerDisabled = true
            })
            .onDisappear(perform: {
                UIApplication.shared.isIdleTimerDisabled = true
            })
            .scaleEffect(verticalSizeClass == .compact ? 1.8 : 1)
        }
        .onAppear(perform: {
            timerTrack.start(callback: { count in
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
            })
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
