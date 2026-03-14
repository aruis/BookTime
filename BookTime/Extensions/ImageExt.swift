//
//  ImageExt.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/9.
//

import SwiftUI
import ImageIO

extension UIImage {
    func aspectFittedToHeight(_ newHeight: CGFloat) -> UIImage {
        let scale = newHeight / self.size.height
        let newWidth = self.size.width * scale
        let newSize = CGSize(width: newWidth, height: newHeight)
        let renderer = UIGraphicsImageRenderer(size: newSize)

        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    func aspectFittedToWidth(_ newWidth: CGFloat) -> UIImage {
        let scale = newWidth / self.size.width
        let newHeight = self.size.height * scale
        let newSize = CGSize(width: newWidth, height: newHeight)
        let renderer = UIGraphicsImageRenderer(size: newSize)

        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

}

extension Data {
    func makeThumbnailData(maxPixelSize: CGFloat = 340, compressionQuality: CGFloat = 0.82) -> Data? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        
        guard let source = CGImageSourceCreateWithData(self as CFData, options as CFDictionary) else {
            return nil
        }
        
        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: compressionQuality)
    }
}
