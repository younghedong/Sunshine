import Foundation
import AMSMB2

class SMBClient {
    private let client: AMSMB2
    private let settings: SMBSettings
    
    init(settings: SMBSettings) {
        self.settings = settings
        let smbURL = URL(string: "smb://\(settings.serverAddress)")!
        let credential = URLCredential(user: settings.username, password: settings.password, persistence: .forSession)
        self.client = AMSMB2(url: smbURL, credential: credential)!
    }
    
    func listDirectory(at path: String, completion: @escaping (Result<[FileItem], Error>) -> Void) {
        client.connectShare(name: settings.sharedFolder) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }
            
            self.client.contentsOfDirectory(atPath: path) { result in
                switch result {
                case .success(let items):
                    let fileItems = items.compactMap { item -> FileItem? in
                        guard let name = item.name else { return nil }
                        return FileItem(name: name,
                                        isDirectory: item.isDirectory,
                                        path: (path as NSString).appendingPathComponent(name))
                    }
                    completion(.success(fileItems))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}