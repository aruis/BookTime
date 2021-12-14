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
    
    
    @State private var totalReadDay = 101
    @State private var totalReadMin = 2300
    @State private var totalReadBook = 78
    @State private var longHit = 10
    
    @State private var sumType = "all"
    
    var  process:CGFloat{
        get{
            return CGFloat( todayReadMin)/CGFloat( targetMinPerdayShadow)
        }
    }
    
    
    var body: some View {
        NavigationView {
            ScrollView{
                VStack (spacing:15){
                    Picker(selection: $sumType, label: Text("DayPiker")) {
                        Text("全部").tag("all")
                        Text("本年").tag("year")
                        Text("本月").tag("month")
                    }.labelsHidden()
                        .pickerStyle(SegmentedPickerStyle())
                    
                    Slogan(title: todayReadMin > 0 ? "今天是您坚持阅读的第":"您已坚持阅读", unit: "天", value: $totalReadDay)
                    
                    ZStack{
                        Circle()
                            .trim(from: 0.0, to:1.0)
                            .stroke(Color("AccentColor"), style: StrokeStyle(lineWidth: 25, lineCap: CGLineCap.round))
                            .frame(width:260)
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
                            .frame(width:260)
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
                    
                    Slogan(title: "累计阅读", unit: "分钟", value: $totalReadMin)
                    Slogan(title: "读完了", unit: "本书", value: $totalReadBook)
                    Slogan(title: "最长连续打卡", unit: "天", value: $longHit)
                    
                    
                    
                }
                .padding()
                .padding(.bottom,30)
                
                .task {
                    todayReadMin = MyTool.checkAndBuildTodayLog(context:context).readMinutes
                    //                todayReadMin = 30
                    if(targetMinPerday > 0){
                        targetMinPerdayShadow = targetMinPerday
                    }else{
                        targetMinPerdayShadow = 45
                    }
                }
            }            
            .navigationTitle("一点微小的成绩")
            .toolbar(content: {
                Button(action: {
    //                bookViewModel.clean()
    //                self.showNewBook = true
                }){
                    Image(systemName: "square.and.arrow.up")
                }
            })
        
            
        }
       
    }
    
    
}

struct Statistics_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{
            Statistics()
        }
        
    }
}


struct Slogan: View {
    var title:String
    var unit:String
    
    @Binding var value:Int
    
    var body: some View {
        HStack(alignment: .firstTextBaseline){
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text(String(value))
                .font(.largeTitle)
                .animation(.default, value: value)
            
            
            Text(unit)
                .font(.subheadline)
                .foregroundColor(.gray)
            
        }
    }
}
