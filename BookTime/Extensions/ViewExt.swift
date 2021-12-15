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

        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: origin, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
