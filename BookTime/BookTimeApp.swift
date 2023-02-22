//
//  BookTimeApp.swift
//  BookTime
//
//  Created by Liu Rui on 2021/11/30.
//

import SwiftUI


@main
struct BookTimeApp: App {
    
    
    let bookPersistenceController = BookPersistenceController.shared
    
    
    @State var iconSize = 120.0
    @State var deltaAngle = 0.0
    
    @State var hideSplashtop = false
    
    @State var isShowSplashtop = true
    @State var isShowMainTab = false
    
    var body: some Scene {
        
        WindowGroup {
//            AddBook()
            ZStack{
                if isShowMainTab {
                    MainTab()
                }

                if isShowSplashtop {
                    Icon(iconSize:$iconSize,deltaAngle:$deltaAngle)
                        .opacity(hideSplashtop ? 0 : 1)
                        .onAppear{
                            withAnimation(.easeInOut(duration: 0.9).delay(0.25)){
                                iconSize = 960
                                deltaAngle = 35
                            }

                            withAnimation(.easeIn(duration: 0.35).delay(0.8)){
                                hideSplashtop = true
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.18, execute: {
                                isShowMainTab = true
                            })

                            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                                isShowSplashtop = false
                            })
                        }
                }
            }
            
            .environment(\.managedObjectContext,bookPersistenceController.container.viewContext)
            //            .environment(\.managedObjectContext , BookPersistenceController.preview.container.viewContext)
        }
    }
}
