//
//  HXPhotoPicker.swift
//  PhotoPicker-Swift
//
//  Created by Silence on 2020/11/9.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

class HXPhotoPicker {}

public enum Photo {

    @available(iOS 13.0, *)
    @discardableResult
    @MainActor
    public static func edit(
        _ asset: EditorAsset,
        config: EditorConfiguration = .init(),
        delegate: EditorViewControllerDelegate? = nil,
        fromVC: UIViewController? = nil
    ) async throws -> EditorAsset {
        try await EditorViewController.edit(asset, config: config, delegate: delegate, fromVC: fromVC)
    }
    
    @discardableResult
    public static func edit(
        asset: EditorAsset,
        config: EditorConfiguration,
        sender: UIViewController? = nil,
        finished: EditorViewController.FinishHandler? = nil,
        cancelled: EditorViewController.CancelHandler? = nil
    ) -> EditorViewController {
        let vc = EditorViewController(
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
   
    @available(iOS 13.0, *)
    @discardableResult
    @MainActor
    public static func edit(
        _ asset: EditorAsset,
        config: EditorConfiguration = .init(),
        delegate: EditorViewControllerDelegate? = nil,
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

public struct HXPickerWrapper<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}
public protocol HXPickerCompatible: AnyObject { }
public protocol HXPickerCompatibleValue {}
extension HXPickerCompatible {
    public var hx: HXPickerWrapper<Self> {
        get { return HXPickerWrapper(self) }
        set { } // swiftlint:disable:this unused_setter_value
    }
}
extension HXPickerCompatibleValue {
    public var hx: HXPickerWrapper<Self> {
        get { return HXPickerWrapper(self) }
        set { } // swiftlint:disable:this unused_setter_value
    }
}
