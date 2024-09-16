import SwiftUI

struct SettingsView: View {
    @State private var showingSMBSettings = false
    @StateObject private var viewModel = ContentViewModel()
    @FocusState private var focusedItem: String?
    let focusTab: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Button(action: { showingSMBSettings = true }) {
                        Text("SMB设置")
                    }
                    .listRowBackground(focusedItem == "smbSettings" ? Color.secondary.opacity(0.3) : Color.clear)
                    .focused($focusedItem, equals: "smbSettings")
                }
                .listStyle(PlainListStyle())
            }
            .padding(.top, 50) // 添加一些顶部填充以补偿移除的标题
        }
        .sheet(isPresented: $showingSMBSettings) {
            SMBSettingsView(isPresented: $showingSMBSettings, settings: $viewModel.settings, testConnection: viewModel.testConnection)
        }
        .onExitCommand {
            if focusedItem == nil {
                focusTab()
            } else {
                focusedItem = nil
            }
        }
    }
}
