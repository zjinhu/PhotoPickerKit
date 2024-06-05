//
//  EditorConfiguration.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit

public struct EditorConfiguration: IndicatorTypeConfig {

    public var modalPresentationStyle: UIModalPresentationStyle
 
    /// hide status bar
    /// 隐藏状态栏
    public var prefersStatusBarHidden: Bool = true
    
    /// Rotation is allowed, and rotation can only be disabled in full screen
    /// 允许旋转，全屏情况下才可以禁止旋转
    public var shouldAutorotate: Bool = true
    
    /// 是否自动返回
    public var isAutoBack: Bool = true
    
    /// supported directions
    /// 支持的方向
    public var supportedInterfaceOrientations: UIInterfaceOrientationMask = .all

    /// Whether to disable the done button in the unedited state
    /// 是否在未编辑状态下禁用完成按钮
    public var isWhetherFinishButtonDisabledInUneditedState: Bool = false
    
    /// The URL configuration after editing, the default is under tmp
    /// Please set a different URL each time you edit to prevent the existing data from being overwritten
    /// If editing a GIF, please set the URL of the gif suffix
    /// 编辑之后的URL配置，默认在tmp下
    /// 每次编辑时请设置不同URL，防止之前存在的数据被覆盖
    /// 如果编辑的是GIF，请设置gif后缀的URL
    public var urlConfig: EditorURLConfig?
    
    /// picture configuration
    /// 图片配置
    public var photo: Photo = .init()
    
    /// video configuration
    /// 视频配置
    public var video: Video = .init()

    /// Crop Screen Configuration
    /// 裁剪画面配置
    public var cropSize: CropSize = .init()
    
    /// Ignore video cropping duration when fixed crop size state
    /// 固定裁剪大小状态时忽略视频裁剪时长
    public var isIgnoreCropTimeWhenFixedCropSizeState: Bool = true
    
    public init() {
        modalPresentationStyle = .automatic
    }
}

public extension EditorConfiguration {
    
    struct Photo {
        
        /// Control brushes, textures... clarity after export
        /// 控制画笔、贴图...导出之后清晰程度
        public var scale: CGFloat = UIScreen._scale

        public init() { }
    }
    
    struct Video {
        
        /// Video export resolution
        /// 视频导出的分辨率
        public var preset: ExportPreset = .ratio_960x540
        
        /// Quality of video export [0-10]
        /// 视频导出的质量[0-10]
        public var quality: Int = 6
        
        /// Autoplay after loading is complete
        /// 加载完成后自动播放
        public var isAutoPlay: Bool = true
        
        /// Clipping duration configuration
        /// 裁剪时长配置
        public var cropTime: CropTime = .init()
        
        public init() { }
        
        public struct CropTime {
            ///xiugai add
            public var isCanControlMove: Bool = false
            /// Video maximum cropping duration
            /// > 0 The video must be cropped when it is longer than
            /// = 0 for no clipping
            /// 视频最大裁剪时长
            /// > 0 视频时长超过时必须裁剪
            /// = 0 可不裁剪
            public var maximumTime: TimeInterval = 0
            
            /// Video minimum cropping duration, minimum 1
            /// 视频最小裁剪时长，最小1
            public var minimumTime: TimeInterval = 1
            
            /// The color of the left and right arrows in normal state
            /// 左右箭头正常状态下的颜色
            public var arrowNormalColor: UIColor = .white
            
            /// The color of the left and right arrows when they are highlighted
            /// 左右箭头高亮状态下的颜色
            public var arrowHighlightedColor: UIColor = .black
            
            /// The color of the highlighted border
            /// 边框高亮状态下的颜色
            public var frameHighlightedColor: UIColor = .white
            
            public init() { }
        }
    }

    struct CropSize {

        /// round crop box
        /// isResetToOriginal = false, which can avoid restoring the original width and height when resetting
        /// 圆形裁剪框
        /// isResetToOriginal = false，可以避免重置时恢复原始宽高
        public var isRoundCrop: Bool = false
        
        /// default fixed ratio
        /// 默认固定比例
        /// ```swift
        /// /// Leave `aspectRatios` empty if you don't want other ratios at the bottom
        /// /// 如果不想要底部其他的比例请将`aspectRatios`置空
        /// aspectRatios = []
        /// ```
        public var isFixedRatio: Bool = false
        
        /// default aspect ratio
        /// 默认宽高比
        public var aspectRatio: CGSize = .zero
        
        /// Mask type when clipping
        /// 裁剪时遮罩类型
        public var maskType: EditorView.MaskType = .blurEffect(style: .dark)
        
        /// Show proportional size
        /// 显示比例大小
        public var isShowScaleSize: Bool = true

        /// When the default fixed ratio, click restore to reset to the original aspect ratio
        /// true: reset to original aspect ratio
        /// false: Reset to the default aspect ratio `aspectRatio` set, centered
        /// 当默认固定比例时，点击还原是否重置到原始宽高比
        /// true：重置到原始宽高比
        /// false：重置到设置的默认宽高比`aspectRatio`，居中显示
        public var isResetToOriginal: Bool = false
        
        public init() { } 
    }

} 
