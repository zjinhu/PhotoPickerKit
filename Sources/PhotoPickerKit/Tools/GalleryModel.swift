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
class GalleryModel: ObservableObject {
    let photoLibrary = PhotoLibraryService.shared
    @Published var albums: [AlbumItem] = []
    var maxSelectionCount: Int = 0
    @Published var defaultSelectIndex: Int = 0
    @Published var onSelectedDone: Bool = false
    @Published var autoCrop: Bool = false
    @Published var isStatic: Bool = false
    @Published var showQuicklook: Bool = false
    @Published var showCrop: Bool = false
    
    @Published var permission: PhotoLibraryPermission = .denied
    @Published var selectedAssets: [SelectedAsset] = []
    @Published var showToast: Bool = false
    @Published var cropRatio: CGSize = .zero
    @Published var selectedAsset: SelectedAsset?
    
    @Published var isPresentedEdit = false
    @Published var previewSelectIndex: Int = 0
    
    @Published var resetVideoStatus = false
    
    private var subscribers: [AnyCancellable] = []
    var selectIndesPaths: [IndexPath] = []
    
    init() {
        
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
    
    enum PhotoLibraryPermission {
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

    func loadAllAlbums() async {
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
    @Published public var image: UIImage?
    @Published public var time: Double?
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
        requestID =  asset.asset.getLivePhoto(resultClosure: { [weak self] photo in
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
class AlbumItem: Identifiable{
    let id = UUID()
    //相簿名称
    var title: String?
    /// 相册里的资源数量
    var count: Int = 0
    //相簿内的资源
    @Published
    var result: PHFetchResult<PHAsset>?
    /// 相册对象
    var collection: PHAssetCollection?
 
    init(title: String?,
         collection: PHAssetCollection?) {
        self.collection = collection
        self.title = title
    }
   
    func fetchResult(options: PHFetchOptions?) {
        guard let collection = collection  else {
            return
        }
        result = PHAsset.fetchAssets(in: collection, options: options)
        count = result?.count ?? 0
    }
}
 
