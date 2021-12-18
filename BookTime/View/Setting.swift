//
//  Setting.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/4.
//

import SwiftUI

struct Setting: View {
    @Environment(\.managedObjectContext) var context
    
    let store = NSUbiquitousKeyValueStore()
    
    @AppStorage("targetMinPerday") var targetMinPerday = 45
    @AppStorage("useiCloud") var useiCloud = false
    
    @FetchRequest(entity: Book.entity(), sortDescriptors:[])
    var books: FetchedResults<Book>
    
    @FetchRequest(entity: ReadLog.entity(), sortDescriptors:[])
    var logs: FetchedResults<ReadLog>
    
    @State var showAbout = false
    @State var sliderIsChange = false
    @State var lastBackupTime:String? = nil

    @State var showCleanSheet = false
    @State var showCleanDataSucToast = false
    
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
            store.set(Int64( targetMinPerday), forKey: "targetMinPerday")
        })
    }
    
    var body: some View {
        NavigationView {
            
            VStack {
                VStack(){
                    Text(targetMinPerday.asString())
                        .font(.system(size: 100)).fontWeight(.light).monospacedDigit()
                    
                    Text(greeting)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .opacity(sliderIsChange ? 0 : 1)
                    
                    
                }
                .frame(height:170,alignment: .top)
                .animation(.default, value: targetMinPerday)
                
                Form {
                    
                    Section(header: Text("每日阅读目标")) {
                        Slider(value: intProxy, in: 0...360, step: 5,onEditingChanged: { editing in
                            self.sliderIsChange = editing
                        })
                    }
                    
                    Section(header: Text("以下操作请谨慎")){
                        Button(action: {
                            showCleanSheet = true
                        }){
                            Text("\(Image(systemName: "exclamationmark.triangle.fill")) 清除所有数据")
                        }
                    }
                    
                }
                .toast(isPresenting: $showCleanDataSucToast,duration: 3,tapToDismiss: true){
                    AlertToast( type: .complete(.green), title: "数据已清空")
                }
                .confirmationDialog("数据无价，请谨慎选择！", isPresented: $showCleanSheet, titleVisibility : .visible, actions: {
                    Button("我要清除所有数据", role: .destructive) {
                            cleanLocal()
                    }
                
                    Button("取消", role: .cancel) {
                        self.showCleanSheet = false
    //                    useiCloud = false
                    }
                })
                .onAppear(perform: {
                   UIScrollView.appearance().bounces = false
                 })
                .navigationTitle("设置")
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
        .task {
            let minute = store.longLong(forKey: "targetMinPerday")
            if(minute>0){
                targetMinPerday = Int(minute)
            }
            
            
        }
        
        
    }
       
    func cleanLocal(){
        for book in books {
            context.delete(book)
        }
        
        for log in logs{
            context.delete(log)
        }
        targetMinPerday = 45
        store.removeObject(forKey: "targetMinPerday")
        
        DispatchQueue.main.async {
            do{
                try context.save()
                showCleanDataSucToast = true
            }catch{
                print(error)
            }
        }
    }
}

struct Setting_Previews: PreviewProvider {
    static var previews: some View {
        Setting()
    }
}
