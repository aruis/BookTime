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
    
    @State var nowDate: Date = Date()
    
    
    private let beginDate: Date  = Date()
    
    var timer: Timer {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {_ in
            self.nowDate = Date()
        }
    }
    
    var saveTimer:Timer{
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) {_ in
            book.readMinutes += 1
            print("plus min \(Date())")
            DispatchQueue.main.async {
                do{
                    try context.save()
                }catch{
                    print(error)
                }
            }
        }
    }
    
    var body: some View {
        VStack{
            Text(countDownString(from: beginDate))
                .font(.largeTitle)
            Button(action: {
                self.timer.invalidate()
                self.saveTimer.invalidate()
                dismiss()
            }){
                Text("结束")
            }

        }
        
        .onAppear(perform: {
            
//            _ = self.timer
//            _ = self.saveTimer
            
            print("begin \(beginDate)")
        })
        .onDisappear(perform: {
            print("close")
            self.timer.invalidate()
            self.saveTimer.invalidate()
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
