//
//  SwiftUIView.swift
//  
//
//  Created by HU on 2024/4/28.
//

import SwiftUI
import Photos
import BrickKit
import PhotoPickerKit
struct QLImageView: View {
    let asset: SelectedAsset
    @StateObject var photoModel: PhotoViewModel
    
    init(asset: SelectedAsset) {
        self.asset = asset
        _photoModel = StateObject(wrappedValue: PhotoViewModel(asset: asset))
    }
    
    var body: some View {
        Image(uiImage: photoModel.image ?? UIImage())
            .resizable()
            .scaledToFit()
            .onAppear{
                if let _ = photoModel.image{}else{
                    loadAsset()
                }
            }
    }
    
    private func loadAsset() {
        
        if let ima = asset.editResult?.image{
            photoModel.image = ima
            return
        }
        if let ima = asset.editResult?.imageData{
            photoModel.image = UIImage(data: ima)
            return
        }
        photoModel.loadImage()
    }
}
 
