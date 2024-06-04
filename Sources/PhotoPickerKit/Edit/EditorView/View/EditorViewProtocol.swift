//
//  EditorViewProtocol.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/5.
//

import UIKit
import AVFoundation

public protocol EditorViewDelegate: AnyObject {
    /// 编辑状态将要发生改变
    func editorView(willBeginEditing editorView: EditorView)
    /// 编辑状态改变已经结束
    func editorView(didEndEditing editorView: EditorView)
    /// 即将进入编辑状态
    func editorView(editWillAppear editorView: EditorView)
    /// 已经进入编辑状态
    func editorView(editDidAppear editorView: EditorView)
    /// 即将结束编辑状态
    func editorView(editWillDisappear editorView: EditorView)
    /// 已经结束编辑状态
    func editorView(editDidDisappear editorView: EditorView)

    // MARK: Video
    /// 视频开始播放
    func editorView(_ editorView: EditorView, videoDidPlayAt time: CMTime)
    /// 视频暂停播放
    func editorView(_ editorView: EditorView, videoDidPauseAt time: CMTime)
    func editorView(videoReadyForDisplay editorView: EditorView)
    func editorView(videoResetPlay editorView: EditorView)
    func editorView(_ editorView: EditorView, videoIsPlaybackLikelyToKeepUp: Bool)
    func editorView(_ editorView: EditorView, videoReadyToPlay duration: CMTime)
    func editorView(_ editorView: EditorView, videoDidChangedBufferAt time: CMTime)
    /// 视频播放时间发生了改变
    func editorView(_ editorView: EditorView, videoDidChangedTimeAt time: CMTime)
    /// 视频滑动进度条发生了改变
    func editorView(
        _ editorView: EditorView,
        videoControlDidChangedTimeAt time: TimeInterval,
        for event: VideoControlEvent
    )
}

public extension EditorViewDelegate {
    func editorView(willBeginEditing editorView: EditorView) { }
    func editorView(didEndEditing editorView: EditorView) { }
    func editorView(editWillAppear editorView: EditorView) { }
    func editorView(editDidAppear editorView: EditorView) { }
    func editorView(editWillDisappear editorView: EditorView) { }
    func editorView(editDidDisappear editorView: EditorView) { }

    func editorView(_ editorView: EditorView, videoDidPlayAt time: CMTime) { }
    func editorView(_ editorView: EditorView, videoDidPauseAt time: CMTime) { }
    func editorView(videoReadyForDisplay editorView: EditorView) { }
    func editorView(videoResetPlay contentView: EditorView) { }
    func editorView(_ editorView: EditorView, videoIsPlaybackLikelyToKeepUp: Bool) { }
    func editorView(_ editorView: EditorView, videoReadyToPlay duration: CMTime) { }
    func editorView(_ editorView: EditorView, videoDidChangedBufferAt time: CMTime) { }
    func editorView(_ editorView: EditorView, videoDidChangedTimeAt time: CMTime) { }
    func editorView(
        _ editorView: EditorView,
        videoControlDidChangedTimeAt time: CMTime,
        for event: VideoControlEvent
    ) { }
}
