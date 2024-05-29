//
//  PhotoLibraryService.swift
//  PhotoRooms
//
//  Created by HU on 2024/4/22.
//

import SwiftUI
import Photos
 
public class PhotoLibraryService: NSObject {
    static let shared = PhotoLibraryService()
    let photoLibrary: PHPhotoLibrary
 
    @Published var photoLibraryChange : PHChange?
    
    private override init() {
        self.photoLibrary = .shared()
        super.init()
        self.photoLibrary.register(self)
    }
}

public extension PhotoLibraryService {
    func savePhoto(for photoData: Data, withLivePhotoURL url: URL? = nil) async throws {
        guard photoLibraryPermissionStatus == .authorized else {
            throw PhotoLibraryError.photoLibraryDenied
        }
        
        do {
            try await photoLibrary.performChanges {
                let createRequest = PHAssetCreationRequest.forAsset()
                createRequest.addResource(with: .photo, data: photoData, options: nil)
                if let url {
                    let options = PHAssetResourceCreationOptions()
                    options.shouldMoveFile = true
                    createRequest.addResource(with: .pairedVideo, fileURL: url, options: options)
                }
            }
        } catch {
            throw PhotoLibraryError.photoSavingFailed
        }
    }
}

public extension PhotoLibraryService {
    var photoLibraryPermissionStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    @discardableResult
    func requestPhotoLibraryPermission() async -> PHAuthorizationStatus  {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }
    
    func requestPhotoLibraryPermission(_ handler: @escaping (PHAuthorizationStatus) -> Void){
        PHPhotoLibrary.requestAuthorization(for: .readWrite, handler: handler)
    }
}

extension PhotoLibraryService: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        photoLibraryChange = changeInstance
    }
}

enum PhotoLibraryError: LocalizedError {
    case photoNotFound
    case photoSavingFailed
    case photoLibraryDenied
    case photoLoadingFailed
    case unknownError
}

extension PhotoLibraryError {
    var errorDescription: String? {
        switch self {
        case .photoNotFound:
            return "Photo Not Found"
        case .photoSavingFailed:
            return "Photo Saving Failed"
        case .photoLibraryDenied:
            return "Photo Library Access Denied"
        case .photoLoadingFailed:
            return "Photo Loading Failed"
        case .unknownError:
            return "Unknown Error"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .photoNotFound:
            return "The photo is not found in the photo library."
        case .photoSavingFailed:
            return "Oops! There is an error occurred while saving a photo into the photo library."
        case .photoLibraryDenied:
            return "You need to allow the photo library access to save pictures you captured. Go to Settings and enable the photo library permission."
        case .photoLoadingFailed:
            return "Oops! There is an error occurred while loading a photo from the photo library."
        case .unknownError:
            return "Oops! The unknown error occurs."
        }
    }
}


extension PhotoLibraryService {
    
    func fetchAssetAllAlbums(options: PHFetchOptions, type: PHAssetMediaType? = nil) async -> [AlbumItem] {
        await withCheckedContinuation { (continuation: CheckedContinuation<[AlbumItem], Never>) in
            continuation.resume(returning: allAlbums(options: options, type: type))
        }
    }
    
    func fetchSmartAlbums(options: PHFetchOptions?) -> PHFetchResult<PHAssetCollection> {
        PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .any,
            options: options
        )
    }
    
    func fetchUserAlbums(options: PHFetchOptions?) -> PHFetchResult<PHAssetCollection> {
        PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: options
        )
    }
    
    func allAlbums(options: PHFetchOptions?, type: PHAssetMediaType? = nil) -> [AlbumItem] {
        
        let smartAlbums: PHFetchResult<PHAssetCollection> = fetchSmartAlbums(options: options)
        let userAlbums: PHFetchResult<PHAssetCollection> = fetchUserAlbums(options: options)
        let albums: [PHFetchResult<PHAssetCollection>] = [smartAlbums, userAlbums]
        var items : [AlbumItem] = []
        for result in albums {
            result.enumerateObjects { (collection, _, _) in
                if !collection.isKind(of: PHAssetCollection.self) {
                    return
                }
                if  collection.estimatedAssetCount <= 0 ||
                    collection.assetCollectionSubtype.rawValue == 205 ||
                    collection.assetCollectionSubtype.rawValue == 215 ||
                    collection.assetCollectionSubtype.rawValue == 217 ||
                    collection.assetCollectionSubtype.rawValue == 218 ||
                    collection.assetCollectionSubtype.rawValue == 212 ||
                    collection.assetCollectionSubtype.rawValue == 204 ||
                    collection.assetCollectionSubtype.rawValue == 1000000201 {
                    return
                }
                
                let fetchOptions = PHFetchOptions()
                fetchOptions.includeHiddenAssets = false
                fetchOptions.fetchLimit = 1
                if let type {
                    fetchOptions.predicate = NSPredicate(format: "mediaType == %d", type.rawValue)
                }
                let assetsFetchResult = PHAsset.fetchAssets(in: collection , options: fetchOptions)
                if assetsFetchResult.count <= 0{
                    return
                }
                
                let assetCollection = AlbumItem(
                    title: collection.localizedTitle,
                    collection: collection
                )
                items.append(assetCollection)
            }
        }
        return items
    }
}
