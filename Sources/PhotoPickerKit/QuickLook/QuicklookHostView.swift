//
//  SwiftUIView.swift
//  
//
//  Created by FunWidget on 2024/5/23.
//

import SwiftUI
import BrickKit
struct QuicklookHostView: UIViewControllerRepresentable {
    @EnvironmentObject var viewModel: GalleryModel
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIViewController {
        return QuicklookViewController(viewModel: viewModel)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
 
}
 
