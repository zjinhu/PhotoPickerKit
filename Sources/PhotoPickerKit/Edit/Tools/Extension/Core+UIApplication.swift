//
//  Core+UIApplication.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/9/26.
//

import UIKit

extension UIApplication {
    static var _keyWindow: UIWindow? {
        let window = shared.windows.filter({ $0.isKeyWindow }).last
        return window
    }
    
    static var interfaceOrientation: UIInterfaceOrientation {
        let orientation = _keyWindow?.windowScene?.interfaceOrientation ?? .portrait
        return orientation
    }
}

extension UIScreen {
    
    static var _scale: CGFloat {
        if Thread.isMainThread,
           let scale = UIApplication._keyWindow?.windowScene?.screen.scale {
            return scale
        }
        return main.scale
    }
    
    static var _width: CGFloat {
        if Thread.isMainThread,
           let width = UIApplication._keyWindow?.windowScene?.screen.bounds.width {
            return width
        }
        return main.bounds.width
    }
    
    static var _height: CGFloat {
        if Thread.isMainThread,
           let height = UIApplication._keyWindow?.windowScene?.screen.bounds.height {
            return height
        }
        return main.bounds.height
    }
    
    static var _size: CGSize {
        if Thread.isMainThread,
           let size = UIApplication._keyWindow?.windowScene?.screen.bounds.size {
            return size
        }
        return main.bounds.size
    }
    
}
