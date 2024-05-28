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
                                   maxSelectionCount: 7,
                                   selectTitle: "Videos",
                                   autoCrop: true,
                                   cropRatio: .init(width: 1, height: 1),
                                   onlyImage: false,
                                   selected: $selectItem.pictures)
                
                Button {
                    showPicker.toggle()
                } label: {
                    Text("打开系统相册")
                }
                .photoPicker(isPresented: $showPicker,
                             selected: $selectedItems,
                             maxSelectionCount: 5,
                             matching: .any(of: [.images, .livePhotos, .videos]))
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
 
                            selectItem.selectedIndex = index
                            
                            switch picture.fetchPHAssetType(){
                                
                            case .gif:
                                
                                if let image = picture.asset.toImageData(){
                                    picture.imageData = image
                                    selectItem.selectedAsset = picture
                                    isPresentedCrop.toggle()
                                }
                                
                            case .video:
                                
                                
                                Task{
                                    if let url = await picture.asset.getVideoUrl(){
                                        await MainActor.run{
                                            picture.videoUrl = url
                                            selectItem.selectedAsset = picture
                                            isPresentedCrop.toggle()
                                        }
                                    }
                                }
                                
                                
                            case .livePhoto:
                                
                                picture.asset.getLivePhotoVideoUrl { url in
                                    if let url {
                                        DispatchQueue.main.async {
                                            picture.videoUrl = url
                                            selectItem.selectedAsset = picture
                                            isPresentedCrop.toggle()
                                        }
                                    }
                                }
                                
                                
                            default: 
                                
                                if let image = picture.asset.toImage(){
                                    picture.image = image
                                    selectItem.selectedAsset = picture
                                    isPresentedCrop.toggle()
                                }
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
                        .tag(index)
                    }
                }
                .id(UUID())
            }
        }
        .editPicker(isPresented: $isPresentedCrop,
                    cropRatio: .init(width: 1, height: 1),
                    asset: selectItem.selectedAsset) { asset in
            selectItem.pictures.replaceSubrange(selectItem.selectedIndex...selectItem.selectedIndex, with: [asset])
        }
    }
}

#Preview {
    ContentView()
}
