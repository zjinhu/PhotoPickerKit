//
//  EditedResult.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/26.
//

import UIKit
import AVFoundation
 
public enum EditedResult {
    case image(ImageEditedResult, ImageEditedData)
    case video(VideoEditedResult, VideoEditedData)
    
    /// edited url
    /// 编辑后的地址
    public var url: URL {
        switch self {
        case .image(let imageEditedResult, _):
            return imageEditedResult.url
        case .video(let videoEditedResult, _):
            return videoEditedResult.url
        }
    }
    
    public var image: UIImage? {
        switch self {
        case .image(let imageEditedResult, _):
            return imageEditedResult.image
        case .video(let videoEditedResult, _):
            return videoEditedResult.coverImage
        }
    }
}

public struct ImageEditedData: Codable {
    
    
    /// clipping parameters
    /// 裁剪参数
    let cropSize: EditorCropSizeFator?
    
    public init(
        cropSize: EditorCropSizeFator?
    ) {
        self.cropSize = cropSize
    }
}

public struct VideoEditedData {

    /// Clipping Duration Parameters
    /// 裁剪时长参数
    public let cropTime: EditorVideoCropTime?

    /// clipping parameters
    /// 裁剪参数
    let cropSize: EditorCropSizeFator?
    
    init(
        cropTime: EditorVideoCropTime?,
        cropSize: EditorCropSizeFator?
    ) {
        self.cropTime = cropTime
        self.cropSize = cropSize
    }
}

public struct VideoEditedMusic: Codable {
    
    /// Whether to include the original video audio
    /// 是否包含原视频音频
    public let hasOriginalSound: Bool
    
    /// Original video volume
    /// 原视频音量
    public let videoSoundVolume: Float

    public init(
        hasOriginalSound: Bool,
        videoSoundVolume: Float
    ) {
        self.hasOriginalSound = hasOriginalSound
        self.videoSoundVolume = videoSoundVolume
    }
}

public struct EditorVideoCropTime: Codable {
    
    /// Edit start time
    /// 编辑的开始时间
    public let startTime: TimeInterval
    
    /// edit end time
    /// 编辑的结束时间
    public let endTime: TimeInterval
    
    public let preferredTimescale: Int32
    
    let controlInfo: EditorVideoControlInfo
}

public struct EditorCropSizeFator: Codable {
    /// 是否固定比例
    let isFixedRatio: Bool
    /// 裁剪框比例
    let aspectRatio: CGSize
    /// 角度刻度值
    let angle: CGFloat
    
    public init(isFixedRatio: Bool, aspectRatio: CGSize, angle: CGFloat) {
        self.isFixedRatio = isFixedRatio
        self.aspectRatio = aspectRatio
        self.angle = angle
    }
}
