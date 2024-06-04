//
//  EditorAdjusterView+ContentView.swift
//  Example
//
//  Created by Slience on 2023/1/19.
//

import UIKit
import AVFoundation

extension EditorAdjusterView {
    
    var isVideoPlayToEndTimeAutoPlay: Bool {
        get { contentView.isVideoPlayToEndTimeAutoPlay}
        set { contentView.isVideoPlayToEndTimeAutoPlay = newValue }
    }
}

extension EditorAdjusterView: EditorContentViewDelegate {
    
    func contentView(rotateVideo contentView: EditorContentView) {
        resetVideoRotate(true)
    }
    func contentView(resetVideoRotate contentView: EditorContentView) {
        resetVideoRotate(false)
    }

    func contentView(_ contentView: EditorContentView, videoDidPlayAt time: CMTime) {
        frameView.videoSliderView.isPlaying = true
        delegate?.editorAdjusterView(self, videoDidPlayAt: time)
    }
    func contentView(_ contentView: EditorContentView, videoDidPauseAt time: CMTime) {
        frameView.videoSliderView.isPlaying = false
        delegate?.editorAdjusterView(self, videoDidPauseAt: time)
    }
    func contentView(videoReadyForDisplay contentView: EditorContentView) {
        delegate?.editorAdjusterView(videoReadyForDisplay: self)
        updateControlScaleSize()
    }
    func contentView(resetPlay contentView: EditorContentView) {
        delegate?.editorAdjusterView(videoResetPlay: self)
        frameView.videoSliderView.setPlayDuration(0, isAnimation: false)
    }
    func contentView(_ contentView: EditorContentView, isPlaybackLikelyToKeepUp: Bool) {
        delegate?.editorAdjusterView(self, videoIsPlaybackLikelyToKeepUp: isPlaybackLikelyToKeepUp)
    }
    func contentView(_ contentView: EditorContentView, readyToPlay duration: CMTime) {
        if let startTime = videoStartTime, let endTime = videoEndTime {
            frameView.videoSliderView.videoDuration = endTime.seconds - startTime.seconds
        }else if let startTime = videoStartTime {
            frameView.videoSliderView.videoDuration = duration.seconds - startTime.seconds
        }else if let endTime = videoEndTime {
            frameView.videoSliderView.videoDuration = endTime.seconds
        }else {
            frameView.videoSliderView.videoDuration = duration.seconds
        }
        delegate?.editorAdjusterView(self, videoReadyToPlay: duration)
    }
    func contentView(_ contentView: EditorContentView, didChangedBuffer time: CMTime) {
        if let startTime = videoStartTime, let endTime = videoEndTime {
            frameView.videoSliderView.bufferDuration = min(
                max(0, time.seconds - startTime.seconds),
                endTime.seconds - startTime.seconds
            )
        }else if let startTime = videoStartTime {
            let videoDuration = videoDuration.seconds
            frameView.videoSliderView.bufferDuration = min(
                max(0, time.seconds - startTime.seconds),
                videoDuration - startTime.seconds
            )
        }else if let endTime = videoEndTime {
            frameView.videoSliderView.bufferDuration = min(time.seconds, endTime.seconds)
        }else {
            frameView.videoSliderView.bufferDuration = time.seconds
        }
        delegate?.editorAdjusterView(self, videoDidChangedBufferAt: time)
    }
    func contentView(_ contentView: EditorContentView, didChangedTimeAt time: CMTime) {
        var duration: Double
        if let startTime = videoStartTime, videoEndTime != nil {
            duration = time.seconds - startTime.seconds
        }else if let startTime = videoStartTime {
            let videoDuration = videoDuration.seconds
            duration = (videoDuration - startTime.seconds) * ((time.seconds - startTime.seconds) / videoDuration)
        }else {
            duration = time.seconds
        }
        frameView.videoSliderView.setPlayDuration(duration, isAnimation: true)
        delegate?.editorAdjusterView(self, videoDidChangedTimeAt: time)
    }
}

