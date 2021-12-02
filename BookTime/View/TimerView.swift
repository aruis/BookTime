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
    @ObservedObject var timerTrack:TimerTrack = TimerTrack.shared
    
    @State var nowDate: Date = Date()
    
    
    private let beginDate: Date  = Date()
    
    
    var body: some View {
        VStack{
//            Text(countDownString(from: beginDate))
            Text(String( timerTrack.count))
                .font(.largeTitle)
            Button(action: {
             
                dismiss()
            }){
                Text("结束")
            }

        }
        
        .onAppear(perform: {
            timerTrack.start()
            print("begin \(beginDate)")
        })
        .onDisappear(perform: {
            timerTrack.stop()
            print("close")
        })
        
    }
    
    func countDownString(from date: Date) -> String {
        let calendar = Calendar(identifier: .chinese)
        let components = calendar
            .dateComponents([.day, .hour, .minute, .second],
                            from: beginDate,
                            to: nowDate)
        return String(format: "%02dd:%02dh:%02dm:%02ds",
                      components.day ?? 00,
                      components.hour ?? 00,
                      components.minute ?? 00,
                      components.second ?? 00)
    }}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TimerView(book: (BookPersistenceController.testData?.first)!)
                .environment(\.managedObjectContext, BookPersistenceController.preview.container.viewContext)
        }
        
        
    }
}
