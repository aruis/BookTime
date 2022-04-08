//
//  ViewExt.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/15.
//

import SwiftUI

extension View {
    func snapshot(origin:CGPoint = .zero) -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 5
        format.opaque = false
        
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
//        view?.backgroundColor = .clear
        
        let window = UIWindow(frame: view!.bounds)
        window.addSubview(controller.view)
        window.makeKeyAndVisible()
        
        let renderer = UIGraphicsImageRenderer(bounds: view!.bounds, format: format)
        let image =  renderer.image { rendererContext in
            view?.layer.render(in: rendererContext.cgContext)
        }
        
//        return image
        return UIImage(data: image.aspectFittedToWidth(600).jpegData(compressionQuality: 0.85)!)!
    }
    
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
          self.modifier(DeviceRotationViewModifier(action: action))
    }
}

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}
