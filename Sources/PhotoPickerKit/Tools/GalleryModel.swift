//
//  GalleryViewModel.swift
//  PhotoRooms
//
//  Created by HU on 2024/4/23.
//
import Foundation
import Photos
import SwiftUI
import Combine

@MainActor
public class GalleryModel: ObservableObject {
    public let photoLibrary = PhotoLibraryService.shared
    @Published
    public var albums: [AlbumItem] = []
    public var maxSelectionCount: Int = 0
    @Published
    public var defaultSelectIndex: Int = 0
    @Published
    public var onSelectedDone: Bool = false
    @Published
    public var autoCrop: Bool = false
    @Published
    public var isStatic: Bool = false
    @Published 
    public var showQuicklook: Bool = false
    @Published
    public var showCrop: Bool = false
    
    @Published 
    public var permission: PhotoLibraryPermission = .denied
    @Published
    public var selectedAssets: [SelectedAsset] = []
    @Published
    public var showToast: Bool = false
    @Published
    public var cropRatio: CGSize = .zero
    @Published
    public var selectedAsset: SelectedAsset?
    
    @Published
    public var isPresentedEdit = false
    
    @Published
    public var previewSelectIndex: Int = 0
     
    private var subscribers: [AnyCancellable] = []
    var selectIndesPaths: [IndexPath] = []
    
    public init() {
        
        switch photoLibrary.photoLibraryPermissionStatus {
        case .restricted, .limited:
            permission = .limited
        case .authorized:
            permission = .authorized
        default:
            permission = .denied
            Task{
                await photoLibrary.requestPhotoLibraryPermission()
                await loadAllAlbums()
            }
        }

        photoLibrary.$photoLibraryChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] change in
                self?.bindLibraryUpdate(change: change)
            }
            .store(in: &subscribers)
        
    }
    
    public enum PhotoLibraryPermission {
        case denied
        case limited
        case authorized
    }
}

extension GalleryModel {
    func bindLibraryUpdate(change: PHChange?) {
        for item in albums{
            if let result = item.result, let changes = change?.changeDetails(for: result) {
                withAnimation {
                    item.result = changes.fetchResultAfterChanges
                }
            }
        }

    }
}

extension GalleryModel {

    public func loadAllAlbums() async {
        let options = PHFetchOptions()
//        options.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced, .typeCloudShared]
//        options.sortDescriptors = [NSSortDescriptor(key: "localizedTitle", ascending: true)]
        let albums = await photoLibrary.fetchAssetAllAlbums(options: options, type: isStatic ? .image : nil)
        
        await MainActor.run {
            withAnimation {
                self.albums = albums
            }
        }
    }
 
}

@MainActor
public class PhotoViewModel: ObservableObject {
    @Published
    public var image: UIImage?
    @Published
    public var time: Double?
    private var requestID: PHImageRequestID?
    private var currentTask: Task<Void, Never>?
    
    let asset: SelectedAsset
    let isStatic: Bool
    public init(asset: SelectedAsset, isStatic: Bool = false) {
        self.asset = asset
        self.isStatic = isStatic
    }
    
    public func loadImage(size: CGSize = .zero) {
        requestID = asset.asset.getImage(size: size) { [weak self] ima in
            self?.image = ima
        }
    }
    
    public func onStop() {
        currentTask = nil
        if let requestID = requestID {
            PHCachingImageManager.default().cancelImageRequest(requestID)
        }
    }
    
    public func onStart() async {
        if isStatic{ return }
        guard asset.asset.mediaType == .video else { return }

        currentTask?.cancel()
        currentTask = Task {
            time = await asset.asset.getVideoTime()
        }
    }
}

@MainActor
public class LivePhotoViewModel: ObservableObject {
    @Published
    public var livePhoto: PHLivePhoto?
 
    private var requestID: PHImageRequestID?
 
    let asset: SelectedAsset
 
    public init(asset: SelectedAsset) {
        self.asset = asset
    }
    
    public func loadAsset() {
        requestID =  asset.asset.loadLivePhoto(resultClosure: { [weak self] photo in
            self?.livePhoto = photo
        })
    }
    
    public func onStop() {
        if let requestID = requestID {
            PHCachingImageManager.default().cancelImageRequest(requestID)
        }
    }
 
}

@MainActor
public class GifViewModel: ObservableObject {
    @Published
    public var imageData: Data?
 
    private var requestID: PHImageRequestID?
    let asset: SelectedAsset
 
    public init(asset: SelectedAsset) {
        self.asset = asset
    }
    
    public func loadImageData() {
        requestID = asset.asset.getImageData({ [weak self] data in
            self?.imageData = data
        })
    }
    
    public func onStop() {
        if let requestID = requestID {
            PHCachingImageManager.default().cancelImageRequest(requestID)
        }
    }

}


@MainActor
public class VideoViewModel: ObservableObject {
    @Published
    public var playerItem: AVPlayerItem?

    let asset: SelectedAsset
 
    public init(asset: SelectedAsset) {
        self.asset = asset
    }
    
    public func loadAsset() async {
        playerItem = await asset.asset.getPlayerItem()
    }
}

//相簿列表项
public class AlbumItem: Identifiable{
    public let id = UUID()
    //相簿名称
    public var title: String?
    /// 相册里的资源数量
    public var count: Int = 0
    //相簿内的资源
    @Published
    public var result: PHFetchResult<PHAsset>?
    /// 相册对象
    public var collection: PHAssetCollection?
 
    public init(title: String?,
         collection: PHAssetCollection?) {
        self.collection = collection
        self.title = title
    }
   
    public func fetchResult(options: PHFetchOptions?) {
        guard let collection = collection  else {
            return
        }
        result = PHAsset.fetchAssets(in: collection, options: options)
        count = result?.count ?? 0
    }
}
 
