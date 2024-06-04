//
//  Editor+PhotoTools.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit

extension PhotoTools {
    
    static func getCompressionQuality(_ dataCount: CGFloat) -> CGFloat? {
        var compressionQuality: CGFloat?
        if dataCount > 30000000 {
            compressionQuality = 25000000 / dataCount
        }else if dataCount > 15000000 {
            compressionQuality = 10000000 / dataCount
        }else if dataCount > 10000000 {
            compressionQuality = 6000000 / dataCount
        }else if dataCount > 3000000 {
            compressionQuality = 3000000 / dataCount
        }
        return compressionQuality
    }
    
}
