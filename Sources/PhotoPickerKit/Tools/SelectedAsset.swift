//
//  SwiftUIView.swift
//
//
//  Created by HU on 2024/4/24.
//

import SwiftUI
import Photos
import BrickKit

enum AssetSection{
    case main
}

public class SelectedAsset : Identifiable, Equatable, Hashable{

    public let asset: PHAsset

    public init(asset: PHAsset) {
        self.asset = asset
    }
    
    public var isStatic: Bool = false

    public var editResult: EditAssetResult?

    @discardableResult
    public func getOriginalSource() async -> SelectedAsset{
        
        if isStatic{
            if let ima = asset.toImage(){
                editType = EditAssetType.image(ima)
                return self
            }
        }
        
        switch fetchPHAssetType(){
        case .video:
            
            if let url = await asset.getVideoUrl(){
                editType = EditAssetType.video(url)
                return self
            }
            
        case .livePhoto:
            
            return await withCheckedContinuation { continuation in
                self.asset.getLivePhotoVideoUrl { url in
                    if let url {
                        self.editType = EditAssetType.livePhoto(url)
                    }
                    continuation.resume(returning: self)
                }
            }
            
        case .gif:
            
            return await withCheckedContinuation { continuation in
                if let imageData = self.asset.toImageData(){
                    GifTool.createVideoFromGif(gifData: imageData) { url in
                        if let url{
                            self.editType = EditAssetType.gif(url)
                        }
                        continuation.resume(returning: self)
                    }
                }else{
                    continuation.resume(returning: self)
                }
            }
            
        default:
            
            if let image = asset.toImage(){
                editType = EditAssetType.image(image)
                return self
            }
            
        }
        
        return self
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
            return .image
        }
    }
    
    public static func == (lhs: SelectedAsset, rhs: SelectedAsset) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public let id = UUID()
    
    var editType: EditAssetType?
    
    var assetType: SelectedAssetType{
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
            return .image
        }
    }

}


public enum SelectedAssetType{
    case image
    case livePhoto
    case video
    case gif
}

public enum EditAssetType{
    case image(UIImage)
    case livePhoto(URL)
    case video(URL)
    case gif(URL)
}

public enum EditAssetResult {
    case image(UIImage, Data)
    case video(URL)
    case gif(Data?)
    case livePhoto(PHLivePhoto?)
    
    public var image: UIImage? {
        switch self {
        case .image(let image, _):
            return image
        default:
            return nil
        }
    }
    
    public var imageData: Data? {
        switch self {
        case .image(_, let data):
            return data
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
    
    public var gifData: Data? {
        switch self {
        case .gif(let data):
            return data
        default:
            return nil
        }
    }
    
    public var livePhoto: PHLivePhoto? {
        switch self {
        case .livePhoto(let livePhoto):
            return livePhoto
        default:
            return nil
        }
    }
}
