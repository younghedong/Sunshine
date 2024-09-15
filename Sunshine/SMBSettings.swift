struct SMBSettings: Codable {
    var serverAddress: String
    var username: String
    var password: String
    var sharedFolder: String
    
    enum CodingKeys: String, CodingKey {
        case serverAddress, username, sharedFolder
        case password // 不要直接编码密码
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        serverAddress = try container.decode(String.self, forKey: .serverAddress)
        username = try container.decode(String.self, forKey: .username)
        sharedFolder = try container.decode(String.self, forKey: .sharedFolder)
        password = "" // 从存储中加载时，不要尝试解码密码
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(serverAddress, forKey: .serverAddress)
        try container.encode(username, forKey: .username)
        try container.encode(sharedFolder, forKey: .sharedFolder)
        // 不要编码密码
    }
}