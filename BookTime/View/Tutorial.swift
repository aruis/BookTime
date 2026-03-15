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
    
    private var progressValue: Double {
        Double(currentPage + 1) / 4.0
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemOrange).opacity(0.10),
                    Color.accentColor.opacity(0.08),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0){
                Spacer()
                
                if(currentPage == 0 ){
                    VStack(spacing: 18){
                        Image("a_girl_readbook")
                            .resizable()
                            .scaledToFit()
                            .frame(width: imgSize)
                            .shadow(color: Color.black.opacity(0.08), radius: 24, y: 12)
                            .matchedGeometryEffect(id: "imageOne", in: animation, properties: .frame, anchor: .center, isSource: true)
                            .zIndex(1)
                        VStack(spacing: 8) {
                            Text("Welcome to BookTime.")
                                .font(.system(.title, design: .rounded).weight(.bold))
                            Text("Track your reading time")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 24)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.2).delay(0.65)) {
                            imgSize = 300
                        }
                    }
                }
                
                if currentPage > 0{
                    VStack(spacing:24){
                        HStack(spacing: 16) {
                            Image("a_girl_readbook")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 92)
                                .shadow(color: Color.black.opacity(0.08), radius: 14, y: 8)
                                .matchedGeometryEffect(id: "imageOne", in: animation, properties: .frame, anchor: .center, isSource: false)
                                .zIndex(1)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("BookTime")
                                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                                Text("Track your reading time")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 4)
                        
                        VStack(alignment: .leading, spacing: 14) {
                            if(currentPage > 0){
                                TutorialPage(index:1, content: String(localized: "Enter the information of the book you are reading into the device.") )
                            }
                            
                            if(currentPage > 1){
                                if UIDevice.current.userInterfaceIdiom == .phone {
                                    TutorialPage(index:2,content: String(localized: "Place the device horizontally and start timing."))
                                }else{
                                    TutorialPage(index:2,content: String(localized: "Turn on the timer mode while reading the paper book, or use the split screen mode to time the e-book reading."))
                                }
                                
                            }
                            
                            if(currentPage > 2){
                                TutorialPage(index:3,content: String(localized: "Get into the habit of punching in every day to achieve results."))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(22)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.55), lineWidth: 1)
                        )
                        
                        Spacer()
                    }
                    .padding(30)
                    .padding(.top,80)
                }
                
                Spacer()
                
                VStack(spacing:18){
                    ProgressView(value: progressValue)
                        .tint(.accentColor)
                        .padding(.horizontal, 42)
                    
                    HStack(spacing: 8) {
                        ForEach(0..<4, id: \.self) { index in
                            Capsule(style: .continuous)
                                .fill(index <= currentPage ? Color.accentColor : Color.secondary.opacity(0.18))
                                .frame(width: index == currentPage ? 26 : 8, height: 8)
                                .animation(.easeInOut(duration: 0.25), value: currentPage)
                        }
                    }
                    
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
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color(.systemOrange), Color.accentColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: Color(.systemOrange).opacity(0.22), radius: 18, y: 10)
                        }
                        
                        if currentPage < 3{
                            Button(action:{
                                hasViewdWalkthrough = true
                                dismiss()
                            }){
                                Text("Skip")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.bottom, 18)
            }
        }
        .padding(.bottom,30)
    }
}

struct Tutorial_Previews: PreviewProvider {
    static var previews: some View {
        Tutorial()
    }
}

struct TutorialPage: View {
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
        HStack(spacing:12){
            Text(title)
                .font(.system(.title2,design: .rounded).weight(.bold))
                .foregroundColor(Color(.systemOrange))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color(.systemOrange).opacity(0.14))
                )
                .rotationEffect(.degrees(show ? 0 : -180) )
                .offset(x:show ? 0: -50)
            
            Text(content)
                .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                .font(.system(.callout,design: .rounded))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
        .onAppear(perform: {
            withAnimation(.easeInOut(duration: 1.0)){
                show = true
            }
        })
    }
}
