//
//  SwiftUIView.swift
//
//
//  Created by FunWidget on 2024/5/16.
//

import SwiftUI
import Photos
import BrickKit

struct GalleryPageView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isNavigationQuickLook = false
    @State private var isNavigationCrop = false
    @ObservedObject var viewModel = GalleryModel()
    @Binding var selected: [SelectedAsset]
    let selectTitle: String?
    
    init(maxSelectionCount: Int = 0,
         selectTitle: String? = nil,
         autoCrop: Bool = false,
         cropRatio: CGSize = .zero,
         onlyImage: Bool = false,
         selected: Binding<[SelectedAsset]>) {
        _selected = selected
        
        self.selectTitle = selectTitle
        
        self.viewModel.maxSelectionCount = maxSelectionCount
        self.viewModel.isStatic = onlyImage
        self.viewModel.autoCrop = autoCrop
        self.viewModel.cropRatio = cropRatio
    }
    
    var body: some View {
        NavigationView {
            ZStack{
                NavigationLink(isActive: $isNavigationQuickLook) {
                    QuickLookView()
                        .navigationBarHidden(true)
                        .environmentObject(viewModel)
                        .ignoresSafeArea()
                } label: {
                    EmptyView()
                }
                
                NavigationLink(isActive: $isNavigationCrop) {
                    if let asset = viewModel.selectedAsset{
                        EditView(asset: asset,
                                 cropRatio: viewModel.cropRatio){ replace in
                            viewModel.selectedAssets.removeAll()
                            viewModel.selectedAssets.append(replace)
                            selected = viewModel.selectedAssets
                            dismiss()
                        }
                                 .statusBar(hidden: true)
                                 .navigationBarHidden(true)
                                 .ignoresSafeArea()
                                 
                    }
                    
                } label: {
                    EmptyView()
                }
                
                GalleryPageHostView()
                    .environmentObject(viewModel)
                    .ignoresSafeArea()
                    .navigationBarHidden(true)
            }
            
        }
        .navigationViewStyle(.stack)
        .ss.task {
            await self.viewModel.loadAllAlbums()
            await MainActor.run {
                if let selectTitle{
                    let index = self.viewModel.albums.firstIndex { item in
                        item.title == selectTitle
                    } ?? 0
                    
                    self.viewModel.defaultSelectIndex = index
                }
            }
        }
        .onChange(of: viewModel.onSelectedDone){ newValue in
            let group = DispatchGroup()
            let queue = DispatchQueue.global()
            
            var items: [SelectedAsset] = []
            for item in viewModel.selectedAssets{
                group.enter()
                
                item.isStatic = viewModel.isStatic
                
                switch item.fetchPHAssetType() {
                case .livePhoto:
                    queue.async(group: group) {
                        item.asset.getLivePhotoVideoUrl { url in
                            item.videoUrl = url
                            items.append(item)
                            group.leave()
                        }
                    }
                case .video:
                    queue.async(group: group) {
                        item.asset.getVideoUrl { url in
                            item.videoUrl = url
                            items.append(item)
                            group.leave()
                        }
                    }
                case .gif:
                    queue.async(group: group) {
                        if let imageData = item.asset.toImageData(){
                            GifTool.createVideoFromGif(gifData: imageData) { url in
                                DispatchQueue.main.async {
                                    item.videoUrl = url
                                    items.append(item)
                                    group.leave()
                                }
                            }
                        }else{
                            group.leave()
                        }
                    }
                default:
                    queue.async(group: group) {
                        if let image = item.asset.toImage(){
                            item.image = image
                            items.append(item)
                            group.leave()
                        }
                    }
                }
            }
            group.notify(queue: .main) {
                selected = items
                dismiss()
            }
        }
        .onChange(of: viewModel.showQuicklook){ newValue in
            if viewModel.selectedAssets.isEmpty{}else{
                for item in viewModel.selectedAssets{
                    item.isStatic = viewModel.isStatic
                }
                isNavigationQuickLook.toggle()
            }
        }
        .onChange(of: viewModel.showCrop){ newValue in
            if let sset = viewModel.selectedAsset{
                Task{
                    await viewModel.selectedAsset?.getOriginalSource()
                    isNavigationCrop.toggle()
                }
            }
        }
        .toast(isPresenting: $viewModel.showToast){
            AlertToast(displayMode: .hud,
                       type: .systemImage("exclamationmark.circle.fill", .alertOrange),
                       title: "最多可选\(viewModel.maxSelectionCount)张照片".localString,
                       style: .style(backgroundColor: .backColor, titleColor: .textColor, titleFont: .f14))
        }
    }
}

