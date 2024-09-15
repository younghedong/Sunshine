//
//  ContentView.swift
//  Sunshine
//
//  Created by dongzi on 2024/9/15.
//

import SwiftUI
import TVVLCKit
import AMSMB2

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var showingSMBSettings = false
    @State private var selectedVideo: FileItem?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.items) { item in
                    Button(action: {
                        if item.isDirectory {
                            viewModel.loadDirectory(path: item.path)
                        } else {
                            selectedVideo = item
                        }
                    }) {
                        HStack {
                            Image(systemName: item.isDirectory ? "folder" : "film")
                            Text(item.name)
                        }
                    }
                }
            }
            .navigationTitle(viewModel.currentPath == "/" ? "根目录" : viewModel.currentPath)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSMBSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSMBSettings) {
                SMBSettingsView(isPresented: $showingSMBSettings, settings: $viewModel.settings, testConnection: viewModel.testConnection)
            }
            .fullScreenCover(item: $selectedVideo) { item in
                VideoPlayerView(videoURL: viewModel.getVideoURL(for: item))
            }
            .task {
                await viewModel.connectAndLoadDirectory()
            }
            .alert(item: $viewModel.errorWrapper) { wrapper in
                Alert(title: Text("错误"), message: Text(wrapper.error), dismissButton: .default(Text("确定")))
            }
        }
    }
}

class ContentViewModel: ObservableObject {
    @Published var items: [FileItem] = []
    @Published var currentPath: String = "/"
    @Published var errorWrapper: ErrorWrapper?
    @Published var settings: SMBSettings
    
    private var client: AMSMB2?
    
    init() {
        if let savedSettings = UserDefaults.standard.data(forKey: "SMBSettings"),
           let decodedSettings = try? JSONDecoder().decode(SMBSettings.self, from: savedSettings) {
            settings = decodedSettings
        } else {
            settings = SMBSettings(serverAddress: "192.168.31.59", username: "hedong", password: "", sharedFolder: "movies")
        }
    }
    
    func connectAndLoadDirectory() async {
        await connectAndLoadDirectoryAsync()
    }
    
    private func connectAndLoadDirectoryAsync() async {
        let url = URL(string: "smb://\(settings.serverAddress)")!
        let credential = URLCredential(user: settings.username, password: settings.password, persistence: .forSession)
        print("尝试连接到 SMB 服务器: \(url), 用户名: \(settings.username)")
        
        for attempt in 1...3 {
            do {
                client = AMSMB2(url: url, credential: credential)
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    client?.connectShare(name: settings.sharedFolder) { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                }
                print("连接成功，开始加载目录")
                await loadDirectory(path: "/")
                return
            } catch {
                print("连接尝试 \(attempt) 失败: \(error.localizedDescription)")
                if attempt == 3 {
                    DispatchQueue.main.async {
                        self.errorWrapper = ErrorWrapper(error: error.localizedDescription)
                    }
                } else {
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 等待1秒后重试
                }
            }
        }
    }
    
    func loadDirectory(path: String) {
        Task {
            do {
                print("尝试列出目录内容: \(path)")
                let files = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[[URLResourceKey: Any]], Error>) in
                    client?.contentsOfDirectory(atPath: path) { result in
                        switch result {
                        case .success(let files):
                            print("成功获取目录内容，文件数量: \(files.count)")
                            continuation.resume(returning: files)
                        case .failure(let error):
                            print("获取目录内容失败: \(error.localizedDescription)")
                            continuation.resume(throwing: error)
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.items = files.compactMap { entry in
                        guard let name = entry[.nameKey] as? String,
                              let isDirectory = entry[.fileResourceTypeKey] as? URLFileResourceType else {
                            print("无法解析文件项: \(entry)")
                            return nil
                        }
                        return FileItem(name: name,
                                        isDirectory: isDirectory == .directory,
                                        path: (path as NSString).appendingPathComponent(name))
                    }
                    print("更新 UI，显示 \(self.items.count) 个项目")
                    self.currentPath = path
                }
            } catch {
                print("加载目录时发生错误: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorWrapper = ErrorWrapper(error: error.localizedDescription)
                }
            }
        }
    }
    
    func navigateUp() {
        let parentPath = (currentPath as NSString).deletingLastPathComponent
        loadDirectory(path: parentPath)
    }
    
    func getVideoURL(for item: FileItem) -> URL {
        let encodedUsername = settings.username.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed) ?? ""
        let encodedPassword = settings.password.addingPercentEncoding(withAllowedCharacters: .urlPasswordAllowed) ?? ""
        let urlString = "smb://\(encodedUsername):\(encodedPassword)@\(settings.serverAddress)/\(settings.sharedFolder)\(item.path)"
        let url = URL(string: urlString)!
        print("生成视频 URL: \(url)")
        return url
    }
    
    func testConnection(_ completion: @escaping (Bool, String?) -> Void) {
        let url = URL(string: "smb://\(settings.serverAddress)")!
        let credential = URLCredential(user: settings.username, password: settings.password, persistence: .forSession)
        print("测试连接到 SMB 服务器: \(url)")
        let testClient = AMSMB2(url: url, credential: credential)
        
        testClient?.connectShare(name: settings.sharedFolder) { error in
            if let error = error {
                print("测试连接失败: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            } else {
                print("测试连接成功")
                completion(true, nil)
            }
        }
    }
}

#Preview {
    ContentView()
}
