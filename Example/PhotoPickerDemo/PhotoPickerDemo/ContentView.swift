//
//  ContentView.swift
//  Example
//
//  Created by HU on 2024/4/22.
//

import SwiftUI
import PhotoPickerKit
import Photos
import PhotosUI
import BrickKit

class SelectItem: ObservableObject{
    @Published var pictures: [SelectedAsset] = []
    @Published var selectedIndex = 0
    @Published var selectedAsset: SelectedAsset?
}

struct ContentView: View {
    @State var isPresentedGallery = false
    @State var isPresentedCrop = false
    
    @State private var showPicker: Bool = false
    @State private var selectedItems: [PHPickerResult] = []
    @State private var selectedImages: [UIImage]?
    
    @StateObject var selectItem = SelectItem()

    var body: some View {
        NavigationView{
            
            VStack {

                Button {
                    isPresentedGallery.toggle()
                } label: {
                    Text("打开自定义相册")
                        .foregroundColor(Color.red)
                        .frame(height: 50)
                }
                .galleryPicker(isPresented: $isPresentedGallery,
                               maxSelectionCount: 5,
                               selectTitle: "Videos",
                               autoCrop: true,
                               cropRatio: .zero,
                               onlyImage: true,
                               selected: $selectItem.pictures)
                
                Button {
                    showPicker.toggle()
                } label: {
                    Text("打开系统相册")
                }
                .photoPicker(isPresented: $showPicker,
                             selected: $selectedItems,
                             maxSelectionCount: 1,
                             matching: .any(of: [.images]))
                .onChange(of: selectedItems) { newItems in
                    var images = [UIImage]()
                    Task{
                        for item in newItems{
                            if let image = try await item.loadTransfer(type: UIImage.self){
                                images.append(image)
                            }
                        }
                        await MainActor.run {
                            selectedImages = images
                        }
                    }
                }
                
                List {
                    
                    if let selectedImages {
                        ForEach(selectedImages, id: \.self) { picture in
                            Image(uiImage: picture)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 250, height: 250)
                                
                        }
                    }
                    
                    ForEach(Array(selectItem.pictures.enumerated()), id: \.element) { index, picture in
                        
                        
                        Button {

                            ///在进入编辑页面之前需要准备好相关类型的资源，保证每次进入编辑都是最原始的状态
                            Task{
                                selectItem.selectedAsset = await picture.getOriginalSource()
                                selectItem.selectedIndex = index
                                isPresentedCrop.toggle()
                            }

                        } label: {
                            
                            switch picture.fetchPHAssetType(){
                            case .gif:
                                QLGifView(asset: picture)
                            case .livePhoto:
                                QLivePhotoView(asset: picture)
                                    .frame(height: Screen.width)
                            case .video:
                                QLVideoView(asset: picture)
                                    .frame(height: 200)
                            default:
                                QLImageView(asset: picture)
                            }
                            
                        }
                    }
                }.id(UUID())
                
            }
        }
        .editPicker(isPresented: $isPresentedCrop,
                    cropRatio: .zero,
                    asset: selectItem.selectedAsset) { asset in
            selectItem.pictures.replaceSubrange(selectItem.selectedIndex...selectItem.selectedIndex, with: [asset])
        }
    }
}

#Preview {
    ContentView()
}
