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
    
    /// 自定义语言
    public var customLanguages: [CustomLanguage] = []
    
    /// 当前是否处于暗黑模式
    public static var isDark: Bool {
        if shared.appearanceStyle == .normal {
            return false
        }
        if shared.appearanceStyle == .dark {
            return true
        }
        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                return true
            }
        }
        return false
    }
    public static var HUDView: PhotoHUDProtocol.Type = ProgressHUD.self
    
    public var isDebugLogsEnabled: Bool = false
    
    /// 当前语言文件，每次创建PhotoPickerController判断是否需要重新创建
    var languageBundle: Bundle?
    /// 当前语言类型，每次创建PhotoPickerController时赋值
    var languageType: LanguageType?
    /// 当前外观样式，每次创建PhotoPickerController时赋值
    var appearanceStyle: AppearanceStyle = .varied
    
    /// 自带的bundle文件
    var bundle: Bundle?
    /// 加载指示器类型
    var indicatorType: IndicatorType = .system

    var downloadSession: URLSession!
    var downloadTasks: [String: URLSessionDownloadTask] = [:]
    var downloadCompletions: [String: (URL?, Error?, Any?) -> Void] = [:]
    var downloadProgresss: [String: (Double, URLSessionDownloadTask) -> Void] = [:]
    var downloadFileURLs: [String: URL] = [:]
    var downloadExts: [String: Any] = [:]

    let uuid: String = UUID().uuidString
    
    private override init() {
        super.init()
        downloadSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        createBundle()
    }
    
    @discardableResult
    func createBundle() -> Bundle? {
        return Bundle.main
    }
}
