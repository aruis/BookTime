//
//  TagLabelStyle.swift
//  BookTime
//
//  Created by Liu Rui on 2022/4/10.
//

import SwiftUI

struct TagLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 4) {
            configuration.title
            configuration.icon
                .opacity(0.35)
                
        }
    }
}
