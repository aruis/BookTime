//
//  TestSwiftUIView.swift
//  BookTime
//
//  Created by Liu Rui on 2022/6/16.
//

import SwiftUI

struct TestSwiftUIView: View {
    var body: some View {
        HStack{
            
            Button(action: {
                
            }, label: {
                Image(systemName:"clear")
                    .frame(width: 28, height: 28)
            })
            .font(.title2)
            .buttonStyle(.bordered)

            
            Button(action: {
                
            }, label: {
                Image(systemName:"iphone")
                    .frame(width: 28, height: 28)
            })
            .font(.title2)
            .buttonStyle(.bordered)

            
            Button(action: {
                
            }, label: {
                Image(systemName:"lightbulb")
                    .frame(width: 28, height: 28)
            })
            .font(.title2)
            .buttonStyle(.bordered)

        }
    }
}

struct TestSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        TestSwiftUIView()
    }
}
