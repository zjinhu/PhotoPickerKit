//
//  SwiftUIView.swift
//
//
//  Created by HU on 2024/5/9.
//

import SwiftUI
import BrickKit
public struct EditView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    
    var cropRatio: CGSize
    var selectedAsset: SelectedAsset
    var editDone: (SelectedAsset) -> Void
    var cropVideoTime: TimeInterval
    var cropVideoFixTime: Bool
    public init(asset: SelectedAsset,
                cropVideoTime: TimeInterval = 5,
                cropVideoFixTime: Bool = false,
                cropRatio: CGSize = .zero,
                done: @escaping (SelectedAsset) -> Void) {
        self.selectedAsset = asset
        self.cropRatio = cropRatio
        self.editDone = done
        self.cropVideoTime = cropVideoTime
        self.cropVideoFixTime = cropVideoFixTime
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeUIViewController(context: Context) -> UIViewController {
        return makeCropper(context: context)
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
    
    public func makeCropper(context: Context) -> UIViewController {
        
        var config = EditorConfiguration()
        config.isFixedCropSizeState = true
        config.isAutoBack = false
        config.isIgnoreCropTimeWhenFixedCropSizeState = false
        config.cropSize.isShowScaleSize = false
        config.photo.defaultSelectedToolOption = .cropSize
        config.video.defaultSelectedToolOption = .cropSize
        config.video.cropTime.minimumTime = 1
        config.video.cropTime.maximumTime = cropVideoTime
        config.video.cropTime.isCanControlMove = !cropVideoFixTime
        if cropRatio != .zero{
            config.cropSize.isFixedRatio = true
            config.cropSize.aspectRatio = cropRatio
            config.cropSize.aspectRatios = []
        }else{
            config.cropSize.isFixedRatio = false
        }
        
        if let image = selectedAsset.image,
           selectedAsset.assetType == .image{
            let vc = EditorViewController(.init(type: .image(image)), config: config)
            vc.delegate = context.coordinator
            return vc
        }
        
        if let videoUrl = selectedAsset.videoUrl,
           selectedAsset.assetType == .video{
            let vc = EditorViewController(.init(type: .video(videoUrl)), config: config)
            vc.delegate = context.coordinator
            return vc
        }
        
        if let videoUrl = selectedAsset.videoUrl,
           selectedAsset.assetType == .livePhoto{
            let vc = EditorViewController(.init(type: .video(videoUrl)), config: config)
            vc.delegate = context.coordinator
            return vc
        }
        
        if let url = selectedAsset.gifVideoUrl,
           selectedAsset.assetType == .gif{
            let vc = EditorViewController(.init(type: .video(url)), config: config)
            vc.delegate = context.coordinator
            return vc
        }
        
        return UIViewController()
    }
    
    public class Coordinator: EditorViewControllerDelegate {
        var parent: EditView
        
        init(_ parent: EditView) {
            self.parent = parent
        }
        // MARK: - 编辑完成后制造数据
        /// 完成编辑
        /// - Parameters:
        ///   - editorViewController: 对应的 EditorViewController
        ///   - result: 编辑后的数据
        public func editorViewController(_ editorViewController: EditorViewController, didFinish asset: EditorAsset) {
            switch parent.selectedAsset.assetType {
            case .image:
                if let imageURL = asset.result?.url,
                   let imageData = try? Data(contentsOf: imageURL),
                   let image = UIImage(data: imageData){
                    parent.selectedAsset.image = image
                }else{
                    parent.selectedAsset.image = asset.result?.image
                }
                parent.editDone(parent.selectedAsset)
                parent.dismiss()
            case .livePhoto:
                
                let temporaryDirectoryURL = FileManager.default.temporaryDirectory
                let imageFileURL = temporaryDirectoryURL.appendingPathComponent("livephoto.png")
                try? FileManager.default.removeItem(at: imageFileURL)
                
                let imageData = asset.result?.image?.pngData()
                try? imageData?.write(to: imageFileURL)
                
                if let videoUrl = asset.result?.url{
                    LivePhoto.generate(from: imageFileURL, videoURL: videoUrl) { progress in
                        print("LivePhoto--\(progress)")
                    } completion: { live, res in
                        self.parent.selectedAsset.livePhoto = live
                        self.parent.selectedAsset.videoUrl = videoUrl
                        self.parent.editDone(self.parent.selectedAsset)
                        self.parent.dismiss()
                    }
                }
            case.video:
                switch asset.result{
                case .video(let result, _):
                    parent.selectedAsset.videoUrl = result.url
                    parent.editDone(parent.selectedAsset)
                    parent.dismiss()
                default:
                    break
                }
                
            case.gif:

                switch asset.result{
                case .video(let result, _):
                    GifTool.createGifData(from: result.url) { date in
                        self.parent.selectedAsset.imageData = date
                        self.parent.selectedAsset.gifVideoUrl = result.url
                        self.parent.editDone(self.parent.selectedAsset)
                        self.parent.dismiss()
                    }
                default:
                    break
                }
                
            default:
                break
            }
            
        }
        
        public func editorViewController(didCancel editorViewController: EditorViewController) {
            parent.dismiss()
        }
        
    }
}

