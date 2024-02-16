//
//  JoinVideoCallView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 02/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol JoinCallViewDelegate: AnyObject {
    func didTapCopyLink()
    func didTapAudioButton()
    func didTapVideoButton()
}

class JoinVideoCallView: NSView, LoadableNib {
    
    weak var delegate: JoinCallViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var videoButtonContainer: NSBox!
    @IBOutlet weak var audioButtonContainer: NSBox!
    @IBOutlet weak var audioButton: CustomButton!
    @IBOutlet weak var videoButton: CustomButton!
    @IBOutlet weak var copyButton: CustomButton!
    
    static let kViewHeight: CGFloat = 206
    static let kViewAudioOnlyHeight: CGFloat = 158
    
    public enum CallButton: Int {
        case Audio
        case Video
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        
        audioButtonContainer.wantsLayer = true
        audioButtonContainer.layer?.cornerRadius = 8

        videoButtonContainer.wantsLayer = true
        videoButtonContainer.layer?.cornerRadius = 8
        
        audioButton.cursor = .pointingHand
        videoButton.cursor = .pointingHand
        copyButton.cursor = .pointingHand
    }
    
    func configureWith(
        callLink: BubbleMessageLayoutState.CallLink,
        and delegate: JoinCallViewDelegate
    ) {
        self.delegate = delegate
        
        videoButtonContainer.isHidden = callLink.callMode == .Audio
    }
    
    func configure(delegate: JoinCallViewDelegate, link: String) {
        self.delegate = delegate
        
        configureWith(link: link)
    }
    
    func configureWith(link: String) {
        let mode = VideoCallHelper.getCallMode(link: link)
        
        audioButtonContainer.isHidden = false
        videoButtonContainer.isHidden = false
        
        switch (mode) {
        case .Audio:
            videoButtonContainer.isHidden = true
            break
        default:
            break
        }
    }
    
    @IBAction func callButtonTouched(_ sender: Any) {
        guard let sender = sender as? NSButton else {
            return
        }

        switch(sender.tag) {
        case CallButton.Audio.rawValue:
            delegate?.didTapAudioButton()
            break
        case CallButton.Video.rawValue:
            delegate?.didTapVideoButton()
            break
        default:
            break
        }
    }
    
    @IBAction func copyLinkButtonTouched(_ sender: Any) {
        delegate?.didTapCopyLink()
    }
    
}
