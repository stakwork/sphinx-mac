//
//  AudioMessageView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol AudioMessageViewDelegate: AnyObject {
    func didTapPlayPauseButton()
}

class AudioMessageView: NSView, LoadableNib {
    
    weak var delegate: AudioMessageViewDelegate?
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var playPauseButton: CustomButton!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    @IBOutlet weak var timeLabel: NSTextField!
    @IBOutlet weak var durationViewContainer: NSView!
    @IBOutlet weak var durationView: NSBox!
    @IBOutlet weak var progressView: NSBox!
    @IBOutlet weak var currentTimeView: NSBox!
    @IBOutlet weak var progressViewWidthConstraint: NSLayoutConstraint!

//    @IBOutlet weak var tapHandlerView: UIView!
    
    static let kViewHeight: CGFloat = 60
    static let kThreadsListViewHeight: CGFloat = 72
    
    let kDurationViewWidth: CGFloat = 174

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
    
    func configureWith(
        audio: BubbleMessageLayoutState.Audio,
        mediaData: MessageTableCellState.MediaData?,
        bubble: BubbleMessageLayoutState.Bubble,
        and delegate: AudioMessageViewDelegate
    ) {
        
        self.delegate = delegate
        
        durationView.fillColor = bubble.direction.isIncoming() ? NSColor.Sphinx.WashedOutReceivedText : NSColor.Sphinx.WashedOutSentText
        
        if let audioInfo = mediaData?.audioInfo {
            playPauseButton.title = audioInfo.playing ? "pause" : "play_arrow"
            
            let progress = audioInfo.currentTime * 1 / audioInfo.duration
            progressViewWidthConstraint.constant = kDurationViewWidth * progress
            
            let current:Int = Int(audioInfo.duration - audioInfo.currentTime)
            let minutes:Int = current / 60
            let seconds:Int = current % 60
            timeLabel.stringValue = "\(minutes):\(seconds.timeString)"
            
            playPauseButton.isHidden = false
            loadingWheel.isHidden = true
            loadingWheel.stopAnimation(nil)
        } else {
            playPauseButton.isHidden = true
            loadingWheel.isHidden = false
            loadingWheel.startAnimation(nil)
            
            timeLabel.stringValue = "00:00"
            progressViewWidthConstraint.constant = 0
        }
        
        progressView.layoutSubtreeIfNeeded()
    }
    
    @IBAction func playPauseButtonClicked(_ sender: Any) {
        delegate?.didTapPlayPauseButton()
    }
}
