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
                
//                NavigationLink(isActive: $isNavigationCrop) {
//                    if let asset = viewModel.selectedAssets.first{
//                        ImageCropView(asset: asset,
//                                      cropRatio: viewModel.cropRatio,
//                                      cancle: {
//                            viewModel.selectedAssets.removeAll()
//                        },
//                                      done: { asset in
//                            viewModel.selectedAssets.replaceSubrange(0...0, with: [asset])
//                            viewModel.onSelectedDone.toggle()
//                        })
//                        .navigationBarHidden(true)
//                        .ignoresSafeArea()
//                    }
//
//                } label: {
//                    EmptyView()
//                }
                
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
        .onChange(of: viewModel.onSelectedDone, perform: { newValue in
            selected = viewModel.selectedAssets
            dismiss()
        })
        .onChange(of: viewModel.showQuicklook, perform: { newValue in
            if viewModel.selectedAssets.isEmpty{}else{
                isNavigationQuickLook.toggle()
            }
        })
        .onChange(of: viewModel.showCrop, perform: { newValue in
            if viewModel.selectedAssets.isEmpty{}else{
                isNavigationCrop.toggle()
            }
        })
        .toast(isPresenting: $viewModel.showToast){
            AlertToast(displayMode: .hud,
                       type: .systemImage("exclamationmark.circle.fill", .alertOrange),
                       title: "最多可选\(viewModel.maxSelectionCount)张照片".localString,
                       style: .style(backgroundColor: .backColor, titleColor: .textColor, titleFont: .f14))
        }
    }
}

