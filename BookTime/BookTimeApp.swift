//
//  BookTimeApp.swift
//  BookTime
//
//  Created by Liu Rui on 2021/11/30.
//

import SwiftUI

@main
struct BookTimeApp: App {
    @State private var selectedTabIndex = 0
    let bookPersistenceController = BookPersistenceController.shared

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTabIndex){
                BookList()
                    .tabItem {
                        Label("Bookshelf",systemImage: "books.vertical")
                    }
                    .tag(0)
                
                Statistics()
                    .tabItem {
                        Label("Achievement",systemImage:"target")
                    }
                    .tag(1)
                
                Setting()
                    .tabItem{
                        Label("Setting",systemImage: "gearshape")
                    }
                    .tag(2)
            }
            .environment(\.managedObjectContext,bookPersistenceController.container.viewContext)
//            .environment(\.managedObjectContext , BookPersistenceController.preview.container.viewContext)
        }
    }
}
