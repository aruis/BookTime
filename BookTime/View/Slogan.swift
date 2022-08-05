//
//  Slogan.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/15.
//

import SwiftUI

struct Slogan: View {
    var title:String
    var unit:String
    
//    var value:String
    
    @Binding var value: Int
    
    var body: some View {
        HStack(alignment: .firstTextBaseline){
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            RollingText(font: .largeTitle, weight: .medium, value: $value)
            
//            Text(value)
//                .font(.largeTitle)
//                .animation(.default, value: value)
            
            
            Text(unit)
                .font(.subheadline)
                .foregroundColor(.gray)
            
        }
    }
}
