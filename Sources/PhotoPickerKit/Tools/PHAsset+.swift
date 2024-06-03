//
//  File.swift
//
//
//  Created by HU on 2024/4/29.
//

import Foundation
import Photos
import UIKit
public extension PHAsset{
    
    /// 单次使用，不要频繁调用，尤其是列表或者循环中
    func toImage(size: CGSize = .zero,
                 mode: PHImageContentMode = .default) -> UIImage? {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        var image: UIImage?
        options.isSynchronous = true
        
        var requestSize: CGSize
        if size == .zero{
            requestSize = CGSize(width: UIScreen.main.bounds.size.width * UIScreen.main.scale, height: UIScreen.main.bounds.size.height * UIScreen.main.scale)
        }else{
            requestSize = CGSize(width: size.width * UIScreen.main.scale, height: size.height * UIScreen.main.scale)
        }
        
        PHCachingImageManager.default().requestImage(for: self, targetSize: requestSize, contentMode: mode, options: options) { result, info in
            image = result
        }
        return image
    }
    
    @discardableResult
    func getImage(size: CGSize = .zero,
                  mode: PHImageContentMode = .aspectFill,
                  resultClosure: @escaping (UIImage?)->()) -> PHImageRequestID{
        
        
        let options = PHImageRequestOptions()
        
        var requestSize: CGSize
        
        if size == .zero{
            requestSize = PHImageManagerMaximumSize
        }else{
            requestSize = CGSize(width: size.width * UIScreen.main.scale,
                                 height: size.height * UIScreen.main.scale)
            options.resizeMode = .exact
        }
        
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        
        return PHCachingImageManager.default().requestImage(
            for: self,
            targetSize: requestSize,
            contentMode: mode,
            options: options,
            resultHandler: { image, info in
                resultClosure(image) // called for every quality approximation
            }
        )
    }
    
    /// 单次使用，不要频繁调用，尤其是列表或者循环中
    func toImageData() -> Data? {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        var imageData: Data?
        options.isSynchronous = true
 
        PHCachingImageManager.default().requestImageDataAndOrientation(for: self, options: options) { data, _, _, _ in
            imageData = data
        }
        return imageData
    }
    
    @discardableResult
    func getImageData(_ resultClosure: @escaping (Data?)->()) -> PHImageRequestID{

        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        
        return PHCachingImageManager.default().requestImageDataAndOrientation(
            for: self,
            options: options,
            resultHandler: { imageData, _, _, _  in
                resultClosure(imageData)
            }
        )
    }
    
    func getLivePhoto(size: CGSize = PHImageManagerMaximumSize,
                       mode: PHImageContentMode = .default,
                       resultClosure: @escaping (PHLivePhoto?)->()) -> PHImageRequestID {
        
        let options = PHLivePhotoRequestOptions()
        options.isNetworkAccessAllowed = true      // 允许从iCloud下载
        options.deliveryMode = .opportunistic  // 请求高质量的Live Photo
        
        return PHCachingImageManager.default().requestLivePhoto(for: self,
                                                                targetSize: size,
                                                                contentMode: mode,
                                                                options: options) { live, info in
            resultClosure(live)
        }
        
    }
    
    func getLivePhoto(size: CGSize = PHImageManagerMaximumSize,
                      mode: PHImageContentMode = .default) async -> PHLivePhoto? {
        
        let options = PHLivePhotoRequestOptions()
        options.isNetworkAccessAllowed = true      // 允许从iCloud下载
        options.deliveryMode = .opportunistic  // 请求高质量的Live Photo
        
        return await withCheckedContinuation { continuation in
            PHCachingImageManager.default().requestLivePhoto(for: self,
                                                             targetSize: size,
                                                             contentMode: mode,
                                                             options: options) { live, info in
                if let live = live {
                    continuation.resume(returning: live)
                }else{
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    
    func getLivePhotoVideoUrl(size: CGSize = .zero,
                              mode: PHImageContentMode = .default,
                              completion: @escaping (URL?) -> Void) {
        var didResume = false
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        
        var requestSize: CGSize
        if size == .zero{
            requestSize = CGSize(width: UIScreen.main.bounds.size.width * UIScreen.main.scale, height: UIScreen.main.bounds.size.height * UIScreen.main.scale)
        }else{
            requestSize = CGSize(width: size.width * UIScreen.main.scale, height: size.height * UIScreen.main.scale)
        }
        
        PHCachingImageManager.default().requestLivePhoto(for: self,
                                                         targetSize: requestSize,
                                                         contentMode: mode,
                                                         options: options) { (livePhoto, info) in
            guard let livePhoto = livePhoto,
                  let assetResources = PHAssetResource.assetResources(for: livePhoto) as? [PHAssetResource],
                  let videoResource = assetResources.first(where: { $0.type == .pairedVideo }) else {
                completion(nil)
                return
            }
            
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            
            let temporaryDirectoryURL = FileManager.default.temporaryDirectory
            let videoFileURL = temporaryDirectoryURL.appendingPathComponent(videoResource.originalFilename)
            try? FileManager.default.removeItem(at: videoFileURL)
            
            PHAssetResourceManager.default().writeData(for: videoResource, toFile: videoFileURL, options: options) { error in
                if didResume {
                    return
                }
                didResume = true
                if let error = error {
                    print("Error writing video data: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    completion(videoFileURL)
                }
            }
            
        }
    }
    
    func getPlayerItem() async -> AVPlayerItem? {
        
        let options = PHVideoRequestOptions()
        options.version = .current
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true
        
        return await withCheckedContinuation { continuation in
            PHCachingImageManager.default().requestPlayerItem(forVideo: self, options: options) { playerItem, info in
                if let playerItem = playerItem {
                    continuation.resume(returning: playerItem)
                }else{
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    func getVideoTime() async -> Double {
        
        let options = PHVideoRequestOptions()
        options.version = .current
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true
        
        return await withCheckedContinuation { continuation in
            PHCachingImageManager.default().requestAVAsset(forVideo: self, options: options) { (avAsset, audioMix, info) in
                if let avAsset = avAsset as? AVURLAsset {
                    let duration = CMTimeGetSeconds(avAsset.duration)
                    continuation.resume(returning: duration)
                }else{
                    continuation.resume(returning: 0)
                }
            }
        }
    }
    
    func getVideoUrl() async -> URL? {
        
        let options = PHVideoRequestOptions()
        options.version = .original
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true
        
        return await withCheckedContinuation { continuation in
            PHCachingImageManager.default().requestAVAsset(forVideo: self, options: options) { avAsset, _, _ in
                if let urlAsset = avAsset as? AVURLAsset {
                    continuation.resume(returning: urlAsset.url)
                }else{
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func getVideoUrl(_ completion: @escaping (URL?) -> Void) {
        let options = PHVideoRequestOptions()
        options.version = .original
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true
        
        PHCachingImageManager.default().requestAVAsset(forVideo: self, options: options) { avAsset, _, _ in
            if let urlAsset = avAsset as? AVURLAsset {
                completion(urlAsset.url)
            }else{
                completion(nil)
            }
        }
    }

    func isGIF() -> Bool {
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        
        let resources = PHAssetResource.assetResources(for: self)
        for resource in resources {
            if resource.uniformTypeIdentifier == "com.compuserve.gif" {
                return true
            }
        }
        return false
    }

}
