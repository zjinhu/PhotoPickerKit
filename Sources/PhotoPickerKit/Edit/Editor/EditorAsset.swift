//
//  EditorAsset.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/17.
//

import UIKit
import AVFoundation

public struct EditorAsset {
    
    /// edit object
    /// 编辑对象
    public let type: AssetType
    
    /// edit result
    /// 编辑结果
    public var result: EditedResult?
    
    public init(type: AssetType, result: EditedResult? = nil) {
        self.type = type
        self.result = result
    }
}

extension EditorAsset {
    public enum AssetType {
        case image(UIImage)
        case imageData(Data)
        case video(URL)
        case videoAsset(AVAsset)
         
        public var image: UIImage? {
            switch self {
            case .image(let image):
                return image
            default:
                return nil
            }
        }
        
        public var videoURL: URL? {
            switch self {
            case .video(let url):
                return url
            default:
                return nil
            }
        }

        public var contentType: EditorContentViewType {
            switch self {
            case .image, .imageData:
                return .image
            case .video, .videoAsset:
                return .video
            }
        }
    }
    
    public var contentType: EditorContentViewType {
        type.contentType
    }
}
