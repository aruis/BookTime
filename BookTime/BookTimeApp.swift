//
//  BookTimeApp.swift
//  BookTime
//
//  Created by Liu Rui on 2021/11/30.
//

import SwiftUI

@main
struct BookTimeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
