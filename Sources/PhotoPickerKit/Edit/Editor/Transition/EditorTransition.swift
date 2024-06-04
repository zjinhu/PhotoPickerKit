//
//  EditorTransition.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/10/5.
//

import UIKit
import Photos

public enum EditorTransitionMode {
    case push
    case pop
    case present
    case dismiss
}

// swiftlint:disable type_body_length
class EditorTransition: NSObject, UIViewControllerAnimatedTransitioning {
    // swiftlint:enable type_body_length
    private let mode: EditorTransitionMode
    private var requestID: PHImageRequestID?
    private var transitionView: UIView?
    private var previewView: UIImageView!
    
    init(mode: EditorTransitionMode) {
        self.mode = mode
        super.init()
        previewView = UIImageView()
        previewView.contentMode = .scaleAspectFill
        previewView.clipsToBounds = true
    }

    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        if let editorVC = transitionContext?.viewController(
            forKey: (mode == .push || mode == .present) ? .to : .from) as? EditViewController,
           let duration = editorVC.delegate?.editorViewController(
            editorVC, transitionDuration: mode) {
            return duration
        }
        return 0.55
    }
    func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        pushTransition(using: transitionContext)
    }
    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_body_length
    func pushTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        // swiftlint:enable cyclomatic_complexity
        // swiftlint:enable function_body_length
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to) else {
            return
        }
        let containerView = transitionContext.containerView
        let contentView = UIView(frame: fromVC.view.bounds)
        let editorVC: UIViewController
        switch mode {
        case .push, .present:
            if mode == .push {
                containerView.addSubview(fromVC.view)
            }
            containerView.addSubview(toVC.view)
            fromVC.view.addSubview(contentView)
            contentView.backgroundColor = .clear
            editorVC = toVC
        case .pop, .dismiss:
            if mode == .pop {
                containerView.addSubview(toVC.view)
                containerView.addSubview(fromVC.view)
            }
            
            toVC.view.addSubview(contentView)
            contentView.backgroundColor = .black
            editorVC = fromVC
        }
        contentView.addSubview(previewView)
        var fromRect: CGRect = .zero
        var toRect: CGRect = .zero
        let isSpring: Bool = true
        if let editorVC = editorVC as? EditViewController {
            switch mode {
            case .push, .present:
                editorVC.isTransitionCompletion = false
                editorVC.transitionHide()
                if let view = editorVC.delegate?.editorViewController(transitioStartPreviewView: editorVC) {
                    transitionView = view
                    fromRect = view.convert(view.bounds, to: contentView)
                }else if let rect = editorVC.delegate?.editorViewController(
                    transitioStartPreviewFrame: editorVC
                ) {
                    fromRect = rect
                }
                let image = editorVC.delegate?.editorViewController(transitionPreviewImage: editorVC)
                previewView.image = image
                if let image = image {
                    editorVC.setTransitionImage(image)
                }

                if let image = editorVC.editorView.image {
                    toRect = getTransitionFrame(
                        with: image.size,
                        viewSize: toVC.view.size
                    )
                }else {
                    if let image = image {
                        toRect = getTransitionFrame(
                            with: image.size,
                            viewSize: toVC.view.size
                        )
                    }else {
                        toRect = .zero
                    }
                }

                if toRect.width < editorVC.view.width {
                    toRect.origin.x = (editorVC.view.width - toRect.width) * 0.5
                }
                if toRect.height < editorVC.view.height {
                    toRect.origin.y = (editorVC.view.height - toRect.height) * 0.5
                }
            case .pop, .dismiss:
                let view = editorVC.editorView.contentView
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                if let image = editorVC.editedResult?.image {
                    imageView.image = image
                }else {
                    if let image = editorVC.editorView.image {
                        imageView.image = image
                    }else {
                        imageView.image = view.layer.convertedToImage()
                    }
                }
                let finalView = editorVC.editorView.finalView
                if let rect = finalView.superview?.convert(finalView.frame, to: contentView) {
                    fromRect = rect
                }
                previewView.frame = fromRect
                imageView.frame = previewView.bounds
                previewView.addSubview(imageView)
                view.frame = previewView.bounds
                if let view = editorVC.delegate?.editorViewController(transitioEndPreviewView: editorVC) {
                    transitionView = view
                    toRect = view.convert(view.bounds, to: contentView)
                }else if let rect = editorVC.delegate?.editorViewController(
                    transitioEndPreviewFrame: editorVC
                ) {
                    toRect = rect
                }
            }
            editorVC.editorView.isHidden = true
            editorVC.view.backgroundColor = .clear
        }else {
            previewView.removeFromSuperview()
            contentView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            return
        }

        previewView.frame = fromRect
        transitionView?.isHidden = true
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration - 0.15) {
            switch self.mode {
            case .push, .present:
                contentView.backgroundColor = .black
               
                if let editorVC = editorVC as? EditViewController {
                    editorVC.transitionShow()
                }
            case .pop, .dismiss:
                contentView.backgroundColor = .clear
            
                if let editorVC = editorVC as? EditViewController {
                    editorVC.transitionHide()
                }
            }
        }
        let tempView = UIView()
        let frameIsSame = previewView.frame.equalTo(toRect)
        if frameIsSame {
            contentView.addSubview(tempView)
        }
        animate(
            withDuration: duration,
            isSpring: isSpring
        ) { [weak self] in
            guard let self = self else { return }
            if toRect.equalTo(.zero) {
                self.previewView.alpha = 0
                return
            }
            if frameIsSame {
                tempView.alpha = 0
            }else {
                self.previewView.frame = toRect
            }
            if self.previewView.layer.cornerRadius > 0 {
                self.previewView.layer.cornerRadius = self.previewView.width * 0.5
            }
            if let subView = self.previewView.subviews.first {
                subView.frame = CGRect(origin: .zero, size: toRect.size)
            }
        } completion: { [weak self] _ in
            guard let self = self else {
                contentView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                return
            }
            self.transitionView?.isHidden = false
            switch self.mode {
            case .push, .present:
                if let requestID = self.requestID {
                    PHImageManager.default().cancelImageRequest(requestID)
                    self.requestID = nil
                }
                
                if let editorVC = editorVC as? EditViewController {
                    editorVC.view.backgroundColor = .black
                    editorVC.editorView.isHidden = false
                    editorVC.isTransitionCompletion = true
                    editorVC.transitionCompletion()
                }
                self.previewView.removeFromSuperview()
                contentView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            case .pop, .dismiss:
                UIView.animate(
                    withDuration: 0.25,
                    delay: 0,
                    options: [.allowUserInteraction]
                ) {
                    self.previewView.alpha = 0
                } completion: { _ in
                    self.previewView.removeFromSuperview()
                    contentView.removeFromSuperview()
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }
            }
        }
    }

    func animate(
        withDuration duration: TimeInterval,
        isSpring: Bool,
        animations: @escaping () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        if isSpring {
            UIView.animate(
                withDuration: duration,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0,
                options: [.layoutSubviews, .curveEaseOut]
            ) {
                animations()
            } completion: { isFinished in
                completion?(isFinished)
            }
        }else {
            UIView.animate(
                withDuration: duration,
                animations: animations,
                completion: completion
            )
        }
    }

    func getTransitionFrame(with imageSize: CGSize, viewSize: CGSize) -> CGRect {
        let imageScale = imageSize.width / imageSize.height
        let imageWidth = viewSize.width
        let imageHeight = imageWidth / imageScale
        let imageX: CGFloat = 0
        var imageY: CGFloat = 0
        if imageHeight < viewSize.height {
            imageY = (viewSize.height - imageHeight) * 0.5
        }
        return CGRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight)
    }
}
