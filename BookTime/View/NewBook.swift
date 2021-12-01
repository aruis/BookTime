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
                    save()
                    dismiss()
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
            
        }
        
    }
    
    private func save(){
        let book = Book(context:context)
        book.image = bookViewModel.image.pngData()!
        book.name = bookViewModel.name
        book.author = bookViewModel.author
        book.createTime = Date()
        
        do{
            try context.save()
        }catch{
            print("Failed to save the recode...")
            print(error.localizedDescription)
        }
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
