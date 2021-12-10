//
//  NewBook.swift
//  BookTime
//
//  Created by Liu Rui on 2021/11/30.
//

import SwiftUI
import VisionKit
import Vision

struct NewBook: View {
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject private var bookViewModel: BookViewModel
    
    @State private var showToast = false
    @State private var showPhotoOptins = false
    @State private var photoSource: PhotoSource?
    @State private var recognizedText = "Tap button to start scanning"
    
    @FocusState private var isAuthorFocus:Bool
    
    let generator = UINotificationFeedbackGenerator()
    
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
                    
                    VStack(alignment: .leading) {
                        Text("书名".uppercased())
                            .font(.system(.headline,design: .rounded))
                            .foregroundColor(Color(.darkGray))
                        
                        TextField("请填入书名",text: $bookViewModel.name)
                            .font(.system(size:20,weight: .semibold,design: .rounded))
                            .padding(.horizontal)
                            .padding(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color(.systemGray5),lineWidth: 1)
                            )
                            .padding(.vertical,10)
                        //                            .textInputAutocapitalization(.words)
                            .submitLabel(.next)
                            .onSubmit {
                                isAuthorFocus = true
                            }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("作者".uppercased())
                            .font(.system(.headline,design: .rounded))
                            .foregroundColor(Color(.darkGray))
                        
                        TextField("请输入作者名",text: $bookViewModel.author)
                            .font(.system(size:20,weight: .semibold,design: .rounded))
                            .padding(.horizontal)
                            .padding(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color(.systemGray5),lineWidth: 1)
                            )
                            .padding(.vertical,10)
                        //                            .textInputAutocapitalization(.words)
                            .focused($isAuthorFocus)
                            .submitLabel(.done)
                        
                    }
                    
                    
                    //                    FormTextField(label: "书名", placeholder: "请填入书名", value: $bookViewModel.name)
                    //
                    //                    FormTextField(label: "作者", placeholder: "请输入作者名", value: $bookViewModel.author)
                    
                    Spacer()
                }
                .padding(10)
                
            }
            .navigationTitle("读一本新书")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                Button(action: {
                    
                    //                    print(recognizedText)
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
                if  VNDocumentCameraViewController.isSupported{
                    return  ActionSheet(title: Text("选择一张图片作为本书封面").font(.system(.title)),
                                        message: nil,
                                        buttons: [
                                            .default(Text("相机")){
                                                self.photoSource = .camera
                                            },
                                            .default(Text("AI相机")){
                                                self.photoSource = .documentScan
                                            },
                                                .default(Text("相册")){
                                                    self.photoSource = .photoLibrary
                                                },
                                            .cancel(Text("取消"))
                                            
                                        ]
                    )
                    
                }
                else{
                    return   ActionSheet(title: Text("选择一张图片作为本书封面").font(.system(.title)),
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
            }
            .fullScreenCover(item: $photoSource){source in
                switch source {
                case .documentScan: ScanDocumentView(recognizedText: $recognizedText,selectedImage: $bookViewModel.image)
                case .photoLibrary: ImagePicker(sourceType: .photoLibrary, selectedImage: $bookViewModel.image).ignoresSafeArea()
                case .camera: ImagePicker(sourceType: .camera, selectedImage: $bookViewModel.image).ignoresSafeArea()
                }
            }
            .toast(isPresenting: $showToast,duration: 3,tapToDismiss: true){
                AlertToast(displayMode: .banner(.pop), type: .systemImage("exclamationmark.circle.fill", .orange), title: "您还没有输入书名哦")
            }
        }
        
    }
    
    private func save() -> Bool{
        if(bookViewModel.name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty) {
            showToast = true
            generator.notificationOccurred(.error)
            return false
        }
        
        
        let book = Book(context:context)
        book.id = UUID()
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
                .textInputAutocapitalization(.words)
        }
        
    }
}

enum PhotoSource: Identifiable{
    case documentScan
    case photoLibrary
    case camera
    
    var id:Int{
        hashValue
    }
}
