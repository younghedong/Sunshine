import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @FocusState private var focusedTab: Int?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            RecentlyWatchedView(focusTab: focusRecentlyWatchedTab)
                .tabItem {
                    VStack {
                        Image(systemName: "clock.fill")
                        Text("最近观看")
                    }
                }
                .tag(0)
            
            ContentView(focusTab: focusMyFilesTab)
                .tabItem {
                    VStack {
                        Image(systemName: "folder.fill")
                        Text("我的文件")
                    }
                }
                .tag(1)
            
            SettingsView(focusTab: focusSettingsTab)
                .tabItem {
                    VStack {
                        Image(systemName: "gearshape.fill")
                        Text("设置")
                    }
                }
                .tag(2)
        }
        .accentColor(.white)
        .onChange(of: selectedTab) { newValue in
            focusedTab = newValue
        }
    }
    
    func focusRecentlyWatchedTab() {
        selectedTab = 0
        focusedTab = 0
    }
    
    func focusMyFilesTab() {
        selectedTab = 1
        focusedTab = 1
    }
    
    func focusSettingsTab() {
        selectedTab = 2
        focusedTab = 2
    }
}
