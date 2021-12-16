//
//  Setting.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/4.
//

import SwiftUI

struct Setting: View {
    
    @AppStorage("targetMinPerday") var targetMinPerday = 45
    @State var showAbout = false
    @State var sliderIsChange = false
    
    private var greeting:String{
        get {
            let value = targetMinPerday
            if(value > 240){
                return "书籍是人类进步的阶梯，\n但阶梯不是目的，两侧的风景才是。"
            }
            if(value > 180){
                return "为革命，保护视力，眼保健操，请自行脑补。"
            }
            if(value > 120){
                return "自古英雄惜英雄，请收下作者的膝盖。"
            }
            if(value > 90){
                return "道之所在，虽千万人吾往矣。"
            }
            if(value > 60){
                return "路漫漫其修远兮，吾将上下而求索。 "
            }
            if(value > 45){
                return "真的猛士，敢于直面惨淡的人生，敢于正视淋漓的鲜血。"
            }
            if(value > 30){
                return "您已经打败了全国99%的非用户。"
            }
            if(value > 15){
                return "不积跬步，无以至千里。"
            }
            if(value > 1){
                return "好的开始=成功*1/2，好的目标=好的开始*1/2。"
            }
            if(value == 0){
                return "菩提本无树，明镜亦非台。"
            }
            return ""
        }
    }
    
    
    var intProxy: Binding<Double>{
        Binding<Double>(get: {
            return Double(targetMinPerday)
        }, set: {
            targetMinPerday = Int($0)
        })
    }
    
    var body: some View {
        NavigationView {
            VStack{
                VStack(){
                    Text("每日阅读目标")
                        .font(.title2)
                    Text(targetMinPerday.asString())
                        .font(.system(size: 100)).monospacedDigit()
                    
                    Text(greeting)
                        .font(.subheadline)
                        
                        .multilineTextAlignment(.center)
                        .opacity(sliderIsChange ? 0 : 1)
                    
                    Spacer()
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .frame(minHeight:0,maxHeight: 220)
                .animation(.default, value: targetMinPerday)
                
                
                Slider(value: intProxy, in: 0...360, step: 5,onEditingChanged: { editing in
                    self.sliderIsChange = editing
                })
                    .padding(.top,60)
                    .padding([.trailing,.leading],50)
            }
            .padding()
            .toolbar{
                Button(action: {
                    self.showAbout = true
                }){
                    Image(systemName: "lightbulb")
                }
                
            }
            .sheet(isPresented: $showAbout){
                About()
            }

        }
        
        
    }
    
}

struct Setting_Previews: PreviewProvider {
    static var previews: some View {
        Setting()
    }
}
