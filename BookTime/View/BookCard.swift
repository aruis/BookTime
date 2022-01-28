//
//  BookCard.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/1.
//

import SwiftUI

struct BookCard: View {
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @AppStorage("isFirstBookCard") var isFirstBookCard = true
    
    @ObservedObject var book: Book
    
    @State private var showTimer:Bool = false
    @State private var showAlert:Bool = false
    @State private var showBatterySheet:Bool = false
    @State private var showToast = false
    @State private var showOptions = false
    
    
    @State var downTrigger:Int = 0
    @State var isDone = false
    
    @State var hPhone = true
    
    @State private var shareImage:UIImage? = nil
    
    let generator = UINotificationFeedbackGenerator()
    
    @ViewBuilder
    var mainView:some View{
        VStack(alignment: .center,spacing: 16){
            Text(String(localized: "《") + book.name + String(localized: "》")).font(.system(.title2))
            
            Image(uiImage: UIImage(data: book.image) ?? UIImage())
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
                        .foregroundColor(Color("AccentColor"))
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            
                            if book.rating == 1 && index == 0 {
                                book.rating = 0
                            }else{
                                book.rating = Int16(index+1)
                            }
                            save()
                        }
                    
                }
            }.opacity(isDone ? 1 : 0)
                .animation(.default, value: isDone)
            
            if book.readMinutes > 0{
                VStack{
                    Slogan(title: String(localized: "Reading for",comment: "fredingForDay"), unit: String(localized: "day"), value: String( book.readDays))
                    Slogan(title:  String(localized: "Reading for",comment: "fredingForMin"), unit: String(localized: "min"), value: String( book.readMinutes))
                }
            }
                        
            
            
        }
    }
    
    var body: some View {
        ZStack{
            if (UIDevice.current.userInterfaceIdiom == .phone && verticalSizeClass == .compact) || showTimer{
                ZStack{
                    TimerView(book: book)
                    
                    if self.showTimer && verticalSizeClass != .compact{
                        VStack{
                            Spacer()
                            Button(action: {
                                self.showTimer = false
                            }){
                                Text("End reading")
                            }
                        }
                        .padding(.bottom,100)
                        
                    }
                }
                .navigationBarBackButtonHidden(true)
                .onAppear(perform: {
                    generator.notificationOccurred(.success)
                })
            } else{
                ScrollView {
                    VStack(alignment: .center,spacing: 16){
                        
                        mainView
                        
                        ZStack{
                            RoundedRectangle(cornerRadius: isDone ? 25:5)
                                .frame(width: isDone ? 50:250, height: 50)
                                .foregroundColor(isDone ? .green : .gray)
                                .overlay(
                                    //                                Text("")
                                    Image(systemName: "checkmark")
                                        .font(.system(.title))
                                        .foregroundColor(.white)
                                        .scaleEffect(isDone ? 1: 0.7)
                                        .opacity(isDone ? 1 : 0)
                                )
                            
                            
                            Text("Finished Reading")
                                .opacity(isDone ? 0 : 1)
                                .fixedSize()
                            
                                .foregroundColor(.white)
                        }
                        .frame(minWidth: 0,maxWidth: .infinity)
                        .frame(height:80)
                        .onTapGesture {
                            isDone.toggle()
                            if(isDone){
                                generator.notificationOccurred(.success)
                                downTrigger+=1
                                book.doneTime = Date()
                            }
                        }
                        .animation(.easeInOut, value: isDone)

                        
                        if isFirstBookCard {
                            Label(title: {
                                HStack{
                                    if UIDevice.current.userInterfaceIdiom == .phone {
                                        Text("Please place the device horizontally and start timing")
                                    }else{
                                        Text("Tab the book cover and start timing")
                                    }
                                    
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        isFirstBookCard = false
                                    }, label: {
                                        Text("[Don't show again.]")
                                    })
                                }
                                
                            }, icon: {
                                if UIDevice.current.userInterfaceIdiom == .phone {
                                    Image(systemName: "iphone.landscape")
                                        .rotationEffect(.degrees(hPhone ? 90:0))
                                }
                            })
                                .font(.subheadline)
                                .onAppear(perform: {
                                    withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false) ){
                                        hPhone.toggle()
                                    }
                                })
                            
                        }
                        
                        
                    }
                    .padding(10)
                    .toolbar(content: {
                        if(isDone){
                            Button(action: {
                                shareImage = exportBox.snapshot()
                                showOptions = true
                            }){
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                        
                    })
                    .sheet(isPresented: $showOptions) {
                        if let image = shareImage {
                            ActivityView(activityItems: [image])
                        }
                    }
                    .toast(isPresenting: $showToast,duration: 3,tapToDismiss: true){
                        AlertToast( type: .complete(.green), title: String(localized: "Saved to album",comment: "导出成功\n去相册看看吧"))
                    }
                    
                    
                    
                    ConfettiCannon(counter: $downTrigger,num:36,radius: 700)
                    
                }
                //                .toolbar {
                //                    ToolbarItem(placement: .navigationBarTrailing) {
                //                        Button(action: {
                //                            self.showAlert = true
                //                            generator.notificationOccurred(.warning)
                //                        }){
                //                            Image(systemName: "ellipsis")
                //                        }
                //                        .confirmationDialog("", isPresented: $showAlert, actions: {
                //                            Button("删除此书（不可恢复）", role: .destructive) {
                //                                delete()
                //                                dismiss()
                //                            }
                //                            Button("取消", role: .cancel) {
                //                                self.showAlert = false
                //                            }
                //                        })
                //                    }
                //                }
                
                
                
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: {
            self.isDone = book.isDone
            UIDevice.current.isBatteryMonitoringEnabled = true
        })
        .onDisappear(perform: {
            book.isDone = self.isDone
            save()
        })
    }
    
    @ViewBuilder
    var exportBox:some View{
        //        VStack{
        VStack(){
            VStack{
                mainView
                    .frame(width: 280)
                                                
                Image("qr")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60,height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke( lineWidth: 1)
                            .foregroundColor(.black.opacity(0.6))
                    )
                
                
            }
            .padding()
            .padding(.top,15)
            .overlay(
                RoundedRectangle(cornerRadius: 10.0)
                    .stroke(lineWidth: 3.0)
                    .foregroundColor(Color("AccentColor"))
            )
            
            Text("test").font(.title)
                .opacity(0)
        }
        
        .foregroundColor(.black)
        .padding([.trailing,.leading],15)
        .padding([.top,.bottom],-15)
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
