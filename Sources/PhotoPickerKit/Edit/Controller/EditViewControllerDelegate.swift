//
//  EditViewControllerDelegate.swift
//  Edit
//
//  Created by FunWidget on 2024/5/30.
//

import UIKit
import Photos

public protocol EditViewControllerDelegate: AnyObject {
    
    /// 完成编辑
    /// - Parameters:
    ///   - editorViewController: 对应的`EditorViewController`
    ///   - asset: 当前编辑对象，asset.result 为空则没有编辑
    func editorViewController(
        _ editorViewController: EditViewController,
        didFinish asset: EditorAsset
    )
    
    /// 取消编辑
    /// - Parameter editorViewController: 对应的`EditorViewController`
    func editorViewController(
        didCancel editorViewController: EditViewController
    )
    
    // MARK: 只支持 push/pop ，跳转之前需要 navigationController?.delegate = editorViewController
    /// 转场动画时长
    func editorViewController(
        _ editorViewController: EditViewController,
        transitionDuration mode: EditorTransitionMode
    ) -> TimeInterval
    
    /// 转场过渡动画时展示的image
    /// - Parameters:
    ///   - photoEditorViewController: 对应的 PhotoEditorViewController
    func editorViewController(
        transitionPreviewImage editorViewController: EditViewController
    ) -> UIImage?
    
    /// 跳转界面时起始的视图，用于获取位置大小。与 transitioBegenPreviewFrame 一样
    func editorViewController(
        transitioStartPreviewView editorViewController: EditViewController
    ) -> UIView?
    
    /// 界面返回时对应的视图，用于获取位置大小。与 transitioEndPreviewFrame 一样
    func editorViewController(
        transitioEndPreviewView editorViewController: EditViewController
    ) -> UIView?
    
    /// 跳转界面时对应的起始位置大小
    func editorViewController(
        transitioStartPreviewFrame editorViewController: EditViewController
    ) -> CGRect?
    
    /// 界面返回时对应的位置大小
    func editorViewController(
        transitioEndPreviewFrame editorViewController: EditViewController
    ) -> CGRect?
    
}

extension EditViewControllerDelegate {
    
    func editorViewController(
        _ editorViewController: EditViewController,
        didFinish asset: EditorAsset
    ) {
        back(editorViewController)
    }
    
    func editorViewController(
        didCancel editorViewController: EditViewController
    ) {
        back(editorViewController)
    }
    
    func editorViewController(
        _ editorViewController: EditViewController,
        transitionDuration mode: EditorTransitionMode
    ) -> TimeInterval { 0.55 }
    
    func editorViewController(
        transitionPreviewImage editorViewController: EditViewController
    ) -> UIImage? { nil }
    
    func editorViewController(
        transitioStartPreviewView editorViewController: EditViewController
    ) -> UIView? { nil }
    
    func editorViewController(
        transitioEndPreviewView editorViewController: EditViewController
    ) -> UIView? { nil }
    
    func editorViewController(
        transitioStartPreviewFrame editorViewController: EditViewController
    ) -> CGRect? { nil }
    
    func editorViewController(
        transitioEndPreviewFrame editorViewController: EditViewController
    ) -> CGRect? { nil }
    
    private func back(
        _ editorViewController: EditViewController
    ) {
        if !editorViewController.config.isAutoBack {
            if let navigationController = editorViewController.navigationController,
               navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            }else {
                editorViewController.dismiss(animated: true)
            }
        }
    }
}

