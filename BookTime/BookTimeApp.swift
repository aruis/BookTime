//
//  BookTimeApp.swift
//  BookTime
//
//  Created by Liu Rui on 2021/11/30.
//

import SwiftUI
import WidgetKit

@main
struct BookTimeApp: App {
    
    @AppStorage("targetMinPerday") var targetMinPerday = 45
    @AppStorage("todayReadMin") var todayReadMin = 0
    
    @State private var selectedTabIndex = 0
    let bookPersistenceController = BookPersistenceController.shared
    
    @AppStorage("hasViewdWalkthrough") var hasViewdWalkthrough = false
    @State private var showWalkthrough = false
    
    
    
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
                        Label{
                            Text("Achievement")
                        }icon: {
                            Image(systemName: "target",variableValue: CGFloat(todayReadMin)/CGFloat(targetMinPerday))                            
                        }
                        //                        Label("Achievement",systemImage:"target")
                    }
                    .tag(1)
                
                Setting()
                    .tabItem{
                        Label("Setting",systemImage: "gearshape")
                    }
                    .tag(2)
            }
            .sheet(isPresented: $showWalkthrough){
                Tutorial()
            }
            .onAppear(){
                showWalkthrough = hasViewdWalkthrough ? false : true
                WidgetCenter.shared.reloadAllTimelines()
                //                showWalkthrough = true
            }
            
            // show tutorial
            .environment(\.managedObjectContext,bookPersistenceController.container.viewContext)
            //            .environment(\.managedObjectContext , BookPersistenceController.preview.container.viewContext)
        }
    }
}
