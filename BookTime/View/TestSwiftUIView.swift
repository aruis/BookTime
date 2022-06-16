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
            
            Circle()
                .frame(width: 50, height: 50)
                .foregroundColor(.blue)
                .overlay(
                    Image(systemName:"clear")
                        .font(.title2)
                )
                .onTapGesture {
                    
                }

            Circle()
                .frame(width: 50, height: 50)
                .foregroundColor(.blue)
                .overlay(
                    ZStack(alignment: .bottomTrailing){
                            Image( systemName: "iphone")
                            Image( systemName: "iphone.landscape")
                                .opacity(0.35)
                        
                    }
                    .font(.title2)

                )
                .onTapGesture {
                    
                }

            
            Button(action: {
                
            }, label: {
                Image(systemName:"clear")
                    .frame(width: 28, height: 28)
            })
            .font(.title2)
            .buttonStyle(.bordered)

            
            Button(action: {
                
            }, label: {
                ZStack(alignment: .bottomTrailing){
                    
                        Image( systemName: "iphone")
                          
                        Image( systemName: "iphone.landscape")
                            .opacity(0.35)
                    
                }


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
