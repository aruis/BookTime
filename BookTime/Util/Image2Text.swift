//
//  Image2Text.swift
//  BookTime
//
//  Created by 牧云踏歌 on 2023/5/10.
//

//import Foundation
import UIKit
import Vision
import Combine

struct Image2Text{
    
    static func request(saveImage:UIImage) -> Future<String, Error> {
        Future { promise in
            
            guard let cgImage =  saveImage.cgImage else {
//                promise(.failure(error))
                return
            }

            // Create a new image-request handler.
            let requestHandler = VNImageRequestHandler(cgImage: cgImage)

            // Create a new request to recognize text.
            let request = VNRecognizeTextRequest(completionHandler: { request, error in
                guard let observations =
                        request.results as? [VNRecognizedTextObservation] else {
                    promise(.failure(error!))
                    return
                }
                let recognizedStrings = observations.compactMap { observation in
                    // Return the string of the top VNRecognizedText instance.
                    return observation.topCandidates(1).first?.string
                }.joined(separator: ",")
                
                // Process the recognized strings.
        //            print(recognizedStrings)
                
                promise(.success(recognizedStrings))

            })
            
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["zh_CN", "en_US","en_GB"]

            do {
                // Perform the text-recognition request.
                try requestHandler.perform([request])
            } catch {
                print("Unable to perform the requests: \(error).")
            }

        }
        
    }
    
    
}
