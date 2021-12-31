//
//  Tutorial.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/28.
//

import SwiftUI

struct Tutorial: View {
    @Namespace private var animation
    
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("hasViewdWalkthrough") var hasViewdWalkthrough = false
    
    @State private var currentPage = 0
    @State private var imgSize:CGFloat = 2000
    
    var body: some View {
        VStack{
            Spacer()
            
            if(currentPage == 0 ){
                VStack{
                    Image("a_girl_readbook")
                        .resizable()
                        .scaledToFit()
                        .frame(width: imgSize)
                        .matchedGeometryEffect(id: "imageOne", in: animation,anchor: .center)
                    Text("Welcome to BookTime.")
                        .font(.title)
                }.onAppear {
                    withAnimation(.easeInOut(duration: 1.2).delay(0.65)) {
                        imgSize = 300
                    }
                }
            }
            
            if currentPage > 0{
                VStack(spacing:20){
                    HStack {
                        Image("a_girl_readbook")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100)
                            .matchedGeometryEffect(id: "imageOne", in: animation,anchor: .center,isSource: true)
                        
                        VStack {
                            Text("BookTime").font(.largeTitle)
                            Text("Return to reading").font(.subheadline)
                        }
                    }
                    
                    
                    if(currentPage > 0){
                        ExtractedView(index:1, content: String(localized: "Enter the information of the book you are reading into the device.") )
                    }
                    
                    if(currentPage > 1){
                        ExtractedView(index:2,content: String(localized: "Place the device horizontally and start timing."))
                    }
                    
                    if(currentPage > 2){
                        ExtractedView(index:3,content: String(localized: "Get into the habit of punching in every day to achieve results."))
                    }
                    
                    
                    Spacer()
                }
                .padding(30)
                .padding(.top,80)
            }
            
            Spacer()
            
            
            
            
            VStack(spacing:15){
                Button(action: {
                    if currentPage < 3 {
                        withAnimation(.easeInOut(duration:  0.8)){
                            currentPage+=1
                        }
                        
                    }else{
                        hasViewdWalkthrough = true
                        dismiss()
                    }
                }) {
                    Text(currentPage == 3 ? "GET STARTED" : "NEXT")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .padding(.horizontal,50)
                        .background(Color(.systemOrange))
                        .cornerRadius(20)
                }
                
                if currentPage < 3{
                    Button(action:{
                        hasViewdWalkthrough = true
                        dismiss()
                    }){
                        Text("Skip")
                            .font(.headline)
                            .foregroundColor(Color(.darkGray))
                    }
                }
            }
            .padding(.bottom)
            
        }
        .padding(.bottom,30)
        
        
    }
}

struct Tutorial_Previews: PreviewProvider {
    static var previews: some View {
        Tutorial()
    }
}

struct ExtractedView: View {
    var index:Int
    var content :String
    
    @State var show = false
    
    var title:String {
        get{
            switch index{
            case 1:
                return "⓵"
            case 2:
                return "⓶"
            case 3:
                return "⓷"
                
                
            default:
                return "⓵"
            }
            
        }
    }
    
    var body: some View {
        HStack(spacing:8){
            Text(title)
                .font(.system(.largeTitle,design: .rounded))
                .foregroundColor(Color(.systemOrange))
                .rotationEffect(.degrees(show ? 0 : -180) )
                .offset(x:show ? 0: -50)
            
            
            Text(content)
                .frame(width: 240,height: 60,alignment: .leading)
                .font(.system(.callout,design: .rounded))
            
            
        }.onAppear(perform: {
            withAnimation(.easeInOut(duration: 1.0)){
                show = true
            }
        })
    }
}
