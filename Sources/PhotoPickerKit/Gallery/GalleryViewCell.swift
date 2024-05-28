//
//  GalleryViewCell.swift
//
//
//  Created by FunWidget on 2024/5/16.
//

import UIKit
import Photos
import Combine
import SwiftUI

class GalleryViewCell: UICollectionViewCell {
    var viewModel: GalleryModel?
    
    var asset: SelectedAsset?{
        didSet{
            if let asset = asset{
                photoModel = PhotoViewModel(asset: asset)
                photoModel?.$image
                    .receive(on: RunLoop.main)
                    .sink {[weak self] image in
                        self?.imageView.image = image
                 }.store(in: &cancellables)
                
                if let ima = photoModel?.image{
                    self.imageView.image = ima
                }else{
                    photoModel?.loadImage(size: .init(width: cellWidth, height: cellWidth))
                }
                
                numberLabel.isHidden = viewModel?.maxSelectionCount == 1
                
                if asset.asset.mediaSubtypes.contains(.photoLive){
                    liveView.isHidden = asset.isStatic
                }
                
                if asset.asset.isGIF(){
                    gifLabel.isHidden = asset.isStatic
                }
                
                if asset.asset.mediaType == .video {
                    photoModel?.$time
                        .receive(on: RunLoop.main)
                        .sink {[weak self] time in
                            if let time {
                                self?.videoView.isHidden = asset.isStatic
                                self?.videoView.setTitle(time.formatDuration(), for: .normal)
                            }
                     }.store(in: &cancellables)
                    
                    Task{
                        await self.photoModel?.onStart()
                    }
                }
                if viewModel?.maxSelectionCount != 1{
                    getPhotoStatus()
                }
            }
        }
    }
    
    var photoModel: PhotoViewModel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCellViews()
    }
    
    private var cancellables: Set<AnyCancellable> = []
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .gray.withAlphaComponent(0.3)
//        imageView.clipsToBounds = true
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
    
    lazy var coverSelectView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.backgroundColor = .black.withAlphaComponent(0.5)
        return view
    }()
    
    lazy var coverDisableView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.backgroundColor = .white.withAlphaComponent(0.5)
        return view
    }()
    
    lazy var numberLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 12)
        view.textColor = .white
        view.textAlignment = .center
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 10
        view.isHidden = true
        return view
    }()

    
    var isDisabled: Bool = false {
        didSet {
            if isDisabled {
                coverDisableView.isHidden = false
            } else {
                coverDisableView.isHidden = true
            }
        }
    }
    
    func setNumber(number: Int?){
        if let number{
            numberLabel.backgroundColor = Color.mainBlue.toUIColor()
            numberLabel.text = "\(number)"
            coverSelectView.isHidden = false
            coverDisableView.isHidden = true
        }else{
            numberLabel.backgroundColor = UIColor.black.withAlphaComponent(0.2)
            numberLabel.text = ""
            coverSelectView.isHidden = true
        }
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
        
        addSubview(coverSelectView)
        coverSelectView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        coverSelectView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        coverSelectView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        coverSelectView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        addSubview(coverDisableView)
        coverDisableView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        coverDisableView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        coverDisableView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        coverDisableView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        addSubview(numberLabel)
        numberLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        numberLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5).isActive = true
        numberLabel.widthAnchor.constraint(equalToConstant: 20).isActive = true
        numberLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
    
    func getPhotoStatus(){

        if let selectedAssets = viewModel?.selectedAssets,
           selectedAssets.count == viewModel?.maxSelectionCount{
            isDisabled = true
        }else{
            isDisabled = false
        }

        var number: Int?
        if  let selectedAssets = viewModel?.selectedAssets,
            selectedAssets.contains(where: { picture in picture.asset == asset?.asset }){
            let index = selectedAssets.firstIndex(where: { picture in picture.asset == asset?.asset}) ?? -1
            number = index + 1
        }else{
            number = nil
        }
        
        setNumber(number: number)
    }
}

extension UIButton {
    func setInsets(forContentPadding contentPadding: UIEdgeInsets, imageTitlePadding: CGFloat) {
        self.contentEdgeInsets = UIEdgeInsets(top: contentPadding.top, left: contentPadding.left, bottom: contentPadding.bottom, right: contentPadding.right + imageTitlePadding)
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: imageTitlePadding, bottom: 0, right: -imageTitlePadding)
    }
}
