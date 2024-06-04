//
//  EditorViewController+LoadAsset.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/20.
//

import UIKit
import AVFoundation

extension EditViewController {
    
    enum LoadAssetStatus {
        case loadding(Bool = false)
        case succeed(EditorAsset.AssetType)
        case failure
    }
    
    func initAsset() {
        let asset = selectedAsset
        initAssetType(asset.type)
    }
    func initAssetType(_ type: EditorAsset.AssetType) {
        let viewSize = UIDevice.screenSize
        switch type {
        case .image(let image):
            if !isTransitionCompletion {
                loadAssetStatus = .succeed(.image(image))
                return
            }
            editorView.setImage(image)
            DispatchQueue.global().async {
                self.loadThumbnailImage(image, viewSize: viewSize)
            }
            loadCompletion()
            loadLastEditedData()
        case .imageData(let imageData):
            if !isTransitionCompletion {
                loadAssetStatus = .succeed(.imageData(imageData))
                return
            }
            editorView.setImageData(imageData)
            let image = self.editorView.image
            DispatchQueue.global().async {
                self.loadThumbnailImage(image, viewSize: viewSize)
            }
            loadCompletion()
            loadLastEditedData()
        case .video(let url):
            if !isTransitionCompletion {
                loadAssetStatus = .succeed(.video(url))
                return
            }
            let avAsset = AVAsset(url: url)
            let image = avAsset.getImage(at: 0.1)
            editorView.setAVAsset(avAsset, coverImage: image)
            editorView.loadVideo(isPlay: false)
            loadCompletion()
            loadLastEditedData()
        case .videoAsset(let avAsset):
            if !isTransitionCompletion {
                loadAssetStatus = .succeed(.videoAsset(avAsset))
                return
            }
            let image = avAsset.getImage(at: 0.1)
            editorView.setAVAsset(avAsset, coverImage: image)
            editorView.loadVideo(isPlay: false)
            loadCompletion()
            loadLastEditedData()
        }
    }
    
    func loadLastEditedData() {
        guard let result = selectedAsset.result else {
            filtersViewDidLoad()
            return
        }
        switch result {
        case .image(let editedResult, _):
            editorView.setAdjustmentData(editedResult.data)
        case .video(let editedResult, let editedData):
            editorView.setAdjustmentData(editedResult.data)
            loadVideoCropTimeData(editedData.cropTime)
        }
        if !firstAppear {
            editorView.layoutSubviews()
            checkLastResultState()
        }
        if config.video.isAutoPlay, selectedAsset.contentType == .video {
            DispatchQueue.main.async {
                self.videoControlView.resetLineViewFrsme(at: self.videoControlView.startTime)
                self.editorView.seekVideo(to: self.videoControlView.startTime)
                self.editorView.playVideo()
                self.editorView.videoVolume = 1
            }
        }
    }
    
    func loadVideoCropTimeData(_ data: EditorVideoCropTime?) {
        guard let data = data else {
            return
        }
        videoControlInfo = data.controlInfo
        if !firstAppear {
            updateVideoControlInfo()
        }
        controlViewStartEndTime(at: .init(seconds: data.startTime, preferredTimescale: data.preferredTimescale))
        if !firstAppear {
            DispatchQueue.main.async {
                self.updateVideoTimeRange()
            }
        }
    }
    
    func loadVideoControl() {
        let asset = selectedAsset
        switch asset.type {
        case .video(let videoURL):
            videoControlView.layoutSubviews()
            videoControlView.loadData(.init(url: videoURL))
            updateVideoTimeRange()
            isLoadVideoControl = true
        default:
            break
        }
    }
    
    func loadThumbnailImage(_ image: UIImage?, viewSize: CGSize) {
        guard let image = image else {
            selectedThumbnailImage = selectedOriginalImage
            return
        }
        if selectedThumbnailImage == nil {
            selectedThumbnailImage = image
        }
    }
    
    func filtersViewDidLoad() {
        if editorView.type == .video {
            if let avAsset = editorView.avAsset {
                avAsset.getImage(at: 0.1) { _,_,_ in }
            }
        }
    }
    
    func loadCompletion() {
        isLoadCompletion = true
        if !isLoadVideoControl && !firstAppear {
            loadVideoControl()
        }
        if editorView.type == .image {
            selectedOriginalImage = editorView.image
        }else if editorView.type == .video {
            selectedOriginalImage = nil
            showVideoControlView()
        }
    }
    
    func checkLastResultState() {
        resetButton.isEnabled = isReset
        checkFinishButtonState()
    }
    
    func loadFailure(message: String = "视频获取失败!") {
        if isDismissed {
            return
        }
        PhotoTools.showConfirm(
            viewController: self,
            title: "提示",
            message: message,
            actionTitle: "确定"
        ) { [weak self] _ in
            self?.backClick(true)
        }
    }
}
