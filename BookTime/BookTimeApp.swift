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
    
    let transitionTime = 1.0
    
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
                            withAnimation(.easeIn(duration: 0.9 * transitionTime ).delay(0.25 * transitionTime)){
                                iconSize = 1960
                                deltaAngle = 35
                            }

                            withAnimation(.easeIn(duration: 0.35 * transitionTime).delay(0.8 * transitionTime)){
                                hideSplashtop = true
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.18 * transitionTime, execute: {
                                isShowMainTab = true
                            })

                            DispatchQueue.main.asyncAfter(deadline: .now() + 2 * transitionTime, execute: {
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
