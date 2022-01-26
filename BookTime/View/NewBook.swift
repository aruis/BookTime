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
    
    @ObservedObject public var bookViewModel: BookViewModel
    
    //    @ObservedObject private var bookViewModel: BookViewModel
    
    @State private var showToast = false
    @State private var showPhotoOptins = false
    @State private var photoSource: PhotoSource?
    @State private var recognizedText = "Tap button to start scanning"
    
    @State private var textInPhoto:String = ""
    @State private var userInput:String = ""
    
    @FocusState private var isAuthorFocus:Bool
    
    let generator = UINotificationFeedbackGenerator()
    
    //    init(){
    //        let viewModel = BookViewModel()
    //        viewModel.image = UIImage(named: "xiandai")!
    //        bookViewModel = viewModel
    //
    //    }
    
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center){
                    
                    Text(textInPhoto)
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
                        Text("Title")
                            .font(.system(.headline,design: .rounded))
                            .foregroundColor(Color(.darkGray))
                        
                        TextField("Please enter the title of the book",text: $bookViewModel.name)
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
                            .onChange(of: bookViewModel.name, perform: {x in
                                userInput = x
                                //                                tipWords = []
                            })
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Author")
                            .font(.system(.headline,design: .rounded))
                            .foregroundColor(Color(.darkGray))
                        
                        TextField("Please enter the author name",text: $bookViewModel.author)
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
                            .onChange(of: bookViewModel.author, perform: {x in
                                userInput = x
                            })
                        
                        
                    }
                    
                    
                    //                    FormTextField(label: "书名", placeholder: "请填入书名", value: $bookViewModel.name)
                    //
                    //                    FormTextField(label: "作者", placeholder: "请输入作者名", value: $bookViewModel.author)
                    
                    Spacer()
                }
                .padding(10)
                
            }
            .navigationTitle(bookViewModel.book == nil ? "Read a new book":"Modify the book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                Button(action: {
                    
                    //                    print(recognizedText)
                    if( save()){
                        dismiss()
                    }
                    
                }){
                    Text("Save")
                        .font(.headline)
                    //                        .foregroundColor(Color("NavigationBarTitle"))
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {

                    
                    
                        if (!userInput.isEmpty
                            && !textInPhoto.isEmpty
                        ){
                                                        
                            
                            ForEach(
                                textInPhoto.split(separator: ",")
                                    .filter{ x in
                                        x.starts(with: String(userInput.last!))
                                    }
                                    .map{String($0)}

                                ,id:\.self){x in
                                    Button(bookViewModel.name) {
                                        if isAuthorFocus {
                                            bookViewModel.author += x
                                        }else{
                                            bookViewModel.name += x
                                        }
                                    }

                                }
                        }else{
                            Text("nil")
                        }
                        
                        
                    
                    
                }
            }
            .actionSheet(isPresented: $showPhotoOptins){
                if false && VNDocumentCameraViewController.isSupported{
                    return  ActionSheet(title: Text("Choose a picture as the cover of the book").font(.system(.title)),
                                        message: nil,
                                        buttons: [
                                            .default(Text("Camera")){
                                                self.photoSource = .camera
                                            },
                                            .default(Text("AI Camera")){
                                                self.photoSource = .documentScan
                                            },
                                            .default(Text("Photo Library")){
                                                self.photoSource = .photoLibrary
                                            },
                                            .cancel(Text("Cancel"))
                                            
                                        ]
                    )
                    
                }
                else{
                    return   ActionSheet(title: Text("Choose a picture as the cover of the book").font(.system(.title)),
                                         message: nil,
                                         buttons: [
                                            .default(Text("Camera")){
                                                self.photoSource = .camera
                                            },
                                            .default(Text("Photo Library")){
                                                self.photoSource = .photoLibrary
                                            },
                                            .cancel(Text("Cancel"))
                                            
                                         ]
                    )
                    
                }
            }
            .fullScreenCover(item: $photoSource){source in
                switch source {
                case .documentScan: ScanDocumentView(recognizedText: $recognizedText,selectedImage: $bookViewModel.image)
                case .photoLibrary: ImagePicker(sourceType: .photoLibrary, selectedImage: $bookViewModel.image,textInPhoto:$textInPhoto).ignoresSafeArea()
                case .camera: ImagePicker(sourceType: .camera, selectedImage: $bookViewModel.image,textInPhoto:$textInPhoto).ignoresSafeArea()
                }
            }
            .toast(isPresenting: $showToast,duration: 3,tapToDismiss: true){
                AlertToast(displayMode: .banner(.pop), type: .systemImage("exclamationmark.circle.fill", .orange), title: String(localized: "You haven't entered the title of the book yet"))
            }
        }
        
    }
    
    private func save() -> Bool{
        if(bookViewModel.name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty) {
            showToast = true
            generator.notificationOccurred(.error)
            return false
        }
        
        
        if let book = bookViewModel.book{
            book.image = bookViewModel.image.pngData()!
            book.name = bookViewModel.name
            book.author = bookViewModel.author
        }else{
            let book = Book(context:context)
            book.id = UUID().uuidString
            book.image = bookViewModel.image.pngData()!
            book.name = bookViewModel.name
            book.author = bookViewModel.author
            book.isDone = false
            book.createTime = Date()
        }
        
        
        
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
        Text("")
        //        NewBook(Binding.)
        
        //        NewBook()            .preferredColorScheme(.dark)
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
