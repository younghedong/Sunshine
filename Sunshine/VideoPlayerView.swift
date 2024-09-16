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
    private var videoView: UIView!
    private var progressBarView: ProgressBarView!
    private var hideControlsTimer: Timer?
    private var wasPlayingBeforeSeek: Bool = false
    private var isSeeking: Bool = false
    
    init(videoURL: URL) {
        super.init(nibName: nil, bundle: nil)
        setupMediaPlayer(with: videoURL)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupMediaPlayer(with url: URL) {
        videoView = UIView(frame: view.bounds)
        videoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(videoView)
        
        setupProgressBarView()
        
        mediaPlayer = VLCMediaPlayer()
        let media = VLCMedia(url: url)
        mediaPlayer.media = media
        mediaPlayer.delegate = self
        mediaPlayer.drawable = videoView
        
        mediaPlayer.videoAspectRatio = UnsafeMutablePointer<Int8>(mutating: ("" as NSString).utf8String)
        mediaPlayer.videoCropGeometry = UnsafeMutablePointer<Int8>(mutating: ("" as NSString).utf8String)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleVLCError(_:)), name: NSNotification.Name(rawValue: "VLCMediaPlayerEncounteredError"), object: mediaPlayer)
        NotificationCenter.default.addObserver(self, selector: #selector(handleVLCStateChange(_:)), name: NSNotification.Name(rawValue: "VLCMediaPlayerStateChanged"), object: mediaPlayer)
        
        setupGestureRecognizers()
    }
    
    private func setupProgressBarView() {
        progressBarView = ProgressBarView(frame: CGRect(x: 0, y: view.bounds.height - 100, width: view.bounds.width, height: 100))
        progressBarView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        progressBarView.alpha = 0
        view.addSubview(progressBarView)
    }
    
    private func setupGestureRecognizers() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        view.addGestureRecognizer(tapRecognizer)
        view.addGestureRecognizer(panRecognizer)
    }
    
    @objc private func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        toggleControlsVisibility()
    }
    
    @objc private func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: view)
        let progress = translation.x / view.bounds.width
        seek(byProgress: progress)
    }
    
    private func seek(byProgress progress: CGFloat) {
        guard let duration = mediaPlayer.media?.length.intValue else { return }
        let newTime = Int32(Float(duration) * Float(progress))
        mediaPlayer.time = VLCTime(int: newTime)
        mediaPlayer.drawable = videoView  // 强制更新视频帧
        updateProgressBar()
    }
    
    private func toggleControlsVisibility() {
        if progressBarView.alpha == 0 {
            showControls()
        } else {
            hideControls()
        }
    }
    
    private func showControls() {
        UIView.animate(withDuration: 0.3) {
            self.progressBarView.alpha = 1
        }
        resetHideControlsTimer()
    }
    
    private func hideControls() {
        UIView.animate(withDuration: 0.3) {
            self.progressBarView.alpha = 0
        }
        hideControlsTimer?.invalidate()
    }
    
    private func resetHideControlsTimer() {
        hideControlsTimer?.invalidate()
        hideControlsTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.hideControls()
        }
    }
    
    private func updateProgressBar() {
        guard let duration = mediaPlayer.media?.length.intValue else { return }
        let currentTime = mediaPlayer.time.intValue
        let progress = Float(currentTime) / Float(duration)
        progressBarView.setProgress(progress)
        progressBarView.setCurrentTime(formatTime(time: currentTime))
        progressBarView.setTotalTime(formatTime(time: duration))
        progressBarView.setPaused(!mediaPlayer.isPlaying)
    }
    
    private func formatTime(time: Int32) -> String {
        let totalSeconds = Int(time) / 1000
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let press = presses.first else { return }
        
        switch press.type {
        case .leftArrow, .rightArrow:
            showControls()
            if !isSeeking {
                wasPlayingBeforeSeek = mediaPlayer.isPlaying
                if wasPlayingBeforeSeek {
                    mediaPlayer.pause()
                }
                isSeeking = true
            }
            let seekInterval: Int32 = press.type == .leftArrow ? -10 : 10
            seek(byInterval: seekInterval)
        case .playPause:
            showControls()
            togglePlayPause()
        case .select:
            if !mediaPlayer.isPlaying {
                mediaPlayer.play()
                updateProgressBar()
            }
        default:
            super.pressesBegan(presses, with: event)
        }
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let press = presses.first else { return }
        
        switch press.type {
        case .leftArrow, .rightArrow:
            isSeeking = false
            if wasPlayingBeforeSeek {
                mediaPlayer.play()
            }
            updateProgressBar()
        default:
            super.pressesEnded(presses, with: event)
        }
    }
    
    private func seek(byInterval interval: Int32) {
        let currentTime = mediaPlayer.time.intValue
        let newTime = max(0, currentTime + interval * 1000)
        mediaPlayer.time = VLCTime(int: newTime)
        mediaPlayer.drawable = videoView  // 强制更新视频帧
        updateProgressBar()
    }
    
    private func togglePlayPause() {
        if mediaPlayer.isPlaying {
            mediaPlayer.pause()
        } else {
            mediaPlayer.play()
        }
        updateProgressBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mediaPlayer.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mediaPlayer.stop()
    }
    
    @objc func handleVLCError(_ notification: Notification) {
        print("VLC Playback Error")
        if let media = mediaPlayer.media {
            print("Media URL: \(media.url?.absoluteString ?? "Unknown")")
            print("Media state: \(media.state.rawValue)")
        }
        print("Player state: \(mediaPlayer.state.rawValue)")
    }
    
    @objc func handleVLCStateChange(_ notification: Notification) {
        print("VLC State Change: \(mediaPlayer.state.rawValue)")
        updateProgressBar()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension VLCVideoViewController: VLCMediaPlayerDelegate {
    func mediaPlayerStateChanged(_ aNotification: Notification) {
        updateProgressBar()
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        updateProgressBar()
    }
}

class ProgressBarView: UIView {
    private let progressBar = UIProgressView(progressViewStyle: .default)
    private let currentTimeLabel = UILabel()
    private let totalTimeLabel = UILabel()
    private let pauseIndicator = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .clear
        
        addSubview(progressBar)
        addSubview(currentTimeLabel)
        addSubview(totalTimeLabel)
        addSubview(pauseIndicator)
        
        progressBar.progressTintColor = .white
        progressBar.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        progressBar.transform = CGAffineTransform(scaleX: 1, y: 2.0)
        
        currentTimeLabel.textColor = .white
        totalTimeLabel.textColor = .white
        
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        totalTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        pauseIndicator.image = UIImage(systemName: "pause.fill")
        pauseIndicator.tintColor = .white
        pauseIndicator.contentMode = .scaleAspectFit
        pauseIndicator.isHidden = true
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        pauseIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            progressBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            progressBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            progressBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -60),
            progressBar.heightAnchor.constraint(equalToConstant: 8),
            
            currentTimeLabel.leadingAnchor.constraint(equalTo: progressBar.leadingAnchor),
            currentTimeLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 10),
            currentTimeLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10),
            
            totalTimeLabel.trailingAnchor.constraint(equalTo: progressBar.trailingAnchor),
            totalTimeLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 10),
            totalTimeLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10),
            
            pauseIndicator.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 10),
            pauseIndicator.centerYAnchor.constraint(equalTo: currentTimeLabel.centerYAnchor),
            pauseIndicator.widthAnchor.constraint(equalToConstant: 30),
            pauseIndicator.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    func setProgress(_ progress: Float) {
        progressBar.progress = progress
    }
    
    func setCurrentTime(_ time: String) {
        currentTimeLabel.text = time
        currentTimeLabel.sizeToFit()
    }
    
    func setTotalTime(_ time: String) {
        totalTimeLabel.text = "-\(time)"
        totalTimeLabel.sizeToFit()
    }
    
    func setPaused(_ isPaused: Bool) {
        pauseIndicator.isHidden = !isPaused
    }
}
