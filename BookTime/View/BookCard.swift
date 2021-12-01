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
    
    @ObservedObject var book: Book
    
    @State private var showTimer:Bool = false
    
    var body: some View {
        
        if verticalSizeClass == .compact || showTimer{
            VStack{
                TimerView(book: book)
                    .onDisappear(perform: {
                        self.showTimer = false
                    })
                
            }
            
        } else{
            ScrollView {
                VStack(alignment: .center,spacing: 10){
                    Text(book.name).font(.system(.title))
                    
                    Image(uiImage: UIImage(data: book.image)!)
                        .resizable()
                        .scaledToFit()
                        .frame(minWidth: 0,maxWidth: 180)
                        .padding()
                        .shadow(color: Color( "image.border"), radius: 8,x:10,y:10)
                    //                    .padding(10)
                    
                    //                Spacer(minLength: 10)
                    
                    Text("您已阅读:").font(.system(.title))
                    Text(book.readMinutes.asString()).font(.system(.largeTitle))
                    Button(action: {
                        self.showTimer = true
                    }) {
                        HStack {
                            Image(systemName: "iphone.landscape")
                                .font(.system(size: 20))
                            
                            Text(book.readMinutes>0 ? "继续阅读":"开始阅读")
                                .font(.title2)
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 50)
    //                    .background(Color.blue)
    //                    .foregroundColor(.white)
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }
                }
                
                //            .padding(.top,-50)
                .padding(10)
                //            .toolbar {
                //                ToolbarItem(placement: .navigationBarLeading) {
                //                    Button(action: {
                //                        dismiss()
                //                    }) {
                //                        Text("\(Image(systemName: "chevron.left"))")
                //                    }
                //                    .opacity(showReview ? 0 : 1)
                //                }
                //            }
                
                
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)

        }
        
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
