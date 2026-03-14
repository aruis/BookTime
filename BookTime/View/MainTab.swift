//
//  MainTab.swift
//  BookTime
//
//  Created by 牧云踏歌 on 2023/2/18.
//

import SwiftUI
import WidgetKit

struct MainTab: View {
    enum Tab: Hashable {
        case bookshelf
        case statistics
        case setting
    }
    
    @AppStorage("targetMinPerday") var targetMinPerday = 45
    @AppStorage("todayReadMin") var todayReadMin = 0
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var selectedTab: Tab = .bookshelf
    @AppStorage("hasViewdWalkthrough") var hasViewdWalkthrough = false
    @State private var didEvaluateWalkthrough = false
    
    var body: some View {
        TabView(selection: $selectedTab){
            
            BookList()
                .tabItem {
                    Label("Bookshelf",systemImage: "books.vertical")
                }
                .tag(Tab.bookshelf)
            
            Statistics()
                .tabItem {
                    Label{
                        Text("Achievement")
                    }icon: {
                        Image(systemName: "target",variableValue: CGFloat(todayReadMin)/CGFloat(targetMinPerday))
                    }
                }
                .tag(Tab.statistics)
            
            Setting()
                .tabItem{
                    Label("Setting",systemImage: "gearshape")
                }
                .tag(Tab.setting)
        }
        .sensoryFeedback(.selection, trigger: selectedTab)
        .sheet(isPresented: walkthroughBinding){
            Tutorial()
        }
        .onAppear(){
            didEvaluateWalkthrough = true
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
    
    private var walkthroughBinding: Binding<Bool> {
        Binding(
            get: {
                didEvaluateWalkthrough && !hasViewdWalkthrough
            },
            set: { newValue in
                if !newValue {
                    didEvaluateWalkthrough = false
                }
            }
        )
    }
}

struct MainTab_Previews: PreviewProvider {
    static var previews: some View {
        MainTab()
    }
}
