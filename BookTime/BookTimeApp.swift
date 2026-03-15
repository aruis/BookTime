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
            version: "3.26.1",
            title: WhatsNew.Title(text: WhatsNew.Text(String(localized: "What's New"))),
            features: [
                .init(
                    image: .init(
                        systemName: "sparkles",
                        foregroundColor: .accentColor
                    ),
                    title: WhatsNew.Text(String(localized: "Liquid Glass Ready")),
                    subtitle: WhatsNew.Text(String(localized: "Adapted the interface to match iOS Liquid Glass visuals."))
                ),
                .init(
                    image: .init(
                        systemName: "lightbulb.max.fill",
                        foregroundColor: .yellow
                    ),
                    title: WhatsNew.Text(String(localized: "Ultra Power Saving Timer")),
                    subtitle: WhatsNew.Text(String(localized:"Timer mode now supports a no-seconds ultra power saving display. Long press the light button to switch."))
                ),
                .init(
                    image: .init(
                        systemName: "paintbrush.pointed.fill",
                        foregroundColor: .blue
                    ),
                    title: WhatsNew.Text(String(localized: "Refined UI Details")),
                    subtitle: WhatsNew.Text(String(localized:"Polished a number of interface details for a smoother reading experience."))
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
            .environment(\.whatsNew,
                          WhatsNewEnvironment(
                            versionStore: UserDefaultsWhatsNewVersionStore(),
                            whatsNewCollection: whatsNewCollection
                          )
            )
        }
    }
}
