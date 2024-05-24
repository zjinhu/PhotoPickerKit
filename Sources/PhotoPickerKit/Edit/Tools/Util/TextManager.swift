//
//  TextManager.swift
//  HXPhotoPicker
//
//  Created by Silence on 2024/2/4.
//  Copyright © 2024 Silence. All rights reserved.
//

import UIKit

public extension HX {
    
    static var textManager: TextManager { .shared }
    
    class TextManager {
        public static let shared = TextManager()
        /// 编辑器
        public var editor: Editor = .init()
    }
}

public extension HX.TextManager {
    
    enum TextType {
        /// 内部本地化
        case localized(String)
        /// 直接显示，不本地化
        case custom(String)
        
        var text: String {
            switch self {
            case .localized(let text):
                return text.localString
            case .custom(let text):
                return text
            }
        }
    }

    struct Editor {
        public var tools: Tools = .init()
        public var brush: Tools = .init()
        public var text: Text = .init()
        public var sticker: Sticker = .init()
        public var crop: Crop = .init()
        public var music: Music = .init()
        public var adjustment: Adjustment = .init()
        public var filter: Filter = .init()
        
        public var photoLoadTitle: TextType = .localized("图片下载中")
        public var videoLoadTitle: TextType = .localized("视频下载中")
        public var iCloudSyncHudTitle: TextType = .localized("正在同步iCloud")
        public var loadFailedAlertTitle: TextType = .localized("提示")
        public var photoLoadFailedAlertMessage: TextType = .localized("图片获取失败!")
        public var videoLoadFailedAlertMessage: TextType = .localized("视频获取失败!")
        public var iCloudSyncFailedAlertMessage: TextType = .localized("iCloud同步失败")
        public var loadFailedAlertDoneTitle: TextType = .localized("确定")
        public var processingHUDTitle: TextType = .localized("正在处理...")
        public var processingFailedHUDTitle: TextType = .localized("处理失败")
        
        public struct Tools {
            public var cancelTitle: TextType = .localized("取消")
            public var cancelTitleFont: UIFont = HXPickerWrapper<UIFont>.regularPingFang(ofSize: 17)
            public var finishTitle: TextType = .localized("完成")
            public var finishTitleFont: UIFont = HXPickerWrapper<UIFont>.regularPingFang(ofSize: 17)
            public var resetTitle: TextType = .localized("还原")
            public var resetTitleFont: UIFont = HXPickerWrapper<UIFont>.regularPingFang(ofSize: 17)
        }
        
        public struct Brush {
            public var cancelTitle: TextType = .localized("取消")
            public var cancelTitleFont: UIFont = HXPickerWrapper<UIFont>.regularPingFang(ofSize: 17)
            public var finishTitle: TextType = .localized("完成")
            public var finishTitleFont: UIFont = HXPickerWrapper<UIFont>.regularPingFang(ofSize: 17)
        }
        
        public struct Text {
            public var cancelTitle: TextType = .localized("取消")
            public var cancelTitleFont: UIFont = .systemFont(ofSize: 17)
            public var finishTitle: TextType = .localized("完成")
            public var finishTitleFont: UIFont = .systemFont(ofSize: 17)
        }
        
        public struct Sticker {
            public var trashCloseTitle: TextType = .localized("拖动到此处删除")
            public var trashOpenTitle: TextType = .localized("松手即可删除")
        }
        
        public struct Crop {
            public var maskListTitle: TextType = .localized("蒙版素材")
            public var maskListFinishTitle: TextType = .localized("完成")
            public var maskListFinishTitleFont: UIFont = .systemFont(ofSize: 17)
            
        }
        
        public struct Music {
            public var emptyHudTitle: TextType = .localized("暂无配乐")
            public var lyricEmptyTitle: TextType = .localized("此歌曲暂无歌词，请您欣赏")
            
            public var searchButtonTitle: TextType = .localized("搜索")
            public var searchButtonTitleFont: UIFont = HXPickerWrapper<UIFont>.mediumPingFang(ofSize: 14) 
            public var volumeButtonTitle: TextType = .localized("音量")
            public var volumeButtonTitleFont: UIFont = HXPickerWrapper<UIFont>.mediumPingFang(ofSize: 14)
            public var volumeMusicButtonTitle: TextType = .localized("配乐")
            public var volumeMusicButtonTitleFont: UIFont = .systemFont(ofSize: 15)
            public var volumeOriginalButtonTitle: TextType = .localized("视频原声")
            public var volumeOriginalButtonTitleFont: UIFont = .systemFont(ofSize: 15)
            
            public var musicButtonTitle: TextType = .localized("配乐")
            public var musicButtonTitleFont: UIFont = HXPickerWrapper<UIFont>.mediumPingFang(ofSize: 16)
            public var originalButtonTitle: TextType = .localized("视频原声")
            public var originalButtonTitleFont: UIFont = HXPickerWrapper<UIFont>.mediumPingFang(ofSize: 16)
            public var lyricButtonTitle: TextType = .localized("歌词")
            public var lyricButtonTitleFont: UIFont = HXPickerWrapper<UIFont>.mediumPingFang(ofSize: 16)
            
            public var listTitle: TextType = .localized("背景音乐")
            public var finishTitle: TextType = .localized("完成")
            public var finishTitleFont: UIFont = .systemFont(ofSize: 17)
            public var searchPlaceholder: TextType = .localized("搜索歌名")
            public var searchPlaceholderFont: UIFont = .systemFont(ofSize: 17)
        }
        
        public struct Adjustment {
            public var brightnessTitle: TextType = .localized("亮度")
            public var contrastTitle: TextType = .localized("对比度")
            public var exposureTitle: TextType = .localized("曝光度")
            public var saturationTitle: TextType = .localized("饱和度")
            public var warmthTitle: TextType = .localized("色温")
            public var vignetteTitle: TextType = .localized("暗角")
            public var sharpenTitle: TextType = .localized("锐化")
            public var highlightsTitle: TextType = .localized("高光")
            public var shadowsTitle: TextType = .localized("阴影")
        }
        
        public struct Filter {
            public var originalPhotoTitle: TextType = .localized("原图")
            public var originalVideoTitle: TextType = .localized("原片")
            
            public var nameFont: UIFont = HXPickerWrapper<UIFont>.regularPingFang(ofSize: 13)
            public var parameterFont: UIFont = HXPickerWrapper<UIFont>.regularPingFang(ofSize: 11)
        }
    }
}

extension HX.TextManager.TextType: Codable {
    enum CodingKeys: CodingKey {
        case localized
        case custom
        case error
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let text = try? container.decode(String.self, forKey: .localized) {
            self = .localized(text)
            return
        }
        if let text = try? container.decode(String.self, forKey: .custom) {
            self = .custom(text)
            return
        }
        throw DecodingError.dataCorruptedError(
            forKey: CodingKeys.error,
            in: container,
            debugDescription: "Invalid type"
        )
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .localized(let text):
            try container.encode(text, forKey: .localized)
        case .custom(let text):
            try container.encode(text, forKey: .custom)
        }
    }
}

