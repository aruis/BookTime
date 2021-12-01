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

    var body: some Scene {
        WindowGroup {
            BookList()
                .environment(\.managedObjectContext,BookPersistenceController.preview.container.viewContext)

//            BookList()                .environment(\.managedObjectContext,bookPersistenceController.container.viewContext)
        }
    }
}
