//
//  EditViewController+VideoControl.swift
//  Edit
//
//  Created by FunWidget on 2024/5/30.
//

import UIKit
import AVFoundation

extension EditViewController: EditorVideoControlViewDelegate {
    func controlView(_ controlView: EditorVideoControlView, didPlayAt isSelected: Bool) {
        stopPlayVideo()
        if isSelected {
            editorView.playVideo()
            startPlayVideo()
        }else {
            editorView.pauseVideo()
        }
    }
    func controlView(_ controlView: EditorVideoControlView, leftDidChangedValidRectAt time: CMTime) {
        controlViewStartChangeTime(at: time)
        updateVideoTimeRange()
    }
    func controlView(_ controlView: EditorVideoControlView, leftEndChangedValidRectAt time: CMTime) {
        controlViewStartEndTime(at: time)
        updateVideoTimeRange()
    }
    func controlView(_ controlView: EditorVideoControlView, rightDidChangedValidRectAt time: CMTime) {
        controlViewStartChangeTime(at: time)
        updateVideoTimeRange()
    }
    func controlView(_ controlView: EditorVideoControlView, rightEndChangedValidRectAt time: CMTime) {
        controlViewStartEndTime(at: time)
        updateVideoTimeRange()
    }
    func controlViewStartChangeTime(at time: CMTime) {
        if editorView.isVideoPlaying {
            editorView.pauseVideo()
        }
        editorView.seekVideo(to: time)
    }
    func controlViewStartEndTime(at time: CMTime) {
        editorView.seekVideo(to: time)
    }
    
    func updateVideoTimeRange() {
        if editorView.videoDuration.seconds == videoControlView.middleDuration {
            editorView.videoStartTime = nil
            editorView.videoEndTime = nil
        }else {
            editorView.videoStartTime = videoControlView.startTime
            editorView.videoEndTime = videoControlView.endTime
        }
        checkFinishButtonState()
    }
    
    func controlView(_ controlView: EditorVideoControlView, progressLineDragBeganAt time: CMTime) {
        controlViewStartChangeTime(at: time)
    }
    func controlView(_ controlView: EditorVideoControlView, progressLineDragChangedAt time: CMTime) {
        controlViewStartChangeTime(at: time)
    }
    func controlView(_ controlView: EditorVideoControlView, progressLineDragEndAt time: CMTime) {
        controlViewStartEndTime(at: time)
    }
    func controlView(_ controlView: EditorVideoControlView, didScrollAt time: CMTime) {
        controlViewStartChangeTime(at: time)
        updateVideoTimeRange()
    }
    func controlView(_ controlView: EditorVideoControlView, endScrollAt time: CMTime) {
        controlViewStartEndTime(at: time)
        updateVideoTimeRange()
    }
}
