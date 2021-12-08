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
//            BookList().environment(\.managedObjectContext,BookPersistenceController.preview.container.viewContext)
            TabView(selection: $selectedTabIndex){
                BookList()
                    .tabItem {
                        Label("书架",systemImage: "books.vertical")
                    }
                    .tag(0)
                
                Statistics()
                    .tabItem {
                        Label("报告",systemImage:"chart.line.uptrend.xyaxis")
                    }
                    .tag(1)
                
                Setting()
                    .tabItem{
                        Label("设置",systemImage: "gearshape")
                    }
                    .tag(2)
            }.environment(\.managedObjectContext,bookPersistenceController.container.viewContext)
        }
    }
}
