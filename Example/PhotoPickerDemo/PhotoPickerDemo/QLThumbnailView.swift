//
//  SwiftUIView.swift
//  
//
//  Created by HU on 2024/4/29.
//

import SwiftUI
import Photos
import BrickKit
import PhotoPickerKit
struct QLThumbnailView: View {
    let asset: SelectedAsset
    let isStatic: Bool
    @StateObject var photoModel: PhotoViewModel
    
    init(asset: SelectedAsset, isStatic: Bool = false) {
        self.asset = asset
        self.isStatic = isStatic
        _photoModel = StateObject(wrappedValue: PhotoViewModel(asset: asset))
    }
    
    var body: some View {
        GeometryReader { proxy in
            Rectangle()
                .foregroundColor(Color.gray.opacity(0.3))
                .ss.overlay{
                    if let image = photoModel.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                            .allowsHitTesting(false)
                    }
                }
                .ss.overlay(alignment: .bottomLeading) {
                    if asset.asset.mediaSubtypes.contains(.photoLive), !isStatic{
                        
                        Image(systemName: "livephoto")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .padding(5)
                        
                    }
                }
                .ss.overlay(alignment: .bottomTrailing) {
                    if asset.asset.isGIF(){
                        Text("GIF")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.vertical, 5)
                            .background(.black.opacity(0.4))
                            .cornerRadius(5)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                    }
                }
                .ss.overlay(alignment: .bottomLeading) {
                    if let time = photoModel.time{
                        HStack{
                            Image(systemName: "video")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                            
                            Text(time.formatDuration())
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                    }
                }
                .onAppear{
                    if let _ = photoModel.image{ }else{
                        photoModel.loadImage(size: proxy.size)
                    }
                }
                .onDisappear {
                    photoModel.onStop()
                }
                .ss.task {
                    await photoModel.onStart()
                }
        }
    }
}

