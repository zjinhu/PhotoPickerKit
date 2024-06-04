//
//  EditorModels.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/4/29.
//

import UIKit
import AVFoundation

public struct EditorVideoFactor {
    /// 时间区域
    public let timeRang: CMTimeRange
    /// 原始视频音量
    public let volume: Float
    /// 裁剪圆切或者自定义蒙版时，被遮住的部分的处理类型
    /// 可自定义颜色，毛玻璃效果统一为 .light
    public let maskType: EditorView.MaskType?
    /// 导出视频的分辨率
    public let preset: ExportPreset
    /// 导出视频的质量 [0-10]
    public let quality: Int
    public init(
        timeRang: CMTimeRange = .zero,
        volume: Float = 1,
        maskType: EditorView.MaskType? = nil,
        preset: ExportPreset,
        quality: Int
    ) {
        self.timeRang = timeRang
        self.volume = volume
        self.maskType = maskType
        self.preset = preset
        self.quality = quality
    }
}

extension EditorVideoFactor {
    
    func isEqual(_ facotr: EditorVideoFactor) -> Bool {
        if timeRang.start.seconds != facotr.timeRang.start.seconds {
            return false
        }
        if timeRang.duration.seconds != facotr.timeRang.duration.seconds {
            return false
        }
        if volume != facotr.volume {
            return false
        }
        if preset != facotr.preset {
            return false
        }
        if quality != facotr.quality {
            return false
        }
        return true
    }
}

public struct EditAdjustmentData: CustomStringConvertible {
    let content: Content
    let maskImage: UIImage?
    
    public var description: String {
        "data of adjustment."
    }
}

extension ImageEditedResult: Codable {
    enum CodingKeys: CodingKey {
        case image
        case urlConfig
        case imageType
        case data
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let imageData = try container.decode(Data.self, forKey: .image)
        image = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIImage.self, from: imageData)!
        urlConfig = try container.decode(EditorURLConfig.self, forKey: .urlConfig)
        imageType = try container.decode(ImageType.self, forKey: .imageType)
        data = try container.decode(EditAdjustmentData.self, forKey: .data)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let imageData = try NSKeyedArchiver.archivedData(withRootObject: image, requiringSecureCoding: false)
        try container.encode(imageData, forKey: .image)
        try container.encode(urlConfig, forKey: .urlConfig)
        try container.encode(imageType, forKey: .imageType)
        try container.encode(data, forKey: .data)
    }
}

extension VideoEditedResult: Codable {
    enum CodingKeys: CodingKey {
        case urlConfig
        case coverImage
        case fileSize
        case videoTime
        case videoDuration
        case data
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let imageData = try container.decode(Data.self, forKey: .coverImage)
        coverImage = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIImage.self, from: imageData)
        urlConfig = try container.decode(EditorURLConfig.self, forKey: .urlConfig)
        fileSize = try container.decode(Int.self, forKey: .fileSize)
        videoTime = try container.decode(String.self, forKey: .videoTime)
        videoDuration = try container.decode(TimeInterval.self, forKey: .videoDuration)
        data = try container.decode(EditAdjustmentData.self, forKey: .data)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let image = coverImage {
            let imageData = try NSKeyedArchiver.archivedData(withRootObject: image, requiringSecureCoding: false)
            try container.encode(imageData, forKey: .coverImage)
        }
        try container.encode(urlConfig, forKey: .urlConfig)
        try container.encode(fileSize, forKey: .fileSize)
        try container.encode(videoTime, forKey: .videoTime)
        try container.encode(videoDuration, forKey: .videoDuration)
        try container.encode(data, forKey: .data)
    }
}

extension EditAdjustmentData {
    struct Content: Codable {
        let editSize: CGSize
        let contentOffset: CGPoint
        let contentSize: CGSize
        let contentInset: UIEdgeInsets
        let mirrorViewTransform: CGAffineTransform
        let rotateViewTransform: CGAffineTransform
        let scrollViewTransform: CGAffineTransform
        let scrollViewZoomScale: CGFloat
        let controlScale: CGFloat
        let adjustedFactor: Adjusted?
        
        struct Adjusted: Codable {
            let angle: CGFloat
            let zoomScale: CGFloat
            let contentOffset: CGPoint
            let contentInset: UIEdgeInsets
            let maskRect: CGRect
            let transform: CGAffineTransform
            let rotateTransform: CGAffineTransform
            let mirrorTransform: CGAffineTransform
            
            let contentOffsetScale: CGPoint
            let min_zoom_scale: CGFloat
            let isRoundMask: Bool
            
            let ratioFactor: EditorControlView.Factor?
        }
    }
}

extension EditAdjustmentData: Codable {
    enum CodingKeys: CodingKey {
        case content
        case maskImage
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(Content.self, forKey: .content)
        let imageData = try? container.decode(Data.self, forKey: .maskImage)
        if let imageData = imageData {
            maskImage = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIImage.self, from: imageData)
        }else {
            maskImage = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        if let image = maskImage {
            let imageData = try NSKeyedArchiver.archivedData(withRootObject: image, requiringSecureCoding: false)
            try container.encode(imageData, forKey: .maskImage)
        }
    }
}
