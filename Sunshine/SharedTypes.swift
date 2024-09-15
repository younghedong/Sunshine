import Foundation

public struct FileItem: Identifiable {
    public let id = UUID()
    public let name: String
    public let isDirectory: Bool
    public let path: String
    
    public init(name: String, isDirectory: Bool, path: String) {
        self.name = name
        self.isDirectory = isDirectory
        self.path = path
    }
}

public struct SMBSettings: Codable {
    public var serverAddress: String
    public var username: String
    public var password: String
    public var sharedFolder: String
    
    public init(serverAddress: String, username: String, password: String, sharedFolder: String) {
        self.serverAddress = serverAddress
        self.username = username
        self.password = password
        self.sharedFolder = sharedFolder
    }
}

public struct ErrorWrapper: Identifiable {
    public let id = UUID()
    public let error: String
    
    public init(error: String) {
        self.error = error
    }
}

public struct IdentifiableURL: Identifiable {
    public let id = UUID()
    public let url: URL
    
    public init(url: URL) {
        self.url = url
    }
}