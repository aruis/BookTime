//
//  BookCard.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/1.
//

import SwiftUI
import AlertToast
import ConfettiSwiftUI

struct BookCard: View {
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @AppStorage("isFirstBookCard") var isFirstBookCard = true
    
    @ObservedObject var book: Book
    
    @State private var handShowTimer:Bool = false
    @State private var showTimer:Bool = false
    @State private var showSharePic:Bool = false
    @State private var showAlert:Bool = false
    @State private var showBatterySheet:Bool = false    
    
    
    @State var downTrigger:Int = 0
    @State var isDone = false
    
    @State var hPhone = true
    
    //    @State var forceRight = false
    
    @State private var shareImage:UIImage? = nil
    
    @State private var isFullScreen = true
    
    @State private var orientation = UIDeviceOrientation.unknown
    
    let generator = UINotificationFeedbackGenerator()
    
    var body: some View {
        
        ScrollView {
            VStack(alignment: .center,spacing: 16){
                
                VStack(alignment: .center,spacing: 16){
                    Text(String(localized: "《") + book.name + String(localized: "》")).font(.system(.title2))
                    
                    Image(uiImage: UIImage(data: book.image) ?? UIImage())
                        .resizable()
                        .scaledToFit()
                        .frame(minWidth: 0,maxWidth: 150)
                        .padding()
                        .shadow(color: Color( "image.border"), radius: 8,x:10,y:10)
                        .onTapGesture {
                            self.handShowTimer = true
                            self.showTimer = true
                        }
                    
                    if let tagString = book.tags{
                        if !tagString.isEmpty {
                            HStack{
                                ForEach( tagString.split(separator: ",").map({Tag(name: String($0))})){tag in
                                    
                                    Text(tag.name)
                                        .padding(3)
                                        .padding(.horizontal,5)
                                        .background(.gray.opacity(0.2))
                                        .clipShape(Capsule())
                                        .font(.subheadline)
                                    
                                }
                            }
                        }
                        
                    }
                    
                    
                    HStack(spacing:15){
                        ForEach(0...4,id: \.self) {index in
                            Image(systemName: book.rating > index ? "star.fill" : "star")
                            //                                .font(.title2)
                                .resizable()
                                .foregroundColor(.accentColor)
                                .scaledToFit()
                                .frame(width: 40,height: 40)
                                .scaleEffect(book.rating == index+1 ? 1.25 : 1.0)
                                .animation(.linear(duration: 0.1), value: book.rating)
                                .onTapGesture {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    
                                    if  book.rating == index+1 {
                                        book.rating = 0
                                    }else{
                                        book.rating = index+1
                                    }
                                    
                                    save()
                                }
                            
                            
                        }
                    }
                    .padding(10)
                    .opacity(isDone ? 1 : 0)
                        .animation(.default, value: isDone)
                        .gesture(DragGesture().onChanged{value in
                            let x =  value.location.x
                            var target = 0
                            if(x <= 0 ){
                                target = 0
                            }else if (x > 150){
                                target = 5
                            } else{
                                target = Int(x / 40) + 1
                            }
                            if( book.rating !=  target){
                                book.rating = target
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }.onEnded{value in
                            save()
                        })
                    
                    
                    if book.readMinutes > 0{
                        VStack{
                            Slogan(title: String(localized: "Reading for",comment: "fredingForDay"), unit: String(localized: "day"), value: $book.readDays,isRendererImage: false)
                            Slogan(title:  String(localized: "Reading for",comment: "fredingForMin"), unit: String(localized: "min"), value: $book.readMinutes,isRendererImage: false)
                        }
                    }
                    
                    
                    
                }
                
                
                ZStack{
                    RoundedRectangle(cornerRadius: isDone ? 25:5)
                        .frame(width: isDone ? 50:250, height: 50)
                        .foregroundColor(isDone ? .green : Color(UIColor.systemGray5))
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
                    
//                        .foregroundColor(.white)
                }
                .frame(minWidth: 0,maxWidth: .infinity)
                .frame(height:80)
                .onTapGesture {
                    isDone.toggle()
                    if(isDone){
                        generator.notificationOccurred(.success)
                        downTrigger+=1
                    }
                    
                    book.isDone = isDone
                    
                    if(isDone){
                        book.doneTime = Date()
                        book.status = BookStatus.readed.rawValue
                    }else{
                        book.status = BookStatus.reading.rawValue
                    }
                                                            
                    save()

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
                    Button{
                        showSharePic = true
                    }label:{
                        Image(systemName: "square.and.arrow.up")
                    }
                    
//                    ShareLink(item: Image(uiImage: generateSnapshot()), preview: SharePreview("BookTime"))
                }
                
            })
                        
            ConfettiCannon(counter: $downTrigger,num:36,radius: 700)
            
        }
        .onRotate { newOrientation in
            if newOrientation.isFlat{
                return
            }
            
            if orientation != .unknown && orientation.isPortrait == newOrientation.isPortrait {
                return
            }
            
            orientation = newOrientation
            
            if orientation.isLandscape {
                if !showTimer {
                    showTimer = true
                    handShowTimer = false
                }
            } else if !handShowTimer {
                showTimer = false
            }
            
            
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: {
            self.isDone = book.isDone
            UIDevice.current.isBatteryMonitoringEnabled = true
        })
        .fullScreenCover(isPresented: $showTimer, content: {
            TimerView(book: book,handShowTimer: $handShowTimer)
                .persistentSystemOverlays(.hidden)
                .onAppear(perform: {
                    generator.notificationOccurred(.success)
                })
        })
        .sheet(isPresented: $showSharePic){
            VStack(spacing: 30){
                BookCardExport(book: book)
                ShareLink(item: Image(uiImage: generateSnapshot()), preview: SharePreview("BookTime")){
                    Label( "Share",systemImage:"square.and.arrow.up.circle")
                        .font(.largeTitle)
                        .labelStyle(.iconOnly)
                        
                }
            }
            
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
    

    @MainActor
    private func generateSnapshot() -> UIImage {
        let exportBox = BookCardExport(book: book)
        let renderer = ImageRenderer(content: exportBox)
        renderer.scale = 2
        return  renderer.uiImage ?? UIImage()
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
