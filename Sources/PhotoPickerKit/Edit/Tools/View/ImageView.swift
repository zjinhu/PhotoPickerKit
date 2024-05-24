//
//  ImageView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/18.
//

import UIKit
 
final class ImageView: GIFImageView {

    override init() {
        super.init(frame: .zero)
        contentMode = .scaleAspectFill
        clipsToBounds = true
    }
    
    func setImage(_ image: UIImage?, animated: Bool) {
        if let image = image {
            self.image = image
            if animated {
                let transition: CATransition = .init()
                transition.type = .fade
                transition.duration = 0.2
                transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                layer.add(transition, forKey: nil)
            }
        }
    }
    
    func setImageData(_ imageData: Data?) {
        guard let imageData = imageData else {
            gifImage = nil
            return
        }
        let image: GIFImage? = .init(data: imageData)
        gifImage = image
    }
    
    func startAnimatedImage() {
        setupDisplayLink()
    }
    
    func stopAnimatedImage() {
        displayLink?.invalidate()
        gifImage = nil
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
