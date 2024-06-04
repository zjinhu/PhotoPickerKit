//
//  EditorViewController+UINavigationController.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/7/22.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

extension EditViewController: UINavigationControllerDelegate {
    public func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            isTransitionCompletion = false
            return EditorTransition(mode: .push)
        }else if operation == .pop {
            isPopTransition = true
            return EditorTransition(mode: .pop)
        }
        return nil
    }
}

extension EditViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        isTransitionCompletion = false
        return EditorTransition(mode: .present)
    }
    
    public func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        isPopTransition = true
        return EditorTransition(mode: .dismiss)
    }
}


extension EditViewController {
    
    func setTransitionImage(_ image: UIImage) {
        editorView.setImage(image)
    }
    
    func transitionHide() {
        toolBarView.alpha = 0
        videoControlView.alpha = 0
        invertColorButton.alpha = 0
    }
    
    func transitionShow() {
        toolBarView.alpha = 1
        videoControlView.alpha = 1
        invertColorButton.alpha = 1
    }
    
    func transitionCompletion() {
        switch loadAssetStatus {
        case .loadding(let isProgress):
            if isProgress {
                assetLoadingView = PhotoManager.HUDView.show(with: nil, delay: 0, animated: true, addedTo: view)
            }else {
                PhotoManager.HUDView.show(with: nil, delay: 0, animated: true, addedTo: view)
            }
        case .succeed(let type):
            initAssetType(type)
        case .failure:
            if selectedAsset.contentType == .video {
                loadFailure(message: "视频获取失败!")
            }else {
                loadFailure(message: "图片获取失败!")
            }
        }
    }
}
