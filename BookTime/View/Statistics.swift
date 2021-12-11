//
//  Statistics.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/3.
//

import SwiftUI

struct Statistics: View {
    @AppStorage("targetMinPerday") var targetMinPerday = 45
    @Environment(\.managedObjectContext) var context
    
    @State private var orangeCircleProgress:CGFloat = 0.9
    @State private var greenCircleProgress:CGFloat = 0.3
    
    @State private var todayReadMin = 0
    
//    private let tool = MyTool()
    
    private var percentage:Int {
        get {
            return Int(orangeCircleProgress * 100.0)
        }
    }
    
    
    var body: some View {
        VStack {
            Text("今日您已阅读 \(todayReadMin) 分")
            Text("Circle Shape")
                .font(.largeTitle)
            Text("Trim function")
                .foregroundColor(.gray)
            
            ZStack {
                Circle()
                    .trim(from: 0.0, to: orangeCircleProgress)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 40, lineCap: CGLineCap.round))
                    .frame(width:300)
                    .rotationEffect(.degrees(-90))
                    .overlay(
                        Text("\(percentage)%")
                    )
                
                Circle()
                    .trim(from: 0.0, to: greenCircleProgress)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 40, lineCap: CGLineCap.round))
                    .frame(width:170)
                    .rotationEffect(.degrees(-90))
                    .overlay(
                        Text("\(percentage)%")
                    )
            }
            .padding()
            Text("Completed Circle")
            Slider(value: $orangeCircleProgress)
                .padding(.horizontal)
                .accentColor(.orange)
            
            Slider(value: $greenCircleProgress)
                .padding(.horizontal)
                .accentColor(.green)
            
        }.font(.title)
            .padding()
            .onAppear(perform: {
                todayReadMin = MyTool.checkAndBuildTodayLog(context:context).readMinutes
            })
    }
    
    
}

struct Statistics_Previews: PreviewProvider {
    static var previews: some View {
        Statistics()
    }
}

