//
//  EditorViewController+EditorView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/17.
//

import UIKit
import AVFoundation

extension EditViewController: EditorViewDelegate {
    
    var isReset: Bool {
        return editorView.canReset
    }
    
    /// 编辑状态将要发生改变
    public func editorView(willBeginEditing editorView: EditorView) {
        
    }
    /// 编辑状态改变已经结束
    public func editorView(didEndEditing editorView: EditorView) {
        resetButton.isEnabled = isReset
    }
    /// 即将进入编辑状态
    public func editorView(editWillAppear editorView: EditorView) {
        
    }
    /// 已经进入编辑状态
    public func editorView(editDidAppear editorView: EditorView) {
        resetButton.isEnabled = isReset
    }
    /// 即将结束编辑状态
    public func editorView(editWillDisappear editorView: EditorView) {
    }
    /// 已经结束编辑状态
    public func editorView(editDidDisappear editorView: EditorView) {
        resetButton.isEnabled = isReset
        checkFinishButtonState()
    }
    
    // MARK: Video
    public func editorView(videoReadyForDisplay editorView: EditorView) {
        if selectedAsset.result == nil, config.video.isAutoPlay {
            editorView.playVideo()
        }
    }
    /// 视频开始播放
    public func editorView(_ editorView: EditorView, videoDidPlayAt time: CMTime) {
        videoControlView.isPlaying = true
        startPlayVideo()
        if videoCoverView != nil {
            videoCoverView?.removeFromSuperview()
            videoCoverView = nil
        }
    }
    /// 视频暂停播放
    public func editorView(_ editorView: EditorView, videoDidPauseAt time: CMTime) {
        videoControlView.isPlaying = false
        stopPlayVideo()
        
    }
    /// 视频滑动进度条发生了改变
    public func editorView(
        _ editorView: EditorView,
        videoControlDidChangedTimeAt time: TimeInterval,
        for event: VideoControlEvent
    ) {
        videoControlView.updateLineViewFrame(at: time)
    }
    
}
