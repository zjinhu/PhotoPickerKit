//
//  ImageResource.swift
//  HXPhotoPicker
//
//  Created by Silence on 2024/1/30.
//  Copyright © 2024 Silence. All rights reserved.
//

import UIKit

public extension HX {
    
    static var imageResource: ImageResource { .shared }
    
    class ImageResource {
        public static let shared = ImageResource()
        /// 编辑器
        public var editor: Editor = .init()
    }
}

public extension HX.ImageResource {
    
    enum ImageType {
        case local(String)
        /// iOS 13.0+
        case system(String)
        
        var image: UIImage? {
            switch self {
            case .local(let name):
                return name.image
            case .system(let name):
                if #available(iOS 13.0, *) {
                    return .init(systemName: name)
                } else {
                    return name.image
                }
            }
        }
        
        var name: String {
            switch self {
            case .local(let name):
                return name
            case .system(let name):
                return name
            }
        }
        
        static var imageResource: HX.ImageResource {
            HX.ImageResource.shared
        }
    }

    struct Editor {
        /// 工具栏
        public var tools: Tools = .init()
        /// 视频裁剪
        public var video: Video = .init()
        /// 画笔
        public var brush: Brush = .init()
        /// 尺寸裁剪
        public var crop: Crop = .init()
        /// 文本
        public var text: Text = .init()
        /// 贴纸
        public var sticker: Sticker = .init()
        /// 配乐
        public var music: Music = .init()
        /// 马赛克/涂抹
        public var mosaic: Mosaic = .init()
        /// 画面调整
        public var adjustment: Adjustment = .init()
        /// 滤镜
        public var filter: Filter = .init()
        
        public struct Tools {
            /// 视频
            public var video: ImageType = .system("video.fill")
            /// 画笔绘制
            public var graffiti: ImageType = .system("pencil.and.scribble")
            /// 旋转、裁剪
            public var cropSize: ImageType = .system("crop.rotate")
            /// 文本
            public var text: ImageType = .system("t.square")
            /// 贴图
            public var chartlet: ImageType = .system("photo")
            /// 马赛克-涂抹
            public var mosaic: ImageType = .system("rectangle.checkered")
            /// 画面调整
            public var adjustment: ImageType = .system("dial.low.fill")
            /// 滤镜
            public var filter: ImageType = .system("camera.filters")
            /// 配乐
            public var music: ImageType = .system("music.quarternote.3")
        }
        
        public struct Brush {
            /// 画笔自定义颜色
            public var customColor: ImageType = .system("rainbow")
            /// 撤销
            public var undo: ImageType = .system("arrow.uturn.backward")
            /// 画布-撤销
            public var canvasUndo: ImageType = .system("arrow.uturn.backward.circle")
            /// 画布-反撤销
            public var canvasRedo: ImageType = .system("arrow.uturn.forward.circle")
            public var canvasUndoAll: ImageType = .system("x.circle")
        }
        
        public struct Crop {
            /// 选中原始比例时， 垂直比例-正常状态
            public var ratioVerticalNormal: ImageType = .system("rectangle.portrait")
            /// 选中原始比例时， 垂直比例-选中状态
            public var ratioVerticalSelected: ImageType = .system("checkmark.rectangle.portrait")
            /// 选中原始比例时， 横向比例-正常状态
            public var ratioHorizontalNormal: ImageType = .system("rectangle")
            /// 选中原始比例时， 横向比例-选中状态
            public var ratioHorizontalSelected: ImageType = .system("checkmark.rectangle")
            /// 水平镜像
            public var mirrorHorizontally: ImageType = .system("arrow.up.and.down.righttriangle.up.righttriangle.down")
            /// 垂直镜像
            public var mirrorVertically: ImageType = .system("arrow.left.and.right.righttriangle.left.righttriangle.right")
            /// 向左旋转
            public var rotateLeft: ImageType = .system("rotate.left")
            /// 向右旋转
            public var rotateRight: ImageType = .system("rotate.right")
            
            /// 自定义蒙版
            public var maskList: ImageType = .system("3d.bottom.filled")
        }
        
        public struct Text {
            /// 文字背景-正常状态
            public var backgroundNormal: ImageType = .system("t.square")
            /// 文字背景-选中状态
            public var backgroundSelected: ImageType = .system("t.square.fill")
            /// 文本自定义颜色
            public var customColor: ImageType = .system("rainbow")
        }
        
        public struct Sticker {
            /// 返回按钮
            public var back: ImageType = .system("chevron.down")
            /// 跳转相册按钮
            public var album: ImageType = .system("person.2.crop.square.stack")
            /// 相册为空时的封面图片
            public var albumEmptyCover: ImageType = .system("photo")
            /// 贴纸删除按钮
            public var delete: ImageType = .system("x.circle.fill")
            /// 贴纸旋转按钮
            public var rotate: ImageType = .system("arrow.counterclockwise.circle.fill")
            /// 贴纸缩放按钮
            public var scale: ImageType = .system("arrow.up.left.and.arrow.down.right.circle.fill")
            /// 拖拽底部删除垃圾桶打开状态
            public var trashOpen: ImageType = .system("trash.circle")
            /// 拖拽底部删除垃圾桶关闭状态
            public var trashClose: ImageType = .system("trash.circle.fill")
        }
        
        public struct Adjustment {
            /// 亮度
            public var brightness: ImageType = .system("microbe")
            /// 对比度
            public var contrast: ImageType = .system("circle.lefthalf.filled")
            /// 曝光度
            public var exposure: ImageType = .system("plusminus.circle")
            /// 高光
            public var highlights: ImageType = .system("circle.lefthalf.filled.righthalf.striped.horizontal.inverse")
            /// 饱和度
            public var saturation: ImageType = .system("drop.halffull")
            /// 阴影
            public var shadows: ImageType = .system("circle.lefthalf.striped.horizontal.inverse")
            /// 锐化
            public var sharpen: ImageType = .system("triangle")
            /// 暗角
            public var vignette: ImageType = .system("circle.dotted.circle")
            /// 色温
            public var warmth: ImageType = .system("thermometer.medium")
        }
        
        public struct Filter {
            /// 编辑
            public var edit: ImageType = .system("slider.vertical.3")
            /// 重置
            public var reset: ImageType = .system("arrow.counterclockwise")
        }
        
        public struct Mosaic {
            /// 撤销
            public var undo: ImageType = .system("arrow.uturn.backward")
            /// 马赛克
            public var mosaic: ImageType = .system("mosaic")
            /// 涂抹
            public var smear: ImageType = .system("eraser.fill")
            /// 每次涂抹的图片
            public var smearMask: ImageType = .system("paintbrush")
        }
        
        public struct Music {
            /// 搜索图标
            public var search: ImageType = .system("magnifyingglass")
            /// cell 上的音乐图标
            public var music: ImageType = .system("music.quarternote.3")
            /// 音量图标
            public var volum: ImageType = .system("speaker.wave.1")
            /// 选择框-未选中
            public var selectionBoxNormal: ImageType = .system("circle")
            /// 选择框-选中
            public var selectionBoxSelected: ImageType = .system("checkmark.circle.fill")
        }
        
        public struct Video {
            /// 播放
            public var play: ImageType = .system("play.fill")
            /// 暂停
            public var pause: ImageType = .system("pause.fill")
            /// 左边箭头
            public var leftArrow: ImageType = .system("chevron.compact.left")
            /// 右边箭头
            public var rightArrow: ImageType = .system("chevron.compact.right")
        }
    }
}
