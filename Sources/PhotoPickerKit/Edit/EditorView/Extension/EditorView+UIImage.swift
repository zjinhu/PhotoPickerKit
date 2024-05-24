//
//  EditorView+UIImage.swift
//  HXPhotoPicker
//
//  Created by Slience on 2023/1/31.
//

import UIKit

extension UIImage {
    var ci_Image: CIImage? {
        guard let cgImage = self.cgImage else {
            return nil
        }
        return CIImage(cgImage: cgImage)
    }
    
    func animateCGImageFrame(
    ) -> (cgImages: [CGImage], delays: [Double], duration: Double)? { // swiftlint:disable:this large_tuple
        return nil
    }
    
    func animateImageFrame(
    ) -> (images: [UIImage], delays: [Double], duration: Double)? { // swiftlint:disable:this large_tuple
        guard let data = animateCGImageFrame() else { return nil }
        
        let cgImages = data.0
        let delays = data.1
        let gifDuration = data.2
        
        var images: [UIImage] = []
        for imageRef in cgImages {
            let image = UIImage(cgImage: imageRef, scale: 1, orientation: .up)
            images.append(image)
        }
        return (images, delays, gifDuration)
    }
    
    func convertBlackImage() -> UIImage? {
        let rect = CGRect(origin: .zero, size: size)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = UIScreen._scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            UIColor.black.setFill()
            UIRectFill(rect)
            draw(in: rect, blendMode: .destinationOut, alpha: 1)
        }
        return image
    }
}
