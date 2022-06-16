//
//  ImagePicker.swift
//  FoodPin
//
//  Created by Liu Rui on 2021/11/26.
//

import UIKit
import SwiftUI
import Vision

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
        var parent: ImagePicker
        init(_ parent: ImagePicker){
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
                
                let saveImage = UIImage(data: image.aspectFittedToHeight(400).jpegData(compressionQuality: 0.85)!) ?? UIImage()
                parent.selectedImage = saveImage
                
//                let size = saveImage.size
//
//                let cropRect = CGRect(
//                    x: size.width * 0.1,
//                    y: size.height * 0.1,
//                    width: size.width * 0.8,
//                    height: size.height * 0.8
//                ).integral
                
                guard let cgImage =  saveImage.cgImage else {return}

                // Create a new image-request handler.
                let requestHandler = VNImageRequestHandler(cgImage: cgImage)

                // Create a new request to recognize text.
                let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
                
                request.recognitionLevel = .accurate
                request.recognitionLanguages = ["zh_CN", "en_US","en_GB"]

                do {
                    // Perform the text-recognition request.
                    try requestHandler.perform([request])
                } catch {
                    print("Unable to perform the requests: \(error).")
                }
                
            }
            parent.dismiss()
        }
        
        func recognizeTextHandler(request: VNRequest, error: Error?) {
            guard let observations =
                    request.results as? [VNRecognizedTextObservation] else {
                return
            }
            let recognizedStrings = observations.compactMap { observation in
                // Return the string of the top VNRecognizedText instance.
                return observation.topCandidates(1).first?.string
            }.joined(separator: ",")
            
            // Process the recognized strings.
//            print(recognizedStrings)
            
            parent.textInPhoto = recognizedStrings
//            processResults(recognizedStrings)
        }
    }
}
