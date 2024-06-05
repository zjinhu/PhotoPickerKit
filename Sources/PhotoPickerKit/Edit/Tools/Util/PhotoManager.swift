//
//  PhotoManager.swift
//  照片选择器-Swift
//
//  Created by Silence on 2019/6/29.
//  Copyright © 2019年 Silence. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

public final class PhotoManager: NSObject {
    
    public static let shared = PhotoManager()
    
    /// 当前是否处于暗黑模式
    public static var isDark: Bool {
        if shared.appearanceStyle == .normal {
            return false
        }
        if shared.appearanceStyle == .dark {
            return true
        }
        
        if UITraitCollection.current.userInterfaceStyle == .dark {
            return true
        }
        
        return false
    }
    public static var HUDView: PhotoHUDProtocol.Type = ProgressHUD.self

    /// 当前外观样式，每次创建PhotoPickerController时赋值
    var appearanceStyle: AppearanceStyle = .varied
    
    /// 自带的bundle文件
    var bundle: Bundle?
    /// 加载指示器类型
    var indicatorType: IndicatorType = .system
    
    let uuid: String = UUID().uuidString
    
    private override init() {
        super.init()
        createBundle()
    }
    
    @discardableResult
    func createBundle() -> Bundle? {
        return Bundle.main
    }
}
