//
//  SwiftUIView.swift
//  
//
//  Created by HU on 2024/5/16.
//

import SwiftUI

struct GalleryPageHostView: UIViewControllerRepresentable {
 
    @EnvironmentObject var viewModel: GalleryModel

    func makeUIViewController(context: Context) -> UIViewController {
        return makeGalleryPage(context: context)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
    
    func makeGalleryPage(context: Context) -> UIViewController {
        let vc = GalleryPageViewController(viewModel: viewModel)
        return vc
    }
}

 
