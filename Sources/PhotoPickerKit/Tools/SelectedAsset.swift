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
    
    /// 获取修改后视频URL或者Live Photo的视频URL
    /// 编辑前gif livePhoto vide需要提供videoUrl才可进入逐帧编辑页面
    public var videoUrl: URL?
    /// 获取修改后的图片
    /// 编辑前需要提供image才可进入图片编辑页面
    public var image: UIImage?
    
    /// 获取修改后Live Photo
    public var livePhoto: PHLivePhoto?
    ///获取修改后的图片/gif
    public var imageData: Data?
    
    public var isStatic: Bool = false
    
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
    
    @discardableResult
    public func getOriginalSource(isStatic: Bool = false) async -> SelectedAsset{
        
        if isStatic{
            if let ima = asset.toImage(){
                image = ima
                return self
            }
        }
        
        switch fetchPHAssetType(){
        case .video:
            
            if let url = await self.asset.getVideoUrl(){
                self.videoUrl = url
                return self
            }
            
        case .livePhoto:
            
            return await withCheckedContinuation { continuation in
                self.asset.getLivePhotoVideoUrl { url in
                    if let url {
                        self.videoUrl = url
                        continuation.resume(returning: self)
                    }
                }
            }
            
        case .gif:
            
            return await withCheckedContinuation { continuation in
                if let imageData = self.asset.toImageData(){
                    GifTool.createVideoFromGif(gifData: imageData) { url in
                        self.videoUrl = url
                        continuation.resume(returning: self)
                    }
                }else{
                    continuation.resume(returning: self)
                }
            }
            
        default:
            
            if let image = self.asset.toImage(){
                self.image = image
                return self
            }
            
        }
        
        return self
    }
}
