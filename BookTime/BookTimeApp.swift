//
//  BookTimeApp.swift
//  BookTime
//
//  Created by Liu Rui on 2021/11/30.
//

import SwiftUI
import WhatsNewKit

@main
struct BookTimeApp: App {
    
    
    let bookPersistenceController = BookPersistenceController.shared
    let appData = AppData()
    
    @State var iconSize = 120.0
    @State var deltaAngle = 0.0
    
    @State var hideSplashtop = false
    
    @State var isShowSplashtop = true
    @State var isShowMainTab = false
    
    var whatsNewCollection: WhatsNewCollection {[
        WhatsNew(
            version: "2.23.5",
            title: WhatsNew.Title(text: WhatsNew.Text(String(localized: "What's New"))),
            features: [
                //                .init(
                //                    image: .init(
                //                        systemName: "heart.fill",
                //                        foregroundColor: .red
                //                    ),
                //                    title: WhatsNew.Text(String(localized: "Heartfelt Update:")),
                //                    subtitle: WhatsNew.Text(String(localized:"Added AI camera, available for testing."))
                //                ),
                .init(
                    image: .init(
                        systemName: "star.fill",
                        foregroundColor: .accentColor
                    ),
                    title: WhatsNew.Text(String(localized: "Important Enhancements:")),
                    subtitle: WhatsNew.Text(String(localized:"Optimized the UI details of some pages."))
                ),
                
                    .init(
                        image: .init(
                            systemName: "terminal.fill",
                            foregroundColor: .blue
                        ),
                        title: WhatsNew.Text(String(localized: "Bug Fixes:")),
                        subtitle: WhatsNew.Text(String(localized:"Improved interaction logic on iPad.\nFixed the bug that OCR content and tags cannot be selected on the book editing page after iOS17."))
                    )
                
                
            ],
            primaryAction: WhatsNew.PrimaryAction(
                title: WhatsNew.Text(String(localized: "Continue")),
                //                  backgroundColor: .accentColor,
                //                  foregroundColor: .white,
                hapticFeedback: .notification(.success)
            )
            
        )
    ]}
    
    
    
    let transitionTime = 1.0
    
    var body: some Scene {
        
        WindowGroup {            
            ZStack{
                if isShowMainTab {
                    MainTab()
                        .whatsNewSheet()
                }
                
                if isShowSplashtop {
                    Icon(iconSize:$iconSize,deltaAngle:$deltaAngle)
                        .compositingGroup()
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
            .environmentObject(appData)
            .environment(\.managedObjectContext,bookPersistenceController.container.viewContext)
//            .environment(\.whatsNew,
//                          WhatsNewEnvironment(
//                            versionStore: UserDefaultsWhatsNewVersionStore(),
//                            whatsNewCollection: whatsNewCollection
//                          )
//            )
        }
    }
}
