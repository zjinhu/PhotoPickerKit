//
//  SwiftUIView.swift
//
//
//  Created by HU on 2024/4/26.
//

import SwiftUI
import BrickKit

public struct QuickLookView: View {
    
    @EnvironmentObject var viewModel: GalleryModel
    @Environment(\.dismiss) private var dismiss
 
    public init() { }
    
    public var body: some View {
        QuicklookHostView()
            .environmentObject(viewModel)
            .fullScreenCover(isPresented: $viewModel.isPresentedEdit) {
                
                if let asset = viewModel.selectedAsset{
                    EditView(asset: asset,
                             cropRatio: viewModel.cropRatio){ replace in
                        viewModel.selectedAssets.replaceSubrange(viewModel.previewSelectIndex...viewModel.previewSelectIndex, with: [replace])
                    }.ignoresSafeArea()
                }
                
            }
    }
}

