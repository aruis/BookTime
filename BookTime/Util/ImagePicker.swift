//
//  ImagePicker.swift
//  FoodPin
//
//  Created by Liu Rui on 2021/11/26.
//

import UIKit
import SwiftUI
import Vision
import Combine

struct ImagePicker:UIViewControllerRepresentable{
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    @Binding var selectedImage: UIImage
    @Binding var textInPhoto: String
    
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) ->  UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
        
        
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator:NSObject,UIImagePickerControllerDelegate,UINavigationControllerDelegate{
        var cancellable: AnyCancellable?
        var parent: ImagePicker
        
        init(_ parent: ImagePicker){
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
                
                let saveImage = UIImage(data: image.aspectFittedToHeight(400).jpegData(compressionQuality: 0.85)!) ?? UIImage()
                parent.selectedImage = saveImage
                
                cancellable = Image2Text.request(saveImage: saveImage)
                    .sink(receiveCompletion: { completion in
                    }, receiveValue: { someValue in
                        self.parent.textInPhoto = someValue
                    })
                
            }
            parent.dismiss()
        }
        
    }
}
