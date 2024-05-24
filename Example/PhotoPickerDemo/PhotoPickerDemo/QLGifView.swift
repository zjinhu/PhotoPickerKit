//
//  SwiftUIView.swift
//
//
//  Created by FunWidget on 2024/5/23.
//

import SwiftUI
import Photos
import PhotoPickerKit
struct QLGifView: View {
    let asset: SelectedAsset
    @StateObject var gifModel: GifViewModel
    
    
    public init(asset: SelectedAsset) {
        self.asset = asset
        _gifModel = StateObject(wrappedValue: GifViewModel(asset: asset))
    }
    
    var body: some View {
        VStack{
            if let data = gifModel.imageData{
                GIFView(data: data)
            }
        }
        .onAppear{
            if let _ = gifModel.imageData{}else{
                loadAsset()
            }
        }
        .onDisappear{
            gifModel.onStop()
        }
    }
    
    private func loadAsset() {
        
        gifModel.loadImageData()
    }
}

