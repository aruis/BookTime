//
//  ColorExt.swift
//  BookTime
//
//  Created by Liu Rui on 2022/6/6.
//

import Foundation
import SwiftUI

extension Color {
    
    public init(red: Int, green: Int, blue: Int, opacity: Double = 1.0) {
        let redValue = Double(red) / 255.0
        let greenValue = Double(green) / 255.0
        let blueValue = Double(blue) / 255.0
        
        self.init(red: redValue, green: greenValue, blue: blueValue, opacity: opacity)
    }
}
