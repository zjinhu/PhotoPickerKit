//
//  EditorChartlet.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/7/26.
//

import UIKit

public typealias EditorTitleChartletResponse = ([EditorChartlet]) -> Void
public typealias EditorChartletListResponse = (Int, [EditorChartlet]) -> Void

public struct EditorChartlet {
    
    /// 贴图对应的 UIImage 对象, 视频支持gif
    public let image: UIImage?
    
    public let imageData: Data?

    public let ext: Any?
    
    public init(
        image: UIImage?,
        imageData: Data? = nil,
        ext: Any? = nil
    ) {
        self.image = image
        self.imageData = imageData
        self.ext = ext
    }

}

class EditorChartletTitle {
    
    /// 标题图标 对应的 UIImage 数据
    let image: UIImage?

    init(image: UIImage?) {
        self.image = image
    }
    
    var isSelected = false
    var isLoading = false
    var isAlbum = false
    var chartletList: [EditorChartlet] = []
}
