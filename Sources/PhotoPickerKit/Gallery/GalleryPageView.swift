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
            for item in viewModel.selectedAssets{
                item.isStatic = viewModel.isStatic
            }
            selected = viewModel.selectedAssets
            dismiss()
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
                    switch sset.fetchPHAssetType(){
                    case .video:
                        Task{
                            if let url = await sset.asset.getVideoUrl(){
                                await MainActor.run{
                                    viewModel.selectedAsset = sset
                                    viewModel.selectedAsset?.videoUrl = url
                                    isNavigationCrop.toggle()
                                }
                            }
                        }
                    case .livePhoto:
                        
                        sset.asset.getLivePhotoVideoUrl { url in
                            if let url {
                                DispatchQueue.main.async {
                                    viewModel.selectedAsset = sset
                                    viewModel.selectedAsset?.videoUrl = url
                                    isNavigationCrop.toggle()
                                }
                            }
                        }
                        
                    case .gif:
                        
                        if let imageData = sset.asset.toImageData(){
                            GifTool.createVideoFromGif(gifData: imageData) { url in
                                DispatchQueue.main.async {
                                    viewModel.selectedAsset = sset
                                    viewModel.selectedAsset?.imageData = imageData
                                    viewModel.selectedAsset?.gifVideoUrl = url
                                    isNavigationCrop.toggle()
                                }
                            }
                        }
                        
                    default:
                        
                        if let image = sset.asset.toImage(){
                            viewModel.selectedAsset = sset
                            viewModel.selectedAsset?.image = image
                            isNavigationCrop.toggle()
                        }
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

