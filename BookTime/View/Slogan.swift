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
    @Binding var value: Int
    
    var isRendererImage:Bool
    
    var body: some View {
        HStack(alignment: .firstTextBaseline){
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            if(isRendererImage){
                Text("\(value)")
                    .font(.largeTitle)
            }else{
                RollingText(font: .largeTitle, weight: .medium, value: $value)
            }
            
            
            
            
            Text(unit)
                .font(.subheadline)
                .foregroundColor(.gray)
            
        }
    }
}
