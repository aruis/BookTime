//
//  TestSwiftUIView.swift
//  BookTime
//
//  Created by Liu Rui on 2022/5/11.
//

import SwiftUI

struct TestSwiftUIView: View {
    var body: some View {
        VStack{
            Text(Date().start(),style: .relative)
            
            Text(Date.now, format: .dateTime.hour().minute())
            
            Text(Date.now, format: .dateTime.day().month().year())
        }
        
    }
}

struct TestSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        TestSwiftUIView()
    }
}
