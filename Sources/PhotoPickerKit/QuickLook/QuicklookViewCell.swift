//
//  QuicklookViewCell.swift
//  
//
//  Created by FunWidget on 2024/5/23.
//

import UIKit
import PhotosUI
import Photos
import Combine
import SwiftUI
class QuicklookCell: UICollectionViewCell{
    private var cancellables: Set<AnyCancellable> = []
 
    var asset: SelectedAsset?{
        didSet{
            if let asset = asset{
                photoModel = PhotoViewModel(asset: asset)
                
                photoModel?.$image
                    .receive(on: RunLoop.main)
                    .sink {[weak self] image in
                        self?.imageView.image = image
                    }.store(in: &cancellables)
                
                if let _ = photoModel?.image{ }else{
                    photoModel?.loadImage(size: .init(width: cellWidth, height: cellWidth))
                }
                
                if !isStatic, asset.asset.mediaSubtypes.contains(.photoLive){
                    liveView.isHidden = false
                }
                
                if asset.asset.isGIF(){
                    gifLabel.isHidden = false
                }
                
                if asset.asset.mediaType == .video {
                    photoModel?.$time
                        .receive(on: RunLoop.main)
                        .sink {[weak self] time in
                            if let time {
                                self?.videoView.isHidden = false
                                self?.videoView.setTitle(time.formatDuration(), for: .normal)
                            }
                        }.store(in: &cancellables)
                    
                    Task{
                        await self.photoModel?.onStart()
                    }
                }
            }
        }
    }
    
    var photoModel: PhotoViewModel?
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        return imageView
    }()
    
    lazy var liveView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "livephoto")
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    lazy var videoView: UIButton = {
        let view = UIButton()
        view.setImage(UIImage(systemName: "video"), for: .normal)
        //        view.imageView?.size = CGSize(width: 14, height: 14)
        view.imageEdgeInsets = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
        view.imageView?.contentMode = .scaleAspectFit
        view.titleLabel?.font = .systemFont(ofSize: 12)
        view.tintColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setInsets(forContentPadding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), imageTitlePadding: 5)
        view.isHidden = true
        return view
    }()
    
    lazy var gifLabel: UILabel = {
        let view = UILabel()
        view.text = "GIF"
        view.font = .systemFont(ofSize: 14, weight: .medium)
        view.textColor = .white
        view.textAlignment = .center
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 4
        view.isHidden = true
        return view
    }()
    
    var isStatic: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCellViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCellViews() {
        addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        addSubview(liveView)
        liveView.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        liveView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5).isActive = true
        liveView.widthAnchor.constraint(equalToConstant: 22).isActive = true
        liveView.heightAnchor.constraint(equalToConstant: 22).isActive = true
        
        addSubview(videoView)
        videoView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
        videoView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5).isActive = true
        videoView.heightAnchor.constraint(equalToConstant: 14).isActive = true
        
        addSubview(gifLabel)
        gifLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
        gifLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5).isActive = true
        gifLabel.heightAnchor.constraint(equalToConstant: 18).isActive = true
        gifLabel.widthAnchor.constraint(equalToConstant: 30).isActive = true
    }
}

class QuicklookImageCell: UICollectionViewCell{
    private var cancellables: Set<AnyCancellable> = []

    func setSelectedAsset(asset: SelectedAsset){
        if let ima = asset.image{
            self.imageView.image = ima
        }else{
            photoModel = PhotoViewModel(asset: asset)
            photoModel?.loadImage()
            photoModel?.$image
                .receive(on: RunLoop.main)
                .sink {[weak self] image in
                    self?.imageView.image = image
                }.store(in: &cancellables)
        }
    }
    
    var photoModel: PhotoViewModel?
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCellViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCellViews() {
        addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
}

class QuicklookGifCell: UICollectionViewCell {
    private var cancellables: Set<AnyCancellable> = []
 
    func setSelectedAsset(asset: SelectedAsset){
        if let imageData = asset.imageData{
            gifView.setImageData(data: imageData)
        }else{
            photoModel = GifViewModel(asset: asset)
            photoModel?.loadImageData()
            photoModel?.$imageData
                .receive(on: RunLoop.main)
                .sink {[weak self] imageData in
                    guard let imageData = imageData else { return }
                    self?.gifView.setImageData(data: imageData)
                }.store(in: &cancellables)
        }
    }
    
    var photoModel: GifViewModel?
    
    lazy var gifView: UIGIFImageView = {
        let gifView = UIGIFImageView()
        gifView.contentMode = .scaleAspectFit
        gifView.translatesAutoresizingMaskIntoConstraints = false
        gifView.clipsToBounds = true
        return gifView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCellViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCellViews() {
        addSubview(gifView)
        gifView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        gifView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        gifView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        gifView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        let view = UIButton()
        addSubview(view)
        view.frame = self.bounds
//        view.addTarget(self, action: #selector(didBtn(button:)), for: .touchUpInside)
    }
    
//    @objc
//    func didBtn(button: UIButton) {
//        if gifView.isAnimating{
//            gifView.stopAnimating()
//        }else{
//            gifView.startAnimating()
//        }
//    }
}

class QuicklookLivePhotoCell: UICollectionViewCell {
    private var cancellables: Set<AnyCancellable> = []
    func setSelectedAsset(asset: SelectedAsset){
        if let live = asset.livePhoto{
            self.livePhotoView.livePhoto = live
        }else{
            photoModel = LivePhotoViewModel(asset: asset)
            photoModel?.loadAsset()
            photoModel?.$livePhoto
                .receive(on: RunLoop.main)
                .sink {[weak self] livePhoto in
                    self?.livePhotoView.livePhoto = livePhoto
                }.store(in: &cancellables)
        }
    }
    
    var photoModel: LivePhotoViewModel?
    
    lazy var livePhotoView: PHLivePhotoView = {
        let livePhotoView = PHLivePhotoView()
        livePhotoView.clipsToBounds = true
        livePhotoView.translatesAutoresizingMaskIntoConstraints = false
        return livePhotoView
    }()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "livephoto")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCellViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCellViews() {
        addSubview(livePhotoView)
        livePhotoView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        livePhotoView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        livePhotoView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        livePhotoView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
    }
}

class QuicklookVideoCell: UICollectionViewCell {
    
    private var cancellables: Set<AnyCancellable> = []
    func setSelectedAsset(asset: SelectedAsset){
        if let url = asset.videoUrl{
            photoModel?.playerItem = AVPlayerItem(url: url)
        }else{
            photoModel = VideoViewModel(asset: asset)
            
            Task{
                await photoModel?.loadAsset()
            }
            
            photoModel?.$playerItem
                .receive(on: RunLoop.main)
                .sink {[weak self] playerItem in
                    self?.player.replaceCurrentItem(with: playerItem)
                }.store(in: &cancellables)
        }
    }
    
    var photoModel: VideoViewModel?
    
    var isPlaying: Bool = false{
        didSet{
            playButton.isHidden = isPlaying
        }
    }
    
    lazy var player = AVPlayer()
    
    lazy var videoView: PlayerUIView = {
        let videoView = PlayerUIView()
        videoView.configure(with: player)
        videoView.translatesAutoresizingMaskIntoConstraints = false
        videoView.clipsToBounds = true
        return videoView
    }()
    
    lazy var playButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "play"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(playVideo), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 15, bottom: 12, right: 15)
        button.backgroundColor = .black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 8
        return button
    }()
    
    @objc
    func playVideo(){
        player.play()
        isPlaying = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCellViews()
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { [self] _ in
            self.isPlaying = false
            self.player.seek(to: .zero) 
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCellViews() {
        addSubview(videoView)
        videoView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        videoView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        videoView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        videoView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        addSubview(playButton)
        playButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        playButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
}

class PlayerUIView: UIView {
    private var playerLayer: AVPlayerLayer?
    
    // 初始化并设置AVPlayer
    func configure(with player: AVPlayer) {
        if playerLayer == nil {
            playerLayer = AVPlayerLayer(player: player)
            layer.addSublayer(playerLayer!)
        } else {
            playerLayer?.player = player
        }
        playerLayer?.frame = bounds
        playerLayer?.videoGravity = .resizeAspect
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
}

