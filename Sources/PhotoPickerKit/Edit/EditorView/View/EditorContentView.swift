//
//  EditorContentView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/11/12.
//

import UIKit
import AVFoundation

protocol EditorContentViewDelegate: AnyObject {
    func contentView(_ contentView: EditorContentView, videoDidPlayAt time: CMTime)
    func contentView(_ contentView: EditorContentView, videoDidPauseAt time: CMTime)
    func contentView(videoReadyForDisplay contentView: EditorContentView)
    func contentView(_ contentView: EditorContentView, isPlaybackLikelyToKeepUp: Bool)
    func contentView(resetPlay contentView: EditorContentView)
    func contentView(_ contentView: EditorContentView, readyToPlay duration: CMTime)
    func contentView(_ contentView: EditorContentView, didChangedBuffer time: CMTime)
    func contentView(_ contentView: EditorContentView, didChangedTimeAt time: CMTime)

    func contentView(rotateVideo contentView: EditorContentView)
    func contentView(resetVideoRotate contentView: EditorContentView)
}

class EditorContentView: UIView {
    
    weak var delegate: EditorContentViewDelegate?
    
    var image: UIImage? {
        get {
            switch type {
            case .image:
                return imageView.image
            case .video:
                return videoView.coverImageView.image
            default:
                return nil
            }
        }
        set {
            type = .image
            imageView.setImage(newValue)
        }
    }
    
    var contentSize: CGSize {
        switch type {
        case .image:
            if let image = imageView.image {
                return image.size
            }
        case .video:
            if !videoView.videoSize.equalTo(.zero) {
                return videoView.videoSize
            }
        default:
            break
        }
        return .zero
    }
    
    var contentScale: CGFloat {
        switch type {
        case .image:
            if let image = imageView.image {
                return image.width / image.height
            }
        case .video:
            if let image = videoView.coverImageView.image {
                return image.width / image.height
            }
            if !videoView.videoSize.equalTo(.zero) {
                return videoView.videoSize.width / videoView.videoSize.height
            }
        default:
            break
        }
        return 0
    }
    
    var videoCover: UIImage? {
        get { videoView.coverImageView.image }
        set { videoView.coverImageView.image = newValue }
    }
    
    var imageData: Data? {
        get { nil }
        set {
            type = .image
            imageView.setImageData(newValue)
        }
    }
    
    var avAsset: AVAsset? {
        get { videoView.avAsset }
        set {
            type = .video
            videoView.avAsset = newValue
        }
    }
    
    var avPlayer: AVPlayer? {
        if type != .video {
            return nil
        }
        return videoView.player
    }
    
    var playerLayer: AVPlayerLayer? {
        if type != .video {
            return nil
        }
        return videoView.playerLayer
    }
    
    func getVideoDisplayerImage(at time: TimeInterval) -> UIImage? {
        videoView.getDisplayedImage(at: time)
    }
    
    var isVideoPlayToEndTimeAutoPlay: Bool {
        get { videoView.isPlayToEndTimeAutoPlay}
        set { videoView.isPlayToEndTimeAutoPlay = newValue }
    }
    
    /// 缩放比例
    var zoomScale: CGFloat = 1
    
    var type: EditorContentViewType = .unknown {
        willSet {
            if type == .video {
                videoView.clear()
            }
        }
        didSet {
            switch type {
            case .image:
                videoView.isHidden = true
                imageView.isHidden = false
            case .video:
                videoView.isHidden = false
                imageView.isHidden = true
            default:
                break
            }
        }
    }
    
    // MARK: initialize
    init() {
        super.init(frame: .zero)
        initViews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        if videoView.superview == self {
            if !bounds.size.equalTo(.zero) {
                videoView.frame = bounds
            }
        }
    }
    
    // MARK: SubViews
    var imageView: ImageView!
    var videoView: EditorVideoPlayerView!

    private func initViews() {
        imageView = ImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isHidden = true
        addSubview(imageView)

        videoView = EditorVideoPlayerView()
        videoView.size = UIDevice.screenSize
        videoView.delegate = self
        videoView.isHidden = true
        addSubview(videoView)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EditorContentView: EditorVideoPlayerViewDelegate {

    var isPlaying: Bool {
        videoView.isPlaying
    }
    
    var playTime: CMTime {
        videoView.playTime
    }
    var duration: CMTime {
        videoView.duration
    }
    var startTime: CMTime? {
        get { videoView.startTime }
        set {
            videoView.startTime = newValue
            if let startTime = videoView.startTime, let endTime = videoView.endTime {
                delegate?.contentView(
                    self,
                    readyToPlay: .init(seconds: endTime.seconds - startTime.seconds, preferredTimescale: 1000)
                )
            }else if let startTime = videoView.startTime {
                delegate?.contentView(
                    self,
                    readyToPlay: .init(seconds: duration.seconds - startTime.seconds, preferredTimescale: 1000)
                )
            }else if let endTime = videoView.endTime {
                delegate?.contentView(self, readyToPlay: endTime)
            }else {
                delegate?.contentView(self, readyToPlay: duration)
            }
        }
    }
    var endTime: CMTime? {
        get { videoView.endTime }
        set {
            videoView.endTime = newValue
            if let startTime = videoView.startTime, let endTime = videoView.endTime {
                delegate?.contentView(
                    self,
                    readyToPlay: .init(seconds: endTime.seconds - startTime.seconds, preferredTimescale: 1000)
                )
            }else if let startTime = videoView.startTime {
                delegate?.contentView(
                    self,
                    readyToPlay: .init(seconds: duration.seconds - startTime.seconds, preferredTimescale: 1000)
                )
            }else if let endTime = videoView.endTime {
                delegate?.contentView(self, readyToPlay: endTime)
            }else {
                delegate?.contentView(self, readyToPlay: duration)
            }
        }
    }
    var volume: CGFloat {
        get {
            videoView.volume
        }
        set {
            videoView.volume = newValue
        }
    }
    
    func loadAsset(isPlay: Bool, _ completion: ((Bool) -> Void)? = nil) {
        videoView.configAsset(isPlay: isPlay, completion)
    }
    func seek(to time: CMTime, isPlay: Bool, comletion: ((Bool) -> Void)? = nil) {
        videoView.seek(to: time, isPlay: isPlay, comletion: comletion)
    }
    func seek(to time: TimeInterval, isPlay: Bool, comletion: ((Bool) -> Void)? = nil) {
        videoView.seek(to: time, isPlay: isPlay, comletion: comletion)
    }
    func play() {
        videoView.play()
    }
    func pause() {
        videoView.pause()
    }
    func resetPlay(completion: ((CMTime) -> Void)? = nil) {
        videoView.resetPlay(completion: completion)
    }
    
    func playerView(_ playerView: EditorVideoPlayerView, didPlayAt time: CMTime) {
        delegate?.contentView(self, videoDidPlayAt: time)
    }
    
    func playerView(_ playerView: EditorVideoPlayerView, didPauseAt time: CMTime) {
        delegate?.contentView(self, videoDidPauseAt: time)
    }
    
    func playerView(readyForDisplay playerView: EditorVideoPlayerView) {
        delegate?.contentView(videoReadyForDisplay: self)
    }
    func playerView(_ playerView: EditorVideoPlayerView, isPlaybackLikelyToKeepUp: Bool) {
        delegate?.contentView(self, isPlaybackLikelyToKeepUp: isPlaybackLikelyToKeepUp)
    }
    func playerView(resetPlay playerView: EditorVideoPlayerView) {
        delegate?.contentView(resetPlay: self)
    }
    func playerView(_ playerView: EditorVideoPlayerView, readyToPlay duration: CMTime) {
        delegate?.contentView(self, readyToPlay: duration)
    }
    func playerView(_ playerView: EditorVideoPlayerView, didChangedBuffer time: CMTime) {
        delegate?.contentView(self, didChangedBuffer: time)
    }
    func playerView(_ playerView: EditorVideoPlayerView, didChangedTimeAt time: CMTime) {
        delegate?.contentView(self, didChangedTimeAt: time)
    }

}
