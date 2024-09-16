import SwiftUI

struct RecentlyWatchedView: View {
    @State private var recentlyWatched = [
        "大话西游",
        "功夫",
        "长津湖",
        "你好，李焕英",
        "流浪地球"
    ]
    @FocusState private var focusedItem: String?
    let focusTab: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                List(recentlyWatched, id: \.self) { movie in
                    Button(action: {
                        // 播放电影的动作
                    }) {
                        Text(movie)
                    }
                    .listRowBackground(focusedItem == movie ? Color.secondary.opacity(0.3) : Color.clear)
                    .focused($focusedItem, equals: movie)
                }
                .listStyle(PlainListStyle())
            }
            .padding(.top, 50) // 添加一些顶部填充以补偿移除的标题
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
