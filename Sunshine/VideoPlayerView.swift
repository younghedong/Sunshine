import SwiftUI
import TVVLCKit

struct VideoPlayerView: UIViewControllerRepresentable {
    let videoURL: URL
    
    func makeUIViewController(context: Context) -> VLCVideoViewController {
        return VLCVideoViewController(videoURL: videoURL)
    }
    
    func updateUIViewController(_ uiViewController: VLCVideoViewController, context: Context) {}
}

class VLCVideoViewController: UIViewController {
    private var mediaPlayer: VLCMediaPlayer!
        
    init(videoURL: URL) {
        super.init(nibName: nil, bundle: nil)
        print("Initializing VLCVideoViewController with URL: \(videoURL.absoluteString)")
        setupMediaPlayer(with: videoURL)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupMediaPlayer(with url: URL) {
        mediaPlayer = VLCMediaPlayer()
        let media = VLCMedia(url: url)
        media.addOption("--verbose=3")  // Increase verbosity for more detailed logs
        mediaPlayer.media = media
        mediaPlayer.drawable = view
        
        // Add error handling
        NotificationCenter.default.addObserver(self, selector: #selector(handleVLCError(_:)), name: NSNotification.Name(rawValue: "VLCMediaPlayerEncounteredError"), object: mediaPlayer)
        
        // Add state change handling
        NotificationCenter.default.addObserver(self, selector: #selector(handleVLCStateChange(_:)), name: NSNotification.Name(rawValue: "VLCMediaPlayerStateChanged"), object: mediaPlayer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("Starting video playback")
        mediaPlayer.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("Stopping video playback")
        mediaPlayer.stop()
    }
    
    @objc func handleVLCError(_ notification: Notification) {
        print("VLC Playback Error")
        if let media = mediaPlayer.media {
            print("Media URL: \(media.url?.absoluteString ?? "Unknown")")
            print("Media state: \(media.state.rawValue)")
        }
        print("Player state: \(mediaPlayer.state.rawValue)")
        
        // Print all available information from the notification
        if let userInfo = notification.userInfo {
            for (key, value) in userInfo {
                print("Error info - \(key): \(value)")
            }
        }
        
        // Log additional information that might be helpful
        if let mediaTrackInfo = mediaPlayer.media?.tracksInformation {
            print("Media track information: \(mediaTrackInfo)")
        }
        
        // Log more details about the media
        if let media = mediaPlayer.media {
            print("Media duration: \(media.length.intValue) ms")
            print("Media type: \(media.mediaType.rawValue)")
        }
        
        // Log the SMB URL details
        if let url = mediaPlayer.media?.url, url.scheme == "smb" {
            print("SMB URL components:")
            print("- Scheme: \(url.scheme ?? "N/A")")
            print("- Host: \(url.host ?? "N/A")")
            print("- Path: \(url.path)")
            print("- Query: \(url.query ?? "N/A")")
        }
    }
    
    @objc func handleVLCStateChange(_ notification: Notification) {
        print("VLC State Change: \(mediaPlayer.state.rawValue)")
        switch mediaPlayer.state {
        case .error:
            print("Player encountered an error")
            handleVLCError(notification)  // Call error handler to get more details
        case .opening:
            print("Opening media")
        case .buffering:
            print("Buffering")
        case .playing:
            print("Playing")
        case .paused:
            print("Paused")
        case .stopped:
            print("Stopped")
        case .ended:
            print("Playback ended")
        @unknown default:
            print("Unknown state")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
