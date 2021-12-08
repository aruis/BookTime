//
//  NewBook.swift
//  BookTime
//
//  Created by Liu Rui on 2021/11/30.
//

import SwiftUI

struct NewBook: View {
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject private var bookViewModel: BookViewModel
    
    @State private var showToast = false
    @State private var showPhotoOptins = false
    @State private var photoSource: PhotoSource?
    
    
    init(){
        let viewModel = BookViewModel()
        viewModel.image = UIImage(named: "xiandai")!
        bookViewModel = viewModel
        
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center){
                    
                    Image(uiImage: bookViewModel.image)
                        .resizable()
                        .scaledToFit()
                        .frame(minWidth: 0,maxWidth: 180)
                        .padding()
                        .shadow(color: Color( "image.border"), radius: 20)
                        .onTapGesture {
                            self.showPhotoOptins.toggle()
                        }
                    
                    
                    FormTextField(label: "书名", placeholder: "请填入书名", value: $bookViewModel.name)
                    
                    FormTextField(label: "作者", placeholder: "在这里输入作者就好", value: $bookViewModel.author)
                    
                    Spacer()
                }
                .padding(10)
               
            }
            .navigationTitle("读一本新书")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                Button(action: {
                    if( save()){
                        dismiss()
                    }
                    
                }){
                    Text("保存")
                        .font(.headline)
                    //                        .foregroundColor(Color("NavigationBarTitle"))
                }
            }
            .actionSheet(isPresented: $showPhotoOptins){
                ActionSheet(title: Text("选择一张图片作为本书封面").font(.system(.title)),
                            message: nil,
                            buttons: [
                                .default(Text("相机")){
                                    self.photoSource = .camera
                                },
                                .default(Text("相册")){
                                    self.photoSource = .photoLibrary
                                },
                                .cancel(Text("取消"))
                                
                            ]
                )
            }
            .fullScreenCover(item: $photoSource){source in
                switch source {
                case .photoLibrary: ImagePicker(sourceType: .photoLibrary, selectedImage: $bookViewModel.image).ignoresSafeArea()
                case .camera: ImagePicker(sourceType: .camera, selectedImage: $bookViewModel.image).ignoresSafeArea()
                }
            }
            .toast(isPresenting: $showToast){

                      // `.alert` is the default displayMode
//                    AlertToast(type: .error(.red), title: "Message Sent!")
                      
                      //Choose .hud to toast alert from the top of the screen
//                          AlertToast(displayMode: .hud, type: .regular, title: "Message Sent!")
                      
                      //Choose .banner to slide/pop alert from the bottom of the screen
                AlertToast(displayMode: .hud, type: .systemImage("exclamationmark.bubble.circle.fill", .orange), title: "Message Sent!")
                  }
        }
        
    }
    
    private func save() -> Bool{
        if(bookViewModel.name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty) {
            showToast = true
            return false
        }
        
        if(bookViewModel.author.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty){
            return false
        }
        
        let book = Book(context:context)
        book.id = UUID()
        book.image = bookViewModel.image.pngData()!
        book.name = bookViewModel.name
        book.author = bookViewModel.author
        book.createTime = Date()
        
        do{
            print(book)
            try context.save()
        }catch{
            print("Failed to save the recode...")
            print(error.localizedDescription)
        }
        
        return true
    }
}

struct NewBook_Previews: PreviewProvider {
    static var previews: some View {
        NewBook()
        
        NewBook()
            .preferredColorScheme(.dark)
    }
}

struct FormTextField: View {
    let label: String
    var placeholder: String = ""
    
    @Binding var value: String
    
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label.uppercased())
                .font(.system(.headline,design: .rounded))
                .foregroundColor(Color(.darkGray))
            
            TextField(placeholder,text: $value)
                .font(.system(size:20,weight: .semibold,design: .rounded))
                .padding(.horizontal)
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(.systemGray5),lineWidth: 1)
                )
                .padding(.vertical,10)
        }
        
    }
}

enum PhotoSource: Identifiable{
    case photoLibrary
    case camera
    
    var id:Int{
        hashValue
    }
}
