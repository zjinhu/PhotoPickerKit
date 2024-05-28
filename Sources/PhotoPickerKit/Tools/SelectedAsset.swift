//
//  SwiftUIView.swift
//
//
//  Created by HU on 2024/4/24.
//

import SwiftUI
import Photos

enum AssetSection{
    case main
}

public class SelectedAsset : Identifiable, Equatable, Hashable{
    
    public static func == (lhs: SelectedAsset, rhs: SelectedAsset) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public let id = UUID()
    public let asset: PHAsset
    
    public var isStatic: Bool = false

    /// 获取修改后Live Photo
    public var livePhoto: PHLivePhoto?
    /// 获取修改后视频URL或者Live Photo的视频URL
    public var videoUrl: URL?
    /// 获取修改后的图片
    public var image: UIImage?
    ///gif
    public var imageData: Data?
    public var gifVideoUrl: URL?

    public init(asset: PHAsset) {
        self.asset = asset
    }
    
    public var assetType: SelectedAssetType{
        
        if isStatic{
            return .image
        }
        
        if asset.isGIF(){
            return .gif
        }
        switch asset.mediaType {
        case .image:
            if asset.mediaSubtypes.contains(.photoLive) {
                return .livePhoto
            }
            return .image
        case .video:
            return .video
        default:
            return .unknown
        }
    }
    
    public enum SelectedAssetType{
        case image
        case livePhoto
        case video
        case gif
        case unknown
    }
    
    public func fetchPHAssetType() -> SelectedAssetType {
        
        if isStatic{
            return .image
        }
        
        if asset.isGIF(){
            return .gif
        }
        switch asset.mediaType {
        case .image:
            if asset.mediaSubtypes.contains(.photoLive) {
                return .livePhoto
            }
            return .image
        case .video:
            return .video
        default:
            return .unknown
        }
    }
}
