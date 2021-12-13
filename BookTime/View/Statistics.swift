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
    
    @State private var targetMinPerdayShadow = 45
    @State private var todayReadMin = 0
    
    //    private let gradient =
    
    var  process:CGFloat{
        get{
            return CGFloat( todayReadMin)/CGFloat( targetMinPerdayShadow)
        }
    }
    
    
    var body: some View {
        ScrollView{
            VStack (spacing:15){
               
                HStack(alignment: .firstTextBaseline){
                    Text("今天是您坚持阅读的第")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("100")
                        .font(.largeTitle)
                    
                    
                    Text("天")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                }
                
                
                
                ZStack{
                    Circle()
                        .trim(from: 0.0, to:1.0)
                        .stroke(Color("AccentColor"), style: StrokeStyle(lineWidth: 25, lineCap: CGLineCap.round))
                        .frame(width:300)
                        .rotationEffect(.degrees(-90))
                        .opacity(0.25)
                    //                        .opacity(0)
                        .padding()
                    
                    Circle()
                        .trim(from: 0.0, to: process)
                    //                        .trim(from: 0.0,to:  1.0)
                        .stroke( AngularGradient(
                            gradient: Gradient(colors: [Color("AccentColor").opacity(0.6), Color("AccentColor")]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees( 360 * process )
                        ), style: StrokeStyle(lineWidth: 25, lineCap: CGLineCap.round))
                        .frame(width:300)
                        .rotationEffect(.degrees(-90))
                        .overlay(
                            VStack(spacing:6){
                                Text("今日您已阅读 \(todayReadMin) 分")
                                    .font(.title2)
                                if targetMinPerday > 0{
                                    Text("完成计划的 \( Int( round( process * 100))) %")
                                        .foregroundColor(.gray)
                                }
                                
                            }
                            
                        )
                        .padding()
                        .animation(.linear, value: todayReadMin)
                    
                    
                }.frame(width: 300,height: 300)
                
                HStack(alignment: .firstTextBaseline){
                    Text("累计阅读")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("100")
                        .font(.largeTitle)
                    
                    
                    Text("分钟")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                }
                
                HStack(alignment: .firstTextBaseline){
                    Text("读完了")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("30")
                        .font(.largeTitle)
                    
                    
                    Text("本书")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                }
                
                
                HStack(alignment: .firstTextBaseline){
                    Text("最长连续打卡")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("30")
                        .font(.largeTitle)
                    
                    
                    Text("天")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                }
                
           
            }
            .padding()
            .onAppear(perform: {
                todayReadMin = MyTool.checkAndBuildTodayLog(context:context).readMinutes
                //                todayReadMin = 30
                if(targetMinPerday > 0){
                    targetMinPerdayShadow = targetMinPerday
                }else{
                    targetMinPerdayShadow = 45
                }
                
            })
        }
    }
    
    
}

struct Statistics_Previews: PreviewProvider {
    static var previews: some View {
        Statistics()
    }
}

