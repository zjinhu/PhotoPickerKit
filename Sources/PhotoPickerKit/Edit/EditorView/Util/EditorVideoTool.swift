//
//  EditorVideoTool.swift
//  HXPhotoPicker
//
//  Created by Slience on 2023/3/15.
//

import UIKit
import AVFoundation

public class EditorVideoTool {
    
    let avAsset: AVAsset
    let outputURL: URL
    let factor: EditorVideoFactor
    let watermark: Watermark
    let cropFactor: EditorAdjusterView.CropFactor
    let maskType: EditorView.MaskType
    let filter: VideoCompositionFilter?
    let videoOrientation: EditorVideoOrientation
    init(
        avAsset: AVAsset,
        outputURL: URL,
        factor: EditorVideoFactor,
        watermark: Watermark,
        cropFactor: EditorAdjusterView.CropFactor,
        maskType: EditorView.MaskType,
        filter: VideoCompositionFilter? = nil
    ) {
        self.avAsset = avAsset
        videoOrientation = avAsset.videoOrientation
        self.outputURL = outputURL
        self.factor = factor
        self.watermark = watermark
        self.cropFactor = cropFactor
        self.maskType = maskType
        self.filter = filter
        audioMix = AVMutableAudioMix()
        mixComposition = AVMutableComposition()
    }
    
    public init(
        avAsset: AVAsset,
        outputURL: URL,
        factor: EditorVideoFactor,
        maskType: EditorView.MaskType,
        filter: VideoCompositionFilter?
    ) {
        self.avAsset = avAsset
        videoOrientation = avAsset.videoOrientation
        self.outputURL = outputURL
        self.factor = factor
        self.watermark = .init(layers: [], images: [])
        self.cropFactor = .empty
        self.maskType = maskType
        self.filter = filter
        audioMix = AVMutableAudioMix()
        mixComposition = AVMutableComposition()
    }
    
    public func export(
        progressHandler: ((CGFloat) -> Void)? = nil,
        completionHandler: @escaping (Result<URL, EditorError>) -> Void
    ) {
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
        if #available(iOS 15, *) {
            Task {
                do {
                    _ = try await avAsset.load(.duration)
                    await MainActor.run {
                        exprotHandler()
                    }
                } catch {
                    await MainActor.run {
                        self.completionHandler?(
                            .failure(EditorError.error(
                                type: .exportFailed,
                                message: "导出失败：" + error.localizedDescription
                            ))
                        )
                    }
                }
            }
        } else {
            avAsset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
                guard let self = self else {
                    return
                }
                DispatchQueue.main.async {
                    if self.avAsset.statusOfValue(forKey: "duration", error: nil) != .loaded {
                        self.completionHandler?(
                            .failure(EditorError.error(
                                type: .exportFailed,
                                message: "导出失败：时长获取失败"
                            ))
                        )
                        return
                    }
                    self.exprotHandler()
                }
            }
        }
    }
    
    public func cancelExport() {
        avAsset.cancelLoading()
        progressTimer?.invalidate()
        progressTimer = nil
        exportSession?.cancelExport()
        exportSession = nil
    }
    
    private var exportSession: AVAssetExportSession?
    private var completionHandler: ((Result<URL, EditorError>) -> Void)?
    private var progressHandler: ((CGFloat) -> Void)?
    private weak var progressTimer: Timer?
    
    private func exprotHandler() {
        do {
            let exportPresets = AVAssetExportSession.exportPresets(compatibleWith: avAsset)
            if !exportPresets.contains(factor.preset.name) {
                throw EditorError.error(type: .exportFailed, message: "设备不支持导出：" + factor.preset.name)
            }
            guard let videoTrack = avAsset.tracks(withMediaType: .video).first else {
                throw NSError(domain: "Video track is nil", code: 500, userInfo: nil)
            }
            var timeRang = factor.timeRang
            let videoTotalSeconds = videoTrack.timeRange.duration.seconds
            if timeRang.start.seconds + timeRang.duration.seconds > videoTotalSeconds {
                timeRang = CMTimeRange(
                    start: timeRang.start,
                    duration: CMTime(
                        seconds: videoTotalSeconds - timeRang.start.seconds,
                        preferredTimescale: timeRang.start.timescale
                    )
                )
            }
            let animationBeginTime: CFTimeInterval
            if timeRang == .zero {
                animationBeginTime = AVCoreAnimationBeginTimeAtZero
            }else {
                animationBeginTime = timeRang.start.seconds == 0 ?
                    AVCoreAnimationBeginTimeAtZero :
                    timeRang.start.seconds
            }
            try insertVideoTrack(
                for: videoTrack,
                beginTime: animationBeginTime,
                videoDuration: timeRang == .zero ? videoTotalSeconds : timeRang.duration.seconds
            )
            
            var addVideoComposition = false
            if videoComposition.renderSize.width > 0 {
                addVideoComposition = true
            }
            try insertAudioTrack(
                duration: videoTrack.timeRange.duration,
                timeRang: timeRang,
                audioTracks: avAsset.tracks(withMediaType: .audio)
            )
            guard let exportSession = AVAssetExportSession(
                asset: mixComposition,
                presetName: factor.preset.name
            ) else {
                throw EditorError.error(type: .exportFailed, message: "不支持导出该类型视频")
            }
            let supportedTypeArray = exportSession.supportedFileTypes
            exportSession.outputURL = outputURL
            if supportedTypeArray.contains(AVFileType.mp4) {
                exportSession.outputFileType = .mp4
            }else if supportedTypeArray.isEmpty {
                throw EditorError.error(type: .exportFailed, message: "不支持导出该类型视频")
            }else {
                exportSession.outputFileType = supportedTypeArray.first
            }
            exportSession.shouldOptimizeForNetworkUse = true
            if addVideoComposition {
                exportSession.videoComposition = videoComposition
            }
            if !audioMix.inputParameters.isEmpty {
                exportSession.audioMix = audioMix
            }
            if timeRang != .zero {
                exportSession.timeRange = timeRang
            }
            if factor.quality > 0 && factor.quality < 10 {
                let seconds = timeRang != .zero ? timeRang.duration.seconds : videoTotalSeconds
                var maxSize: Int?
                if let urlAsset = avAsset as? AVURLAsset {
                    let scale = Double(max(seconds / videoTotalSeconds, 0.4))
                    maxSize = Int(Double(urlAsset.url.fileSize) * scale)
                }
                exportSession.fileLengthLimit = fileLengthLimit(
                    seconds: seconds,
                    maxSize: maxSize
                )
            }
            DispatchQueue.global().async {
                exportSession.exportAsynchronously(completionHandler: {
                    DispatchQueue.main.async {
                        switch exportSession.status {
                        case .completed:
                            self.progressHandler?(1)
                            self.progressTimer?.invalidate()
                            self.progressTimer = nil
                            self.completionHandler?(.success(self.outputURL))
                        case .failed, .cancelled:
                            self.progressTimer?.invalidate()
                            self.progressTimer = nil
                            let errorString: String
                            if let error = exportSession.error {
                                errorString = "导出失败：" + error.localizedDescription
                            }else {
                                errorString = "导出失败，未知原因"
                            }
                            self.completionHandler?(.failure(EditorError.error(
                                type: exportSession.status == .cancelled ? .cancelled : .exportFailed,
                                message: errorString
                            )))
                        default: break
                        }
                    }
                })
            }
            
            progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] _ in
                self?.progressHandler?(CGFloat(exportSession.progress))
            })
            self.exportSession = exportSession
        } catch {
            completionHandler?(
                .failure(EditorError.error(
                    type: .exportFailed,
                    message: "导出失败：" + error.localizedDescription)
                )
            )
        }
    }
    
    func cropSize() {
        if !cropFactor.isClip {
            return
        }
        let width = videoComposition.renderSize.width * cropFactor.sizeRatio.x
        let height = videoComposition.renderSize.height * cropFactor.sizeRatio.y
        videoComposition.renderSize = .init(width: width, height: height)
    }
    
    
    var mixComposition: AVMutableComposition!
    var videoComposition: AVMutableVideoComposition!
    var audioMix: AVMutableAudioMix!
}

fileprivate extension EditorVideoTool {
    
    func insertVideoTrack(
        for videoTrack: AVAssetTrack,
        beginTime: CFTimeInterval,
        videoDuration: TimeInterval
    ) throws {
        let videoTimeRange = CMTimeRangeMake(
            start: .zero,
            duration: videoTrack.timeRange.duration
        )
        let compositionVideoTrack = mixComposition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )
        compositionVideoTrack?.preferredTransform = videoTrack.preferredTransform
        try compositionVideoTrack?.insertTimeRange(
            videoTimeRange,
            of: videoTrack,
            at: .zero
        )
        videoComposition = AVMutableVideoComposition(propertiesOf: mixComposition)
        adjustVideoOrientation()
        let renderSize = videoComposition.renderSize
        cropSize()
        videoComposition.customVideoCompositorClass = EditorVideoCompositor.self
        let watermarkLayerTrackID = addWatermark(
            renderSize: renderSize,
            beginTime: beginTime,
            videoDuration: videoDuration
        )
        
        var newInstructions: [AVVideoCompositionInstructionProtocol] = []
        for instruction in videoComposition.instructions where instruction is AVVideoCompositionInstruction {
            let videoInstruction = instruction as! AVVideoCompositionInstruction
            let layerInstructions = videoInstruction.layerInstructions
            var sourceTrackIDs: [NSValue] = []
            for layerInstruction in layerInstructions {
                sourceTrackIDs.append(layerInstruction.trackID as NSValue)
            }
            let newInstruction = VideoCompositionInstruction(
                sourceTrackIDs: sourceTrackIDs,
                watermarkTrackID: watermarkLayerTrackID,
                timeRange: instruction.timeRange,
                videoOrientation: videoOrientation,
                watermark: watermark,
                cropFactor: cropFactor,
                maskType: maskType,
                filter: filter
            )
            newInstructions.append(newInstruction)
        }
        if newInstructions.isEmpty {
            var sourceTrackIDs: [NSValue] = []
            sourceTrackIDs.append(videoTrack.trackID as NSValue)
            let newInstruction = VideoCompositionInstruction(
                sourceTrackIDs: sourceTrackIDs,
                watermarkTrackID: watermarkLayerTrackID,
                timeRange: videoTrack.timeRange,
                videoOrientation: videoOrientation,
                watermark: watermark,
                cropFactor: cropFactor,
                maskType: maskType,
                filter: filter
            )
            newInstructions.append(newInstruction)
        }
        
        videoComposition.instructions = newInstructions
        videoComposition.renderScale = 1
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
    }
    
    func addWatermark(
        renderSize: CGSize,
        beginTime: CFTimeInterval,
        videoDuration: TimeInterval
    ) -> CMPersistentTrackID? {
        if watermark.images.isEmpty && watermark.layers.isEmpty{
            return nil
        }
        let overlaySize = videoComposition.renderSize
        let bounds = CGRect(origin: .zero, size: renderSize)
        let overlaylayer = CALayer()
        let bgLayer = CALayer()
        for layer in watermark.layers {
            if let image = layer.convertedToImage() {
                layer.contents = nil
                let drawLayer = CALayer()
                drawLayer.contents = image.cgImage
                drawLayer.frame = bounds
                drawLayer.contentsScale = UIScreen._scale
                bgLayer.addSublayer(drawLayer)
            }
        }
        for image in watermark.images {
            let drawLayer = CALayer()
            drawLayer.contents = image.cgImage
            drawLayer.frame = bounds
            drawLayer.contentsScale = UIScreen._scale
            bgLayer.addSublayer(drawLayer)
        }

        if cropFactor.isClip {
            let contentLayer = CALayer()
            let width = renderSize.width * cropFactor.waterSizeRatio.x
            let height = renderSize.height * cropFactor.waterSizeRatio.y
            let centerX = renderSize.width * cropFactor.waterCenterRatio.x
            let centerY = renderSize.height * cropFactor.waterCenterRatio.y
            let x = centerX - width / 2
            let y = centerY - height / 2
            bgLayer.anchorPoint = .init(
                x: (x + overlaySize.width * 0.5) / bounds.width,
                y: (y + overlaySize.height * 0.5) / bounds.height
            )
            bgLayer.frame = .init(
                x: -x, y: -y,
                width: bounds.width, height: bounds.height
            )
            contentLayer.addSublayer(bgLayer)
            contentLayer.frame = .init(origin: .zero, size: overlaySize)
            bgLayer.transform = CATransform3DMakeRotation(cropFactor.angle.radians, 0, 0, 1)
            overlaylayer.addSublayer(contentLayer)
            contentLayer.transform = CATransform3DMakeScale(cropFactor.mirrorScale.x, cropFactor.mirrorScale.y, 1)
        }else {
            bgLayer.frame = bounds
            overlaylayer.addSublayer(bgLayer)
        }
        overlaylayer.isGeometryFlipped = true
        overlaylayer.frame = .init(origin: .zero, size: overlaySize)
        
        let trackID = avAsset.unusedTrackID()
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            additionalLayer: overlaylayer,
            asTrackID: trackID
        )
        return trackID
    }
    
    func insertAudioTrack(
        duration: CMTime,
        timeRang: CMTimeRange,
        audioTracks: [AVAssetTrack]
    ) throws {
        _ = CMTimeRangeMake(
            start: .zero,
            duration: duration
        )
        var audioInputParams: [AVMutableAudioMixInputParameters] = []
        for audioTrack in audioTracks {
            guard let track = mixComposition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else {
                continue
            }
            let audioTimeRange: CMTimeRange
            if duration.seconds < audioTrack.timeRange.duration.seconds {
                audioTimeRange = .init(start: .zero, duration: duration)
            }else {
                audioTimeRange = audioTrack.timeRange
            }
            try track.insertTimeRange(audioTimeRange, of: audioTrack, at: .zero)
            track.preferredTransform = audioTrack.preferredTransform
            let audioInputParam = AVMutableAudioMixInputParameters(track: track)
            audioInputParam.setVolume(factor.volume, at: .zero)
            audioInputParam.trackID = track.trackID
            audioInputParams.append(audioInputParam)
        }
 
        audioMix.inputParameters = audioInputParams
    }
    
    func adjustVideoOrientation() {
        let assetOrientation = videoOrientation
        guard assetOrientation != .landscapeRight else {
            return
        }
        guard let videoTrack = mixComposition.tracks(withMediaType: .video).first else {
            return
        }
        let naturalSize = videoTrack.naturalSize
        if assetOrientation == .portrait {
            videoComposition.renderSize = CGSize(width: naturalSize.height, height: naturalSize.width)
        } else if assetOrientation == .landscapeLeft {
            videoComposition.renderSize = CGSize(width: naturalSize.width, height: naturalSize.height)
        } else if assetOrientation == .portraitUpsideDown {
            videoComposition.renderSize = CGSize(width: naturalSize.height, height: naturalSize.width)
        }
    }
}

fileprivate extension EditorVideoTool {
    
    func fileLengthLimit(
        seconds: Double,
        maxSize: Int? = nil
    ) -> Int64 {
        if factor.quality > 0 {
            let quality = Double(min(factor.quality, 10))
            if let maxSize = maxSize {
                return Int64(Double(maxSize) * (quality / 10))
            }
            var ratioParam: Double = 0
            if factor.preset == .ratio_640x480 {
                ratioParam = 0.02
            }else if factor.preset == .ratio_960x540 {
                ratioParam = 0.04
            }else if factor.preset == .ratio_1280x720 {
                ratioParam = 0.08
            }
            return Int64(seconds * ratioParam * quality * 1000 * 1000)
        }
        return 0
    }

}

extension EditorVideoTool {
    struct Watermark {
        let layers: [CALayer]
        let images: [UIImage]
    }
}
