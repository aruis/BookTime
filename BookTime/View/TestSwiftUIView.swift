//
//  TestSwiftUIView.swift
//  BookTime
//
//  Created by Liu Rui on 2022/5/11.
//

import SwiftUI

struct TestSwiftUIView: View {
    var body: some View {
        Text(Date().start(),style: .relative)
    }
}

struct TestSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        TestSwiftUIView()
    }
}
