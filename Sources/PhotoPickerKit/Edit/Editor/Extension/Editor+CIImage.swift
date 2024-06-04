//
//  Editor+CIImage.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/1/12.
//

import UIKit

extension CIImage {
    
    func blurredImageWithClippedEdges(
        _ inputRadius: Float
    ) -> CIImage? {

        guard let currentFilter = CIFilter(name: "CIGaussianBlur") else {
            return nil
        }
        let beginImage = self
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        currentFilter.setValue(inputRadius, forKey: "inputRadius")
        guard let output = currentFilter.outputImage else {
            return nil
        }
        let context = CIContext()
        let newExtent = beginImage.extent.insetBy(dx: -output.extent.origin.x * 0.5, dy: -output.extent.origin.y * 0.5)
        guard let final = context.createCGImage(output, from: newExtent) else {
            return nil
        }
        return CIImage(cgImage: final)

    } 

}
