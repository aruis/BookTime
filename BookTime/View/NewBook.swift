//
//  NewBook.swift
//  BookTime
//
//  Created by Liu Rui on 2021/11/30.
//

import SwiftUI
import VisionKit
import Vision
import AlertToast


struct NewBook: View {
    enum FocusInput{
        case name
        case author
        case tag
    }
    
    
    @EnvironmentObject var appData: AppData
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject public var bookViewModel: BookViewModel
    
    //    @ObservedObject private var bookViewModel: BookViewModel
    
    @State private var showToast = false
    @State private var showPhotoOptins = false
    @State private var photoSource: PhotoSource?
    @State private var recognizedText = "Tap button to start scanning"
    
    @State private var textInPhoto:String = ""
    @State private var textInPhotoList:[String] = []
    
    
    @State private var tagInput:String = ""
    
    @FocusState private var focusInput:FocusInput?
    
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
                VStack{
                    HStack(alignment:.top, spacing:0){
                        VStack(spacing: 8){
                            Image(uiImage: bookViewModel.image)
                                .resizable()
                                .scaledToFit()
                                .frame(minWidth: 0,maxWidth: 100)
                                .shadow(color: Color( "image.border"), radius: 10)
                               
                            
                            Text("Set the book cover")
                                .font(.caption)
                                .foregroundColor(Color(.darkGray))
                            
                            Spacer()
                        }
                        .padding(.horizontal,10)
                        .onTapGesture {
                            self.showPhotoOptins.toggle()
                        }
                        .confirmationDialog("Choose a picture as the cover of the book", isPresented: $showPhotoOptins , titleVisibility: .visible){
                            Button("Camera"){
                                self.photoSource = .camera
                            }
                            
                            if VNDocumentCameraViewController.isSupported{
                                Button("AI Camera [Beta]"){
                                    self.photoSource = .documentScan
                                }
                            }
                            
                            Button("Photo Library"){
                                self.photoSource = .photoLibrary
                            }
                            
                        }
                        
                        VStack(spacing: 16) {
                            TextField("Please enter the title of the book",text: $bookViewModel.name)
                                .font(.system(size:16,weight: .semibold,design: .rounded))
                                .padding(.vertical,10)
                                .padding(.horizontal,8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(focusInput == .name ? Color.accentColor : Color(.systemGray5),lineWidth: 1)
                                )
                                .focused($focusInput,equals: .name)
                                .textInputAutocapitalization(.words)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusInput = .author
                                }
                            
                            TextField("Please enter the author name",text: $bookViewModel.author)
                                .font(.system(size:16,weight: .semibold,design: .rounded))
                                .padding(.vertical,10)
                                .padding(.horizontal,8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(focusInput == .author ? Color.accentColor : Color(.systemGray5),lineWidth: 1)
                                )
                                .textInputAutocapitalization(.words)
                                .focused($focusInput,equals: .author)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusInput = .tag
                                }
                            
                            
                            TextField("Please enter a tag",text: $tagInput)
                                .font(.system(size:16,weight: .semibold,design: .rounded))
                                .padding(.vertical,10)
                                .padding(.horizontal,8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(focusInput == .tag ? Color.accentColor : Color(.systemGray5),lineWidth: 1)
                                )
                                .overlay(
                                    
                                    HStack(){
                                        Spacer()
                                        
                                        if tagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                                            Button(action:addTag, label: {
                                                Label("",systemImage: "plus.circle")
                                            })
                                        }
                                    }
                                    
                                )
                                
                                .textInputAutocapitalization(.words)
                                .focused($focusInput,equals: .tag)
                            
                                .onSubmit{
                                    if tryAddTag() {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            focusInput = .tag
                                        }
                                    }else if( save()){
                                        dismiss()
                                    }
                                    
                                }
                            
                            
                            
                            
                        }
                        .padding(.horizontal,12)
                    }
//                    .padding(16)
                    
                    HStack{
                       
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80),spacing: 2),],spacing: 4) {
                            ForEach(bookViewModel.tags){item in
                                Button(action: {
                                    bookViewModel.tags.removeAll(where: {$0.name == item.name})
                                }, label: {
                                    Label(item.name, systemImage: "multiply")
                                        .labelStyle(TagLabelStyle())
                                    
                                })
                                .buttonStyle(.bordered)                                
//                                .background(Color.white)
//                                .foregroundColor(.gray)

                                
                            }
                        }
                        .padding(8)
                       
                       
                    }

                }
                .padding(12)
            }
            .navigationTitle(bookViewModel.book == nil ? "Add a New Book":"Modify the Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .cancellationAction){
                    Button(action: {
                        dismiss()
                    }){
                        Text("Cancel")                            
                    }

                }
                
                ToolbarItem(placement: .primaryAction){
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
                
                ToolbarItemGroup(placement: .keyboard) {
                    
                    ScrollView(.horizontal){
                        HStack{
                            if focusInput == .tag {
                                ForEach(appData.tags){x in
                                    if bookViewModel.tags.first(where:{ tag in
                                        tag.name == x.name
                                    }) == nil {
                                        Button(x.name) {
                                            bookViewModel.tags.append(x)
                                        }
                                    }
                                }
                            } else if textInPhotoList.count > 0{
                                ForEach(textInPhotoList,id:\.self){x in
                                        Button(x) {
                                            if focusInput == .author {
                                                bookViewModel.author += x
                                            }else{
                                                bookViewModel.name += x
                                            }
                                        }
                                        
                                    }
                                
                            }
                        }
                        
                    }
                    
                }

            }

//            .onAppear{
//                focusInput = .name
//            }
            
            //            .actionSheet(isPresented: $showPhotoOptins){
            //                if false && VNDocumentCameraViewController.isSupported{
            //                    return  ActionSheet(title: Text("Choose a picture as the cover of the book").font(.system(.title)),
            //                                        message: nil,
            //                                        buttons: [
            //                                            .default(Text("Camera")){
            //                                                self.photoSource = .camera
            //                                            },
            //                                            .default(Text("AI Camera")){
            //                                                self.photoSource = .documentScan
            //                                            },
            //                                            .default(Text("Photo Library")){
            //                                                self.photoSource = .photoLibrary
            //                                            },
            //                                            .cancel(Text("Cancel"))
            //
            //                                        ]
            //                    )
            //
            //                }
            //                else{
            //                    return   ActionSheet(title: Text("Choose a picture as the cover of the book").font(.system(.title)),
            //                                         message: nil,
            //                                         buttons: [
            //                                            .default(Text("Camera")){
            //                                                self.photoSource = .camera
            //                                            },
            //                                            .default(Text("Photo Library")){
            //                                                self.photoSource = .photoLibrary
            //                                            },
            //                                            .cancel(Text("Cancel"))
            //
            //                                         ]
            //                    )
            //
            //                }
            //            }
            .fullScreenCover(item: $photoSource){source in
                switch source {
                case .documentScan: ScanDocumentView(selectedImage: $bookViewModel.image,textInPhoto: $textInPhoto)
                case .photoLibrary: ImagePicker(sourceType: .photoLibrary, selectedImage: $bookViewModel.image,textInPhoto:$textInPhoto).ignoresSafeArea()
                case .camera: ImagePicker(sourceType: .camera, selectedImage: $bookViewModel.image,textInPhoto:$textInPhoto).ignoresSafeArea()
                }
            }
            .toast(isPresenting: $showToast,duration: 3,tapToDismiss: true){
                AlertToast(displayMode: .banner(.pop), type: .systemImage("exclamationmark.circle.fill", .orange), title: String(localized: "You haven't entered the title of the book yet"))
            }
        }
        .onChange(of: textInPhoto, perform: {value in
            textInPhotoList = value.split(separator: ",").map{String($0)}
        })
        
    }
    
    private func tryAddTag() -> Bool{
        let tagString = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if tagString.isEmpty {
            return false
        } else {
            addTag()
            return true
        }
    }
    
    private func addTag(){
        let tagString = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        tagString.split(separator: ",").forEach{
            let _tag = Tag(name: String($0))
            if(bookViewModel.tags.firstIndex(where: { tag in
                tag.name == _tag.name
            }) == nil){
                bookViewModel.tags.append(_tag)
            }
        }
        tagInput = ""
    }
    
    private func save() -> Bool{
        if(bookViewModel.name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty) {
            showToast = true
            generator.notificationOccurred(.error)
            return false
        }
        
        addTag()
        
        if let book = bookViewModel.book{
            book.image = bookViewModel.image.pngData()!
            book.name = bookViewModel.name
            book.author = bookViewModel.author
            var tag = ""
            bookViewModel.tags.forEach({t in
                tag += t.name
                tag += ","
            })
            book.tags = tag
            
        }else{
            let book = Book(context:context)
            book.id = UUID().uuidString
            book.image = bookViewModel.image.pngData()!
            book.name = bookViewModel.name
            book.author = bookViewModel.author
            book.isDone = false
            book.createTime = Date()
            var tag = ""
            bookViewModel.tags.forEach({t in
                tag += t.name
                tag += ","
            })
            book.tags = tag
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


