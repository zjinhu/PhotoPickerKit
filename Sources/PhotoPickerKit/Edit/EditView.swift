//
//  SwiftUIView.swift
//
//
//  Created by HU on 2024/5/9.
//

import SwiftUI
import BrickKit
struct EditView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    
    var cropRatio: CGSize
    var selectedAsset: SelectedAsset
    var editDone: (SelectedAsset) -> Void
    var cropVideoTime: TimeInterval
    var cropVideoFixTime: Bool
    init(asset: SelectedAsset,
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
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        return makeCropper(context: context)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
    
    func makeCropper(context: Context) -> UIViewController {
        
        var config = EditorConfiguration()
        config.isAutoBack = false
        config.isIgnoreCropTimeWhenFixedCropSizeState = false
        config.cropSize.isShowScaleSize = false
        config.video.cropTime.isCanControlMove = !cropVideoFixTime
        if cropRatio != .zero{
            config.cropSize.isFixedRatio = true
            config.cropSize.aspectRatio = cropRatio
        }else{
            config.cropSize.isFixedRatio = false
        }

        if let type = selectedAsset.editType{
            switch type {
            case .image(let uIImage):
                let vc = EditViewController(.init(type: .image(uIImage)), config: config)
                vc.delegate = context.coordinator
                return vc
            case .livePhoto(let uRL):
                config.video.cropTime.minimumTime = 1.5
                config.video.cropTime.maximumTime = max(1.5, cropVideoTime)
                let vc = EditViewController(.init(type: .video(uRL)), config: config)
                vc.delegate = context.coordinator
                return vc
            case .video(let uRL), .gif(let uRL):
                config.video.cropTime.minimumTime = 1
                config.video.cropTime.maximumTime = cropVideoTime
                let vc = EditViewController(.init(type: .video(uRL)), config: config)
                vc.delegate = context.coordinator
                return vc
            }
        }

        return UIViewController()
    }
    
    class Coordinator: EditViewControllerDelegate {
        var parent: EditView
        
        init(_ parent: EditView) {
            self.parent = parent
        }
        // MARK: - 编辑完成后制造数据
        /// 完成编辑
        /// - Parameters:
        ///   - editorViewController: 对应的 EditorViewController
        ///   - result: 编辑后的数据
        func editorViewController(_ editorViewController: EditViewController, didFinish asset: EditorAsset) {

            switch parent.selectedAsset.assetType {

            case .livePhoto:

                switch asset.result{
                case .video(let result, _):
                    LivePhoto.generate(videoURL: result.url) { progress in
                        print("LivePhoto--\(progress)")
                    } completion: { live, res in
                        let type = EditAssetResult.livePhoto(live)
                        self.parent.selectedAsset.editResult = type
                        self.parent.editDone(self.parent.selectedAsset)
                        self.parent.dismiss()
                    }
                default:
                    break
                }

            case.video:
                switch asset.result{
                case .video(let result, _):
                    let type = EditAssetResult.video(result.url)
                    parent.selectedAsset.editResult = type
                    parent.editDone(parent.selectedAsset)
                    parent.dismiss()
                default:
                    break
                }
                
            case .gif:

                switch asset.result{
                case .video(let result, _):
                    GifTool.createGifData(from: result.url) { date in
                        let type = EditAssetResult.gif(date)
                        self.parent.selectedAsset.editResult = type
                        self.parent.editDone(self.parent.selectedAsset)
                        self.parent.dismiss()
                    }
                default:
                    break
                }
                
            default:
                
                if let imageURL = asset.result?.url,
                   let imageData = try? Data(contentsOf: imageURL),
                   let image = UIImage(data: imageData){
                    let type = EditAssetResult.image(image, imageData)
                    parent.selectedAsset.editResult = type
                }
                parent.editDone(parent.selectedAsset)
                parent.dismiss()
            }
            
        }
        
        func editorViewController(didCancel editorViewController: EditViewController) {
            parent.dismiss()
        }
        
    }
}

