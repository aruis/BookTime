//
//  AddBook.swift
//  BookTime
//
//  Created by 牧云踏歌 on 2023/2/19.
//

import SwiftUI
import PhotosUI

struct AddBook: View {
    @State private var selectedPhotoData: Image?
    @State private var selectedItem: PhotosPickerItem?
    
    
//    var imageSelection: PhotosPickerItem? = nil {
//        didSet {
//            if let imageSelection {
//                let progress = loadTransferable(from: imageSelection)
//                selectedPhotoData = .loading(progress)
//            } else {
//                selectedPhotoData = .empty
//            }
//        }
//    }
    
    var body: some View {
        VStack{
            
            if let selectedPhotoData
               {

                selectedPhotoData
                    .resizable()
                    .scaledToFill()
                    .clipped()

            }
            
            
            PhotosPicker(selection: $selectedItem,matching:
                    .images) {
                Label("Select a photo", systemImage: "photo")
            }
            .tint(.purple)
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedPhotoData = Image(uiImage: UIImage(data: data)!) 
                    }
                }
            }
        }
    }
    

}


struct AddBook_Previews: PreviewProvider {
    static var previews: some View {
        AddBook()
    }
}
