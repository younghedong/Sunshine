import SwiftUI
import AMSMB2

// 如果 SMBSettings 定义在 ContentView.swift 中，你可能需要导入你的主项目模块
// import Sunshine

struct SMBSettingsView: View {
    @Binding var isPresented: Bool
    @Binding var settings: SMBSettings
    var testConnection: (@escaping (Bool, String?) -> Void) -> Void
    
    @State private var serverAddress: String
    @State private var username: String
    @State private var password: String
    @State private var sharedFolder: String
    @State private var testResult: String?
    
    init(isPresented: Binding<Bool>, settings: Binding<SMBSettings>, testConnection: @escaping (@escaping (Bool, String?) -> Void) -> Void) {
        self._isPresented = isPresented
        self._settings = settings
        self.testConnection = testConnection
        
        _serverAddress = State(initialValue: settings.wrappedValue.serverAddress)
        _username = State(initialValue: settings.wrappedValue.username)
        _password = State(initialValue: settings.wrappedValue.password)
        _sharedFolder = State(initialValue: settings.wrappedValue.sharedFolder)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("SMB设置")) {
                    TextField("服务器地址", text: $serverAddress)
                    TextField("用户名", text: $username)
                    SecureField("密码", text: $password)
                    TextField("共享文件夹", text: $sharedFolder)
                }
                
                Section {
                    Button("测试连接") {
                        testConnection { success, message in
                            if success {
                                testResult = "连接成功"
                            } else {
                                testResult = message ?? "连接失败"
                            }
                        }
                    }
                    
                    if let result = testResult {
                        Text(result)
                            .foregroundColor(result == "连接成功" ? .green : .red)
                    }
                }
            }
            .navigationTitle("SMB设置")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        settings = SMBSettings(serverAddress: serverAddress,
                                               username: username,
                                               password: password,
                                               sharedFolder: sharedFolder)
                        if let encodedSettings = try? JSONEncoder().encode(settings) {
                            UserDefaults.standard.set(encodedSettings, forKey: "SMBSettings")
                        }
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
        }
    }
}