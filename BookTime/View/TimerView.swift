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
            //            Text(countDownString(from: beginDate))
            HStack(alignment: .center){
                Text( thisMinute.asString().split(separator: ":")[0])
                
                
                Text(":")
                    .baselineOffset(20)
                    .opacity(showColon ? 1 : 0)
                    .animation(.easeInOut, value: showColon)
                Text( thisMinute.asString().split(separator: ":")[1])
                
            }  .font(.custom("DBLCDTempBlack",size: 100))
                .onAppear(perform: {
                    UIApplication.shared.isIdleTimerDisabled = true
                })
                .onDisappear(perform: {
                    UIApplication.shared.isIdleTimerDisabled = true
                })
        }
        
        .onAppear(perform: {
            withAnimation{
                myRed = 0.5
                myGreen = 0.5
                myBlue = 0
            }
            
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
        NavigationView {
            TimerView(book: (BookPersistenceController.testData?.first)! )
                .environment(\.managedObjectContext, BookPersistenceController.preview.container.viewContext)
        }
        
        
    }
}
