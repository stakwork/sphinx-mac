//
//  CommonAudioCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 26/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol AudioCollectionViewItem {
    func stopPlaying(shouldReset: Bool)
}

protocol AudioCellDelegate {
    func shouldStopPlayingAudios(item: AudioCollectionViewItem?)
}

class CommonAudioCollectionViewItem : CommonReplyCollectionViewItem, AudioCollectionViewItem {
    
    @IBOutlet weak var lockSign: NSTextField!
    @IBOutlet weak var audioBubbleView: AudioBubbleView!
    @IBOutlet weak var audioPlayerContainer: NSView!
    @IBOutlet weak var playButton: CustomButton!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    @IBOutlet weak var audioTrackLine: NSBox!
    @IBOutlet weak var audioProgressLine: NSBox!
    @IBOutlet weak var durationLabel: NSTextField!
    @IBOutlet weak var currentTimeDot: NSBox!
    @IBOutlet weak var currentTimeDotLeftConstraint: NSLayoutConstraint!
    
    static let kAudioBubbleHeight: CGFloat = 62.0
    static let kAudioSentBubbleWidth: CGFloat = 322.0
    static let kAudioReceivedBubbleWidth: CGFloat = 320.0
    
    static let kBlueControlsColor = NSColor.Sphinx.ReceivedIcon
    static let kGrayControlsColor = NSColor.Sphinx.Text
    
    var audioDuration: Double = 0
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.Sphinx.Text, controls: [])
            playButton.alphaValue = loading ? 0.0 : 1.0
        }
    }
    
    var audioData : Data? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playButton.alphaValue = 0.0
        
        audioTrackLine.alphaValue = 0.3
        audioTrackLine.wantsLayer = true
        audioTrackLine.layer?.cornerRadius = audioTrackLine.frame.size.height / 2
        
        audioProgressLine.wantsLayer = true
        audioProgressLine.layer?.cornerRadius = audioProgressLine.frame.size.height / 2
        
        currentTimeDot.wantsLayer = true
        currentTimeDot.layer?.cornerRadius = currentTimeDot.frame.size.height / 2
        
        playButton.cursor = .pointingHand
    }
    
    override func getBubbbleView() -> NSView? {
        return audioBubbleView
    }
    
    func getBubbleSize() -> CGSize {
        let isIncoming = messageRow?.transactionMessage.isIncoming() ?? false
        let bottomBoostedPadding = (messageRow?.isBoosted ?? false) ? Constants.kReactionsViewHeight : 0
        
        if isIncoming {
            return CGSize(width: CommonAudioCollectionViewItem.kAudioReceivedBubbleWidth, height: CommonAudioCollectionViewItem.kAudioBubbleHeight + bottomBoostedPadding)
        } else {
            return CGSize(width: CommonAudioCollectionViewItem.kAudioSentBubbleWidth, height: CommonAudioCollectionViewItem.kAudioBubbleHeight + bottomBoostedPadding)
        }
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)
        self.audioData = nil
        
        messageRow.configureAudioPlayer()
        
        resetPlayer()
    }
    
    func loadAudio(url: URL, messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        toggleLoadingAudio(loading: true)

        MediaLoader.loadAudio(url: url, message: messageRow.transactionMessage, completion: { (messageId, data) in
            if self.isDifferentRow(messageId: messageId) { return }
            self.audioData = data
            self.audioReady()
        }, errorCompletion: { messageId in
            if self.isDifferentRow(messageId: messageId) { return }
            self.audioLoadingFailed()
        })
    }
    
    func toggleLoadingAudio(loading: Bool) {
        self.loading = loading
    }
    
    func audioReady() {
        setCurrentTime()
        toggleLoadingAudio(loading: false)
    }
    
    func setCurrentTime() {
        if let audioPlayerHelper = messageRow?.audioHelper, audioPlayerHelper.currentTime > 0 {
            updateControls(buttonTitle: "play_arrow", color: CommonAudioCollectionViewItem.kBlueControlsColor, dotVisible: true)
            updateCurrentTime(duration: getAudioDuration(), currentTime: Double(audioPlayerHelper.currentTime), animated: false)
        } else {
            updateControls(buttonTitle: "play_arrow", color: CommonAudioCollectionViewItem.kGrayControlsColor, dotVisible: false)
            updateTimeLabel(duration: getAudioDuration(), currentTime: 0.0)
        }
    }
    
    func getAudioDuration() -> Double {
        if let audioPlayerHelper = messageRow?.audioHelper {
            if let data = self.audioData, let audioDuration = audioPlayerHelper.getAudioDuration(data: data) {
                self.audioDuration = audioDuration
            } else if let data = self.messageRow?.transactionMessage.uploadingObject?.getDecryptedData(), let audioDuration = audioPlayerHelper.getAudioDuration(data: data) {
                self.audioDuration = audioDuration
            }
        }
        return self.audioDuration
    }
    
    func audioLoadingFailed() {
        playButton.isEnabled = false
        toggleLoadingAudio(loading: false)
    }
    
    func configureLockSign() {
        let encrypted = (messageRow?.transactionMessage.encrypted ?? false) && (messageRow?.transactionMessage.hasMediaKey() ?? false)
        lockSign.stringValue = encrypted ? "lock" : ""
    }
    
    @IBAction func playButtonTouched(_ sender: Any) {
        messageRow?.configureAudioPlayer()
        
        if let data = audioData, let messageId = self.messageRow?.transactionMessage.id, let audioPlayerHelper = messageRow?.audioHelper {
            audioDelegate?.shouldStopPlayingAudios(item: self)
            
            updateControls(buttonTitle: "pause", color: CommonAudioCollectionViewItem.kBlueControlsColor, dotVisible: true)
            setAudioPlayerInitialTime(messageId: messageId, data: data)
            
            audioPlayerHelper.playAudioFrom(data: data, messageId: messageId, progressCallback: updateCurrentTime, endCallback: audioDidFinishPlaying, pauseCallback: audioDidPausePlaying)
        }
    }
    
    func setAudioPlayerInitialTime(messageId: Int, data: Data) {
        if let audioPlayerHelper = messageRow?.audioHelper {
            audioPlayerHelper.setInitialTime(messageId: messageId, data: data, startTimePercentage: getTimePercentage())
        }
    }
    
    func getTimePercentage() -> Double {
        let totalWidth = CGFloat(audioTrackLine.frame.size.width) - CGFloat(currentTimeDot.frame.size.width)
        let startTimePercentage = currentTimeDotLeftConstraint.constant * 100 / totalWidth
        return Double(startTimePercentage)
    }
    
    func audioDidPausePlaying() {
        updateControls(buttonTitle: "play_arrow", color: CommonAudioCollectionViewItem.kBlueControlsColor, dotVisible: true)
    }
    
    func audioDidFinishPlaying() {
        DelayPerformedHelper.performAfterDelay(seconds: 0.2, completion: {
            self.resetPlayer()
        })
    }
    
    func stopPlaying(shouldReset: Bool) {
        if let audioPlayerHelper = messageRow?.audioHelper {
            audioPlayerHelper.stopPlaying()
            
            if audioPlayerHelper.currentTime > 0 {
                updateControls(buttonTitle: "play_arrow", color: CommonAudioCollectionViewItem.kBlueControlsColor, dotVisible: true)
            }
        }
        
        if shouldReset {
            messageRow?.audioHelper?.reset()
            messageRow?.audioHelper = nil
        }
    }
    
    func resetPlayer() {
        updateControls(buttonTitle: "play_arrow", color: CommonAudioCollectionViewItem.kGrayControlsColor, dotVisible: false)
        updateTimeLabel(duration: getAudioDuration(), currentTime: 0.0)
        currentTimeDotLeftConstraint.constant = 0
        currentTimeDot.superview?.layoutSubtreeIfNeeded()
    }
    
    func updateCurrentTime(duration: Double, currentTime: Double) {
        updateCurrentTime(duration: duration, currentTime: currentTime, animated: true)
    }
    
    func updateCurrentTime(duration: Double, currentTime: Double, animated: Bool) {
        let totalWidth = CGFloat(audioTrackLine.frame.size.width) - CGFloat(currentTimeDot.frame.size.width)
        let expectedWith = (CGFloat(currentTime) * totalWidth) / CGFloat(duration)
        let difference = abs(expectedWith - currentTimeDotLeftConstraint.constant)
        let shouldAvoidAnimation = difference > totalWidth / 2
        
        currentTimeDotLeftConstraint.constant = expectedWith
        updateTimeLabel(duration: duration, currentTime: currentTime)
        
        if !animated || shouldAvoidAnimation {
            currentTimeDot.superview?.layoutSubtreeIfNeeded()
            return
        }
        
        AnimationHelper.animateViewWith(duration: 0.05, animationsBlock: {
            self.currentTimeDot.superview?.layoutSubtreeIfNeeded()
        })
    }
    
    func updateTimeLabel(duration: Double, currentTime: Double) {
        playButton.isEnabled = duration > 0
        let current:Int = Int(duration - currentTime)
        let minutes:Int = current / 60
        let seconds:Int = current % 60
        durationLabel.stringValue = "\(minutes):\(seconds.timeString)"
    }
    
    func updateControls(buttonTitle: String, color: NSColor, dotVisible: Bool) {
        currentTimeDot.alphaValue = dotVisible ? 1.0 : 0.0
        if #available(OSX 10.14, *) {
            playButton.contentTintColor = color
        }
        playButton.title = buttonTitle
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let replyTopPadding = CommonChatCollectionViewItem.getReplyTopPadding(message: messageRow.transactionMessage)
        let boostBottomPadding = messageRow.isBoosted ? Constants.kReactionsViewHeight : 0
        return kAudioBubbleHeight + Constants.kBubbleTopMargin + Constants.kBubbleBottomMargin + replyTopPadding + boostBottomPadding
    }
}
