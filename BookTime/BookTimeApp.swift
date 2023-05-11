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
    
    
    @State var iconSize = 120.0
    @State var deltaAngle = 0.0
    
    @State var hideSplashtop = false
    
    @State var isShowSplashtop = true
    @State var isShowMainTab = false
    
    var whatsNewCollection: WhatsNewCollection {[
        WhatsNew(
            version: "2.23.3",
            title: WhatsNew.Title(text: WhatsNew.Text(String(localized: "What's New"))),
            features: [
                .init(
                    image: .init(
                        systemName: "heart.fill",
                        foregroundColor: .red
                    ),
                    title: WhatsNew.Text(String(localized: "Heartfelt Update:")),
                    subtitle: WhatsNew.Text(String(localized:"Added AI camera, available for testing."))
                ),
                .init(
                    image: .init(
                        systemName: "star.fill",
                        foregroundColor: .accentColor
                    ),
                    title: WhatsNew.Text(String(localized: "Important Enhancements:")),
                    subtitle: WhatsNew.Text(String(localized:"Automatically display update log when launching the app."))
                ),

                .init(
                    image: .init(
                        systemName: "terminal.fill",
                        foregroundColor: .blue
                    ),
                    title: WhatsNew.Text(String(localized: "Bug Fixes:")),
                    subtitle: WhatsNew.Text(String(localized:"Fixed syntax issues in the code.\nCorrected the issue where on iOS, adding a new book was not possible to select book title, author name, and tags from OCR content due to an iOS bug."))
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
//            AddBook()
            ZStack{
                if isShowMainTab {
                    MainTab()
                        .whatsNewSheet()
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
            .environment(
                               \.whatsNew,
                               WhatsNewEnvironment(
                                   // Specify in which way the presented WhatsNew Versions are stored.
                                   // In default the `UserDefaultsWhatsNewVersionStore` is used.
                                   versionStore: UserDefaultsWhatsNewVersionStore(),
//                                   versionStore: InMemoryWhatsNewVersionStore(),
                                   // Pass a `WhatsNewCollectionProvider` or an array of WhatsNew instances
                                   whatsNewCollection: whatsNewCollection
                               )
                           )
            //            .environment(\.managedObjectContext , BookPersistenceController.preview.container.viewContext)
        }
    }
}
