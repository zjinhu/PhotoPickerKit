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
public struct QLImageView: View {
    let asset: SelectedAsset
    @StateObject var photoModel: PhotoViewModel
    
    public init(asset: SelectedAsset) {
        self.asset = asset
        _photoModel = StateObject(wrappedValue: PhotoViewModel(asset: asset))
    }
    
    public var body: some View {
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
        
        if let ima = asset.image{
            photoModel.image = ima
            return
        }
        photoModel.loadImage()
    }
}
 
