//
//  EditViewController+Processing.swift
//  Edit
//
//  Created by FunWidget on 2024/5/30.
//

import UIKit
import AVFoundation
import Photos

extension EditViewController {
    var isEdited: Bool {
        var isCropTime: Bool = false
        if selectedAsset.contentType == .video {
            if editorView.videoDuration.seconds != videoControlView.middleDuration {
                isCropTime = true
            }
        }
        
        var isCropSize: Bool = false
        if selectedAsset.contentType == .image {
            isCropSize = editorView.isCropedImage
        }else if selectedAsset.contentType == .video {
            isCropSize = editorView.isCropedVideo
        }
        
        return isCropTime || isCropSize
    }
}

extension EditViewController {
    func processing() {
        switch selectedAsset.contentType {
        case .image:
            imageProcessing()
        case .video:
            videoProcessing()
        default:
            break
        }
    }
    
    func imageProcessing() {
        if editorView.isCropedImage {
            PhotoManager.HUDView.show(with: "正在处理...", delay: 0, animated: true, addedTo: view)
            if editorView.isCropedImage {
                editorView.cropImage { [weak self] result in
                    guard let self = self else { return }
                    PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.view)
                    switch result {
                    case .success(let imageResult):
                        self.imageProcessCompletion(imageResult)
                    case .failure:
                        PhotoManager.HUDView.showInfo(with: "处理失败", delay: 1.5, animated: true, addedTo: self.view)
                    }
                }
            }else {
                imageFilterProcessing { [weak self] in
                    guard let self = self else {
                        return
                    }
                    PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.view)
                    guard let result = $0 else {
                        PhotoManager.HUDView.showInfo(with: "处理失败", delay: 1.5, animated: true, addedTo: self.view)
                        return
                    }
                    self.imageProcessCompletion(result)
                }
            }
        }else {
            editedResult = nil
            selectedAsset.result = nil
            delegate?.editorViewController(self, didFinish: selectedAsset)
            finishHandler?(selectedAsset, self)
            backClick()
        }
    }
    
    func imageFilterProcessing(completion: @escaping (ImageEditedResult?) -> Void) {
        guard let image = editorView.image else {
            completion(nil)
            return
        }
        PhotoTools.getImageData(image, queueLabel: "HXPhotoPicker.editor.ImageFilterProcessingQueue") {
            guard let imageData = $0 else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            let compressionQuality = PhotoTools.getCompressionQuality(CGFloat(imageData.count))
            PhotoTools.compressImageData(
                imageData,
                compressionQuality: compressionQuality,
                queueLabel: "HXPhotoPicker.editor.CompressImageFilterProcessingQueue"
            ) {
                guard let data = $0 else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                let urlConfig: EditorURLConfig
                if let config = self.config.urlConfig {
                    urlConfig = config
                }else {
                    let fileName = String.fileName(suffix: data.isGif ? "gif" : "png")
                    urlConfig = .init(fileName: fileName, type: .temp)
                }
                if PhotoTools.write(toFile: urlConfig.url, imageData: data) == nil {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                PhotoTools.compressImageData(
                    data,
                    compressionQuality: 0.3,
                    queueLabel: "HXPhotoPicker.editor.CompressThumbImageFilterProcessingQueue"
                ) { thumbData in
                    if let thumbData = thumbData,
                       let thumbnailImage = UIImage(data: thumbData) {
                        DispatchQueue.main.async {
                            completion(.init(
                                image: thumbnailImage,
                                urlConfig: urlConfig,
                                imageType: .normal,
                                data: nil
                            ))
                        }
                    }else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                }
            }
        }
    }
    
    func imageProcessCompletion(_ result: ImageEditedResult) {
        let imageEditedResult: ImageEditedData
        let aspectRatio = editorView.aspectRatio
        let isFixedRatio = editorView.isFixedRatio
        imageEditedResult = .init(
            cropSize: .init(
                isFixedRatio: isFixedRatio,
                aspectRatio: aspectRatio, 
                angle: 0
            )
        )
        let editedResult = EditedResult.image(result, imageEditedResult)
        self.editedResult = editedResult
        selectedAsset.result = editedResult
        delegate?.editorViewController(self, didFinish: selectedAsset)
        finishHandler?(selectedAsset, self)
        backClick()
    }
    
    func videoProcessing() {
        let isCropTime: Bool = editorView.videoDuration.seconds != videoControlView.middleDuration
        
        if editorView.isCropedVideo || isCropTime {
            let timeRange: CMTimeRange
            if isCropTime {
                timeRange = .init(start: videoControlView.startTime, end: videoControlView.endTime)
            }else {
                timeRange = .zero
            }
            
            let factor = EditorVideoFactor(
                timeRang: timeRange,
                maskType: config.cropSize.maskType,
                preset: config.video.preset,
                quality: config.video.quality
            )
            if editorView.isCropedVideo {
                let progressView = PhotoManager.HUDView.showProgress(with: "正在处理...", progress: 0, animated: true, addedTo: view)
                editorView.cropVideo(
                    factor: factor
                ) { [weak self] in
                    guard let self = self else {
                        return nil
                    }
                    return self.videoFilterHandler($0, at: $1)
                } progress: {
                    progressView?.setProgress($0)
                } completion: { [weak self] result in
                    guard let self = self else {
                        return
                    }
                    switch result {
                    case .success(let videoResult):
                        DispatchQueue.global(qos: .userInteractive).async {
                            DispatchQueue.main.async {
                                PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.view)
                                self.videoProcessCompletion(videoResult)
                            }
                        }
                    case .failure(let error):
                        PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.view)
                        if error.isCancel {
                            return
                        }
                        PhotoManager.HUDView.showInfo(with: "处理失败", delay: 1.5, animated: true, addedTo: self.view)
                    }
                }
            }else {
                if config.isIgnoreCropTimeWhenFixedCropSizeState {
                    if !isCropTime {
                        videoFilterProcessing(factor)
                    }else {
                        editedResult = nil
                        selectedAsset.result = nil
                        delegate?.editorViewController(self, didFinish: selectedAsset)
                        finishHandler?(selectedAsset, self)
                        backClick()
                    }
                }else {
                    videoFilterProcessing(factor)
                }
            }
        }else {
            editedResult = nil
            selectedAsset.result = nil
            delegate?.editorViewController(self, didFinish: selectedAsset)
            finishHandler?(selectedAsset, self)
            backClick()
        }
    }
    
    func videoFilterHandler(_ pixelBuffer: CVPixelBuffer, at time: CMTime) -> CVPixelBuffer? {
        _ = CIImage(cvPixelBuffer: pixelBuffer)
        _ = CGSize(
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer)
        )
        return nil
    }
    
    func videoFilterProcessing(_ factor: EditorVideoFactor) {
        guard let avAsset = editorView.avAsset else {
            PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.view)
            PhotoManager.HUDView.showInfo(with: "处理失败", delay: 1.5, animated: true, addedTo: self.view)
            return
        }
        let progressView = PhotoManager.HUDView.showProgress(with: "正在处理...", progress: 0, animated: true, addedTo: view)
        let urlConfig: EditorURLConfig
        if let _urlConfig = config.urlConfig {
            urlConfig = _urlConfig
        }else {
            urlConfig = .init(fileName: .fileName(suffix: "mp4"), type: .temp)
        }
        videoTool?.cancelExport()
        let videoTool = EditorVideoTool(
            avAsset: avAsset,
            outputURL: urlConfig.url,
            factor: factor,
            maskType: config.cropSize.maskType
        ) { [weak self] in
            guard let self = self else {
                return nil
            }
            return self.videoFilterHandler($0, at: $1)
        }
        videoTool.export {
            progressView?.setProgress($0)
        } completionHandler: { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success(let url):
                DispatchQueue.global(qos: .userInteractive).async {
                    let fileSize = url.fileSize
                    let videoDuration = PhotoTools.getVideoDuration(videoURL: url)
                    let coverImage = PhotoTools.getVideoThumbnailImage(videoURL: url, atTime: 0.1)
                    let videoTime = PhotoTools.transformVideoDurationToString(duration: videoDuration)
                    DispatchQueue.main.async {
                        PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.view)
                        self.videoProcessCompletion(
                            .init(
                                urlConfig: urlConfig,
                                coverImage: coverImage,
                                fileSize: fileSize,
                                videoTime: videoTime,
                                videoDuration: videoDuration,
                                data: nil
                            )
                        )
                    }
                }
            case .failure(let error):
                PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.view)
                if error.isCancel {
                    return
                }
                PhotoManager.HUDView.showInfo(with: "处理失败", delay: 1.5, animated: true, addedTo: self.view)
            }
        }
        self.videoTool = videoTool
    }
    
    func videoProcessCompletion(
        _ result: VideoEditedResult
    ) {
        let editedData: VideoEditedData
        let aspectRatio = editorView.aspectRatio
        let isFixedRatio = editorView.isFixedRatio
        var cropTime: EditorVideoCropTime?
        let isCropTime: Bool = editorView.videoDuration.seconds != videoControlView.middleDuration
        if isCropTime {
            cropTime = .init(
                startTime: videoControlView.startDuration,
                endTime: videoControlView.endDuration,
                preferredTimescale: videoControlView.startTime.timescale,
                controlInfo: videoControlView.controlInfo
            )
        }
        
        editedData = .init(
            cropTime: cropTime,
            cropSize: .init(
                isFixedRatio: isFixedRatio,
                aspectRatio: aspectRatio,
                angle: 0
            )
        )
        let editedResult = EditedResult.video(result, editedData)
        self.editedResult = editedResult
        selectedAsset.result = editedResult
        delegate?.editorViewController(self, didFinish: selectedAsset)
        finishHandler?(selectedAsset, self)
        //        delegate?.editorViewController(self, didFinish: [editedResult])
        backClick()
    }
}

extension EditViewController {
    
    func backClick(_ isCancel: Bool = false) {
        
        PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: view)
        removeVideo()
        if isCancel {
            isDismissed = true
            delegate?.editorViewController(didCancel: self)
            cancelHandler?(self)
        }
        if let assetRequestID = assetRequestID {
            PHImageManager.default().cancelImageRequest(assetRequestID)
        }
        if config.isAutoBack {
            if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            }else {
                dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension EditViewController {
    func startPlayVideo() {
        if videoControlView.startDuration == videoControlView.currentDuration {
            startPlayVideoTimer()
        }else {
            let timeInterval = videoControlView.endDuration - videoControlView.currentDuration
            if timeInterval.isNaN { return }
            videoPlayTimer = Timer.scheduledTimer(
                withTimeInterval: timeInterval,
                repeats: false,
                block: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    $0.invalidate()
                    if self.videoPlayTimer == nil || $0 != self.videoPlayTimer {
                        return
                    }
                    self.editorView.seekVideo(to: self.videoControlView.startTime)
                    self.startPlayVideoTimer()
                }
            )
        }
    }
    
    private func startPlayVideoTimer() {
        let timeInterval = videoControlView.middleDuration
        if timeInterval.isNaN { return }
        videoPlayTimer = Timer.scheduledTimer(
            withTimeInterval: timeInterval,
            repeats: true,
            block: { [weak self] in
                guard let self = self else {
                    return
                }
                if self.videoPlayTimer == nil || $0 != self.videoPlayTimer {
                    $0.invalidate()
                    return
                }
                self.editorView.seekVideo(to: self.videoControlView.startTime)
            }
        )
    }
    
    func stopPlayVideo() {
        videoPlayTimer?.invalidate()
        videoPlayTimer = nil
    }
}
