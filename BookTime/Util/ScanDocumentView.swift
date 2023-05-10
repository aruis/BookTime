//
//  ScanDocumentView.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/9.
//

import SwiftUI
import VisionKit
import Vision

struct ScanDocumentView: UIViewControllerRepresentable {
        
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedImage: UIImage
    @Binding var textInPhoto: String

    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let documentViewController = VNDocumentCameraViewController()
        documentViewController.delegate = context.coordinator
        return documentViewController
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // nothing to do here
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var parent: ScanDocumentView
        
        init(_ parent: ScanDocumentView){
            self.parent = parent
        }

        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            
//            let extractedImages = extractImages(from: scan)
            
            let image =  scan.imageOfPage(at: 0)
            parent.selectedImage = UIImage(data: image.aspectFittedToHeight(400).jpegData(compressionQuality: 0.85)!) ?? UIImage()
            
            Image2Text.request(saveImage: parent.selectedImage)
                .sink(receiveCompletion: { completion in
                }, receiveValue: { someValue in
                    // do what you want with the resulting value passed down
                    // be aware that depending on the publisher, this closure
                    // may be invoked multiple times.
                    self.parent.textInPhoto = someValue
                })

            
//            selectedImage.wrappedValue = scan.imageOfPage(at: 0)
//            parent.presentationMode.wrappedValue.dismiss()
            
            parent.dismiss()
        }
        
        
    }
}
