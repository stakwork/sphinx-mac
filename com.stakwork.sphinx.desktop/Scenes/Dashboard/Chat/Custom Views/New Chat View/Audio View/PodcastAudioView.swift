//
//  PodcastAudioView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 15/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol PodcastAudioViewDelegate: AnyObject {
    func didTapClipPlayPauseButtonAt(time: Double)
    func shouldSeekTo(time: Double)
}

class PodcastAudioView: NSView, LoadableNib {
    
    weak var delegate: PodcastAudioViewDelegate?
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var episodeTitleLabel: NSTextField!
    @IBOutlet weak var playButtonView: NSView!
    @IBOutlet weak var playButton: CustomButton!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    @IBOutlet weak var startTimeLabel: NSTextField!
    @IBOutlet weak var endTimeLabel: NSTextField!
    @IBOutlet weak var durationViewContainer: NSView!
    @IBOutlet weak var durationView: NSBox!
    @IBOutlet weak var progressView: NSBox!
    @IBOutlet weak var currentTimeView: NSBox!
    @IBOutlet weak var mouseDraggableView: MouseDraggableView!
    @IBOutlet weak var progressViewWidthConstraint: NSLayoutConstraint!

    var audioInfo: MessageTableCellState.AudioInfo? = nil
    var dragging = false
    
    static let kViewHeight: CGFloat = 80
    
    let kDurationViewWidth: CGFloat = 214
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
        setup()
    }
    
    func setup() {
        durationViewContainer.wantsLayer = true
        durationViewContainer.layer?.masksToBounds = false
        
        loadingWheel.set(tintColor: NSColor.Sphinx.Text)
    }
    
//    func addDotGesture() {
//        let gesture = UIPanGestureRecognizer(target: self, action: #selector(wasDragged))
//        tapHandlerView.addGestureRecognizer(gesture)
//        tapHandlerView.isUserInteractionEnabled = true
//    }
//
//    @objc func wasDragged(gestureRecognizer: UIPanGestureRecognizer) {
//        guard let bubbleWidth = self.bubbleWidth else {
//            return
//        }
//
//        let x = getGestureXPosition(gestureRecognizer)
//        let progressBarWidth = bubbleWidth - kProgressBarLeftMargin - kProgressBarRightMargin
//        let progress = ((x * 100) / progressBarWidth) / 100
//
//        switch(gestureRecognizer.state) {
//        case .began:
//            delegate?.shouldToggleReplyGesture(enable: false)
//            preventUIUpdates = true
//        case .changed:
//            configureTimeWith(progress: progress)
//        case .ended:
//            delegate?.shouldToggleReplyGesture(enable: true)
//            configureTimeWith(progress: progress, shouldSync: true)
//        default:
//            break
//        }
//    }
//
//    func getGestureXPosition(_ gestureRecognizer: UIPanGestureRecognizer) -> CGFloat {
//        guard let bubbleWidth = self.bubbleWidth else {
//            return 0.0
//        }
//
//        let progressBarWidth = bubbleWidth - kProgressBarLeftMargin - kProgressBarRightMargin
//        let dotMinimumX: CGFloat = kProgressBarLeftMargin
//        let x = gestureRecognizer.location(in: self).x - dotMinimumX
//        return (x < 0) ? 0 : ((x > progressBarWidth) ? progressBarWidth : x)
//    }
    
    func configureWith(
        podcastComment: BubbleMessageLayoutState.PodcastComment,
        mediaData: MessageTableCellState.MediaData?,
        bubble: BubbleMessageLayoutState.Bubble,
        and delegate: PodcastAudioViewDelegate?
    ) {
        self.delegate = delegate
        
        durationView.fillColor = bubble.direction.isIncoming() ? NSColor.Sphinx.WashedOutReceivedText : NSColor.Sphinx.WashedOutSentText
        episodeTitleLabel.stringValue = podcastComment.title
        
        if let mediaData = mediaData, let audioInfo = mediaData.audioInfo {
            configureTimeWith(
                audioInfo: audioInfo
            )
        } else {
            startTimeLabel.stringValue = Int(podcastComment.timestamp).getPodcastTimeString()
            configureLoadingWheel(loading: true)
            progressViewWidthConstraint.constant = 0
            progressView.layoutSubtreeIfNeeded()
        }
    }
    
    func configureTimeWith(
        audioInfo: MessageTableCellState.AudioInfo
    ) {
        self.audioInfo = audioInfo
        
        playButton.title = audioInfo.playing ? "pause" : "play_arrow"
        
        configureLoadingWheel(
            loading: audioInfo.loading && !audioInfo.playing
        )
        
        if dragging {
            return
        }
        
        startTimeLabel.stringValue = Int(audioInfo.currentTime).getPodcastTimeString()
        endTimeLabel.stringValue = Int(audioInfo.duration).getPodcastTimeString()
        
        let progressBarWidth = kDurationViewWidth
        let progress = audioInfo.currentTime * 1 / audioInfo.duration
        progressViewWidthConstraint.constant = progressBarWidth * progress
        progressView.layoutSubtreeIfNeeded()
        
        mouseDraggableView.delegate = self
    }
    
    func configureTimeWith(
        progress: Double,
        shouldSync: Bool = false
    ) {
        guard let audioInfo = self.audioInfo else {
            return
        }
        
        let currentTime = audioInfo.duration * progress
        startTimeLabel.stringValue = Int(currentTime).getPodcastTimeString()
        
        let progressBarWidth = kDurationViewWidth
        progressViewWidthConstraint.constant = progressBarWidth * progress
        progressView.layoutSubtreeIfNeeded()
        
        if shouldSync {
            delegate?.shouldSeekTo(time: currentTime)

            DelayPerformedHelper.performAfterDelay(seconds: 1.0, completion: {
                self.dragging = false
            })
        }
    }
    
    func configureLoadingWheel(
        loading: Bool
    ) {
        playButton.isHidden = loading
        playButtonView.isHidden = loading
        loadingWheel.isHidden = !loading
        
        if loading {
            loadingWheel.startAnimation(nil)
        } else {
            loadingWheel.stopAnimation(nil)
        }
    }
    
    @IBAction func playPauseButtonClicked(_ sender: Any) {
        guard let audioInfo = self.audioInfo else {
            return
        }

        dragging = true

        let progressBarWidth = kDurationViewWidth
        let progress = progressViewWidthConstraint.constant / progressBarWidth
        let currentTime = audioInfo.duration * progress

        delegate?.didTapClipPlayPauseButtonAt(time: currentTime)

        DelayPerformedHelper.performAfterDelay(seconds: 1.0, completion: {
            self.dragging = false
        })
    }
    
}

extension PodcastAudioView : MouseDraggableViewDelegate {
    func mouseDownOn(x: CGFloat) {
        dragging = true
        mouseDraggedOn(x: x)
    }
    
    func mouseUpOn(x: CGFloat) {
        dragging = false
        
        let progressBarWidth = kDurationViewWidth
        let progress = ((progressViewWidthConstraint.constant * 100) / progressBarWidth) / 100
        
        configureTimeWith(progress: progress, shouldSync: true)
    }
    
    func mouseDraggedOn(x: CGFloat) {
        let totalProgressWidth = kDurationViewWidth
        let translation = (x < 0) ? 0 : ((x > totalProgressWidth) ? totalProgressWidth : x)
        
        if !translation.isFinite || translation < 0 {
            return
        }

        let progress = ((translation * 100) / totalProgressWidth) / 100
        
        configureTimeWith(progress: progress)
    }
}
