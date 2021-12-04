//
//  BookCard.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/1.
//

import SwiftUI
//import ConfettiSwiftUI

struct BookCard: View {
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @ObservedObject var book: Book
    
    @State private var showTimer:Bool = false
    @State private var showAlert:Bool = false
    @State var downTrigger:Int = 0
    
    var body: some View {
        
        if verticalSizeClass == .compact || showTimer{
            VStack(alignment: .center,spacing: 200){
                TimerView(book: book)
                    .padding(.bottom, verticalSizeClass == .compact ? 50 : 0)
                
                if self.showTimer && verticalSizeClass != .compact{
                    Button(action: {
                        self.showTimer = false
                    }){
                        Text("结束阅读")
                    }
                }
                
                
            }
            .navigationBarBackButtonHidden(true)
            
        } else{
            ScrollView {
                VStack(alignment: .center,spacing: 10){
                    Text(book.name).font(.system(.title2))
                    
                    Image(uiImage: UIImage(data: book.image)!)
                        .resizable()
                        .scaledToFit()
                        .frame(minWidth: 0,maxWidth: 150)
                        .padding()
                        .shadow(color: Color( "image.border"), radius: 8,x:10,y:10)
                        .onTapGesture {
                            self.showTimer = true
                        }
                    
                    
                    HStack(spacing:10){
                        ForEach(0...4,id: \.self) {index in
                            Image(systemName: book.rating > index ? "star.fill" : "star")
                                .font(.title2)
                                .onTapGesture {
                                    if book.rating == 1 && index == 0 {
                                        book.rating = 0
                                    }else{
                                        book.rating = Int16(index+1)
                                    }
                                    save()
                                }
                                .onTapGesture (count: 2){
                                    book.rating = 0
                                    save()
                                }
                        }
                    }.opacity(book.isDone ? 1 : 0)
                        .animation(.default, value: book.isDone)
                    
                    
                    Text("您已阅读:").font(.system(.title2))
                    Text(book.readMinutes.asString()).font(.system(.largeTitle))
                    
                    ZStack{
                        RoundedRectangle(cornerRadius: book.isDone ? 25:5)
                            .frame(width: book.isDone ? 50:250, height: 50)
                            .foregroundColor(book.isDone ? .green : .gray)
                            .overlay(
                                //                                Text("")
                                Image(systemName: "checkmark")
                                    .font(.system(.title))
                                    .foregroundColor(.white)
                                    .scaleEffect(book.isDone ? 1: 0.7)
                                    .opacity(book.isDone ? 1 : 0)
                            )
                        //                            .frame(width: 12, height: 12)
                        //                                           .modifier(ParticlesModifier())
                        //                                           .offset(x: -100, y : -50)
                        
                        
                        Text("我已读完")
                            .opacity(book.isDone ? 0 : 1)
                            .fixedSize()
                        
                            .foregroundColor(.white)
                    }
                    .onTapGesture {
                        book.isDone.toggle()
                        if(book.isDone){ downTrigger+=1}
                        save()
                    }
                    .animation(.easeInOut, value: book.isDone)
                    
                    ConfettiCannon(counter: $downTrigger,num:36,radius: 500)
                }
                
                //            .padding(.top,-50)
                .padding(10)
                
                
                
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.showAlert = true
                    }){
                        Image(systemName: "ellipsis")
                    }
                    .confirmationDialog("", isPresented: $showAlert, actions: {
                        Button("删除此书（不可恢复）", role: .destructive) {
                            delete()
                            dismiss()
                        }
                        Button("取消", role: .cancel) {
                            self.showAlert = false
                        }
                    })
                }
            }
            
            
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
//            .navigationBarBackButtonHidden(true)
            
        }
        
    }
    
    func save(){
        DispatchQueue.main.async {
            do{
                try context.save()
            }catch{
                print(error)
            }
        }
    }
    
    func delete(){
        context.delete(book)
        save()
    }
    
}

struct BookCard_Previews: PreviewProvider {
    static var previews: some View {
        //        BookCard()
        NavigationView {
            BookCard(book: (BookPersistenceController.testData?.first)!)
                .environment(\.managedObjectContext, BookPersistenceController.preview.container.viewContext)
        }
        
        NavigationView {
            BookCard(book: (BookPersistenceController.testData?.first)!)
                .environment(\.managedObjectContext, BookPersistenceController.preview.container.viewContext)
                .previewInterfaceOrientation(.landscapeLeft)
        }
        //        .environment(\.dynamicTypeSize, .small)
        //        .accentColor(.white)
    }
}

struct ParticlesModifier: ViewModifier {
    @State var time = 0.0
    @State var scale = 0.1
    let duration = 5.0
    
    func body(content: Content) -> some View {
        ZStack {
            ForEach(0..<80, id: \.self) { index in
                content
                    .hueRotation(Angle(degrees: time * 80))
                    .scaleEffect(scale)
                    .modifier(FireworkParticlesGeometryEffect(time: time))
                    .opacity(((duration-time) / duration))
            }
        }
        .onAppear {
            withAnimation (.easeOut(duration: duration)) {
                self.time = duration
                self.scale = 1.0
            }
        }
    }
}

struct FireworkParticlesGeometryEffect : GeometryEffect {
    var time : Double
    var speed = Double.random(in: 20 ... 200)
    var direction = Double.random(in: -Double.pi ...  Double.pi)
    var animatableData: Double {
        get { time }
        set { time = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        let xTranslation = speed * cos(direction) * time
        let yTranslation = speed * sin(direction) * time
        let affineTranslation =  CGAffineTransform(translationX: xTranslation, y: yTranslation)
        return ProjectionTransform(affineTranslation)
    }
}
