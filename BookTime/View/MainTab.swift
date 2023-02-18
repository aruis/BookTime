//
//  MainTab.swift
//  BookTime
//
//  Created by 牧云踏歌 on 2023/2/18.
//

import SwiftUI
import WidgetKit

struct MainTab: View {
    
    @AppStorage("targetMinPerday") var targetMinPerday = 45
    @AppStorage("todayReadMin") var todayReadMin = 0
    
    @State private var selectedTabIndex = 0
    @AppStorage("hasViewdWalkthrough") var hasViewdWalkthrough = false
    @State private var showWalkthrough = false
    
    var body: some View {
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
    }
}

struct MainTab_Previews: PreviewProvider {
    static var previews: some View {
        MainTab()
    }
}
