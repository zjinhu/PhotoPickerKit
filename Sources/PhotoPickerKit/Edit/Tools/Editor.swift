//
//  HXPhotoPicker.swift
//  PhotoPicker-Swift
//
//  Created by Silence on 2020/11/9.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

public enum Photo {

    @discardableResult
    @MainActor
    public static func edit(
        _ asset: EditorAsset,
        config: EditorConfiguration = .init(),
        delegate: EditViewControllerDelegate? = nil,
        fromVC: UIViewController? = nil
    ) async throws -> EditorAsset {
        try await EditViewController.edit(asset, config: config, delegate: delegate, fromVC: fromVC)
    }
    
    @discardableResult
    public static func edit(
        asset: EditorAsset,
        config: EditorConfiguration,
        sender: UIViewController? = nil,
        finished: EditViewController.FinishHandler? = nil,
        cancelled: EditViewController.CancelHandler? = nil
    ) -> EditViewController {
        let vc = EditViewController(
            asset,
            config: config,
            finish: finished,
            cancel: cancelled
        )
        var presentVC: UIViewController?
        if let sender = sender {
            presentVC = sender
        }else {
            presentVC = UIViewController.topViewController
        }
        presentVC?.present(
            vc,
            animated: true
        )
        return vc
    }
}

public enum HX {

    @discardableResult
    @MainActor
    public static func edit(
        _ asset: EditorAsset,
        config: EditorConfiguration = .init(),
        delegate: EditViewControllerDelegate? = nil,
        fromVC: UIViewController? = nil
    ) async throws -> EditorAsset {
        try await Photo.edit(asset, config: config, delegate: delegate, fromVC: fromVC)
    }

    public enum ImageTargetMode {
        /// 与原图宽高比一致，高度会根据`targetSize`计算
        case fill
        /// 根据`targetSize`拉伸/缩放
        case fit
        /// 如果`targetSize`的比例与原图不一样则居中显示
        case center
    }
}
