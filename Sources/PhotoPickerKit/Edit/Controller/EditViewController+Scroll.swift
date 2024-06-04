//
//  EditViewController+Scroll.swift
//  Edit
//
//  Created by FunWidget on 2024/5/30.
//

import UIKit

extension EditViewController: UIScrollViewDelegate {
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if scrollView != backgroundView {
            return nil
        }
        return editorView
    }
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView != backgroundView {
            return
        }
        if editorView.isCanZoomScale {
            scrollView.contentInset = .zero
            scrollView.contentSize = view.size
            editorView.y = 0
            editorView.height = view.height
        }else {
            scrollView.contentSize = .init(
                width: editorView.contentSize.width * scrollView.zoomScale,
                height: editorView.contentSize.height * scrollView.zoomScale
            )
            let top = backgroundInsetRect.minY
            let left = backgroundInsetRect.minX
            let right = backgroundInsetRect.minX
            let bottom = view.height - backgroundInsetRect.maxY
            scrollView.contentInset = .init(
                top: top,
                left: left,
                bottom: bottom,
                right: right
            )
            
            let contentHeight = scrollView.contentSize.height
            let viewWidth = scrollView.width - scrollView.contentInset.left - scrollView.contentInset.right
            let viewHeight = scrollView.height - scrollView.contentInset.top - scrollView.contentInset.bottom
            let offsetX = (viewWidth > scrollView.contentSize.width) ?
            (viewWidth - scrollView.contentSize.width) * 0.5 : 0
            let offsetY = (viewHeight > contentHeight) ?
            (viewHeight - contentHeight) * 0.5 : 0
            let centerX = scrollView.contentSize.width * 0.5 + offsetX
            let centerY = contentHeight * 0.5 + offsetY
            editorView.center = CGPoint(x: centerX, y: centerY)
        }
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if scrollView != backgroundView {
            return
        }
        editorView.innerZoomScale = scale
    }
}
