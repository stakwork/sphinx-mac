//
//  CommonPodcastCommentCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import AVKit

class CommonPodcastCommentCollectionViewItem: CommonReplyCollectionViewItem, AudioCollectionViewItem {

    @IBOutlet weak var lockSign: NSTextField!
    @IBOutlet weak var audioBubbleView: PodcastCommentBubbleView!
    @IBOutlet weak var audioPlayerContainer: NSView!
    @IBOutlet weak var playButton: CustomButton!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    @IBOutlet weak var audioTrackLine: NSBox!
    @IBOutlet weak var audioProgressLine: NSBox!
    @IBOutlet weak var progressLabel: NSTextField!
    @IBOutlet weak var durationLabel: NSTextField!
    @IBOutlet weak var currentTimeDot: NSBox!
    @IBOutlet weak var currentTimeDotLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var messageBubbleView: MessageBubbleView!
    @IBOutlet weak var mouseDraggableView: MouseDraggableView!
    
    static let kAudioBubbleHeight: CGFloat = 70.0
    static let kAudioSentBubbleWidth: CGFloat = 352.0
    static let kAudioReceivedBubbleWidth: CGFloat = 350.0
    
    var wasPlayingOnDrag = false
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.Sphinx.Text, controls: [])
            playButton.alphaValue = loading ? 0.0 : 1.0
        }
    }
    
    var podcastComment: PodcastComment? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mouseDraggableView.delegate = self
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
        return messageBubbleView
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)
        messageRow.configurePodcastPlayer()
        
        titleLabel.stringValue = messageRow.transactionMessage.podcastComment?.title ?? "title.not.available".localized
        
        resetPlayer()
    }
    
    func loadAudio(podcastComment: PodcastComment, podcast: PodcastFeed?, messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        toggleLoadingAudio(loading: true)

        let messageId = messageRow.transactionMessage.id
        
        messageRow.podcastPlayerHelper?.setCallbacks(progressCallback: updateCurrentTime, endCallback: audioDidFinishPlaying, pauseCallback: audioDidPausePlaying)
        
        messageRow.podcastPlayerHelper?.createPlayerItemWith(podcastComment: podcastComment, podcast: podcast, delegate: self, for: messageId, completion: { (messageId) in
            if self.isDifferentRow(messageId: messageId) { return }
            self.setAudioPlayerInitialTime()
            self.audioReady()
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
        if let audioPlayerHelper = messageRow?.podcastPlayerHelper, audioPlayerHelper.currentTime > 0 {
            let playing = audioPlayerHelper.playing
            updateControls(buttonTitle: playing ? "pause" : "play_arrow", color: CommonAudioCollectionViewItem.kBlueControlsColor)
            updateCurrentTime(duration: getAudioDuration(), currentTime: Double(audioPlayerHelper.currentTime), animated: false)
        } else {
            updateControls(buttonTitle: "play_arrow", color: CommonAudioCollectionViewItem.kBlueControlsColor)
            updateTimeLabel(duration: getAudioDuration(), currentTime: 0.0)
        }
    }
    
    func getAudioDuration() -> Double {
        if let audioPlayerHelper = messageRow?.podcastPlayerHelper {
            return audioPlayerHelper.getAudioDuration()
        }
        return 0
    }
    
    func audioLoadingFailed() {
        playButton.isEnabled = false
        toggleLoadingAudio(loading: false)
    }
    
    func configureLockSign() {
        let encrypted = (messageRow?.transactionMessage.encrypted ?? false)
        lockSign.stringValue = encrypted ? "lock" : ""
    }
    
    @IBAction func playButtonTouched(_ sender: Any) {
        messageRow?.configurePodcastPlayer()
        
        if let messageId = self.messageRow?.transactionMessage.id, let audioPlayerHelper = messageRow?.podcastPlayerHelper {
            audioDelegate?.shouldStopPlayingAudios(item: self)
            
            let didPlay = audioPlayerHelper.playAudioFrom(messageId: messageId)
            loading = didPlay
            
            if didPlay {
                updateControls(buttonTitle: "pause", color: CommonAudioCollectionViewItem.kBlueControlsColor)
            }
        }
    }
    
    func setAudioPlayerInitialTime() {
        if let audioPlayerHelper = messageRow?.podcastPlayerHelper {
            let ts = messageRow?.transactionMessage.podcastComment?.timestamp ?? 0
            audioPlayerHelper.setInitialTime(startTime: Double(ts))
        }
    }
    
    func getTimePercentage() -> Double {
        let totalWidth = CGFloat(audioTrackLine.frame.size.width) - CGFloat(currentTimeDot.frame.size.width)
        let startTimePercentage = currentTimeDotLeftConstraint.constant * 100 / totalWidth
        return Double(startTimePercentage)
    }
    
    func audioDidPausePlaying() {
        updateControls(buttonTitle: "play_arrow", color: CommonAudioCollectionViewItem.kBlueControlsColor)
    }
    
    func audioDidFinishPlaying() {
        DelayPerformedHelper.performAfterDelay(seconds: 0.2, completion: {
            self.resetPlayer()
        })
    }
    
    func stopPlaying(shouldReset: Bool = false) {
        if let audioPlayerHelper = messageRow?.podcastPlayerHelper {
            audioPlayerHelper.stopPlaying()
            
            if audioPlayerHelper.currentTime > 0 {
                updateControls(buttonTitle: "play_arrow", color: CommonAudioCollectionViewItem.kBlueControlsColor, dotVisible: true)
            }
        }
        
        if shouldReset {
            messageRow?.podcastPlayerHelper?.reset()
            messageRow?.podcastPlayerHelper = nil
        }
    }
    
    func resetPlayer() {
        updateControls(buttonTitle: "play_arrow", color: CommonAudioCollectionViewItem.kBlueControlsColor, dotVisible: false)
        updateTimeLabel(duration: 0, currentTime: 0)
        currentTimeDotLeftConstraint.constant = 0
        currentTimeDot.superview?.layoutSubtreeIfNeeded()
    }
    
    func updateCurrentTime(duration: Double, currentTime: Double) {
        updateCurrentTime(duration: duration, currentTime: currentTime, animated: true)
    }
    
    func updateCurrentTime(duration: Double, currentTime: Double, animated: Bool) {
        let totalWidth = CGFloat(audioTrackLine.frame.size.width)
        let expectedWith = (CGFloat(currentTime) * totalWidth) / CGFloat(duration)
        
        if !expectedWith.isFinite || expectedWith < 0 {
            return
        }
        
        currentTimeDotLeftConstraint.constant = expectedWith
        updateTimeLabel(duration: duration, currentTime: currentTime)
        
        if !animated {
            currentTimeDot.superview?.layoutSubtreeIfNeeded()
            return
        }
        
        AnimationHelper.animateViewWith(duration: 0.05, animationsBlock: {
            self.currentTimeDot.superview?.layoutSubtreeIfNeeded()
        })
    }
    
    func updateTimeLabel(duration: Double, currentTime: Double) {
        playButton.isEnabled = duration > 0
        
        let (dHours, dMinutes, dSeconds) = Int(duration).getTimeElements()
        durationLabel.stringValue = "\(dHours):\(dMinutes):\(dSeconds)"
        
        let (cHours, cMinutes, cSeconds) = Int(currentTime).getTimeElements()
        progressLabel.stringValue = "\(cHours):\(cMinutes):\(cSeconds)"
    }
    
    func updateControls(buttonTitle: String, color: NSColor, dotVisible: Bool = true) {
        currentTimeDot.alphaValue = dotVisible ? 1.0 : 0.0
        if #available(OSX 10.14, *) {
            playButton.contentTintColor = color
        }
        playButton.title = buttonTitle
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let replyTopPadding = CommonChatCollectionViewItem.getReplyTopPadding(message: messageRow.transactionMessage)
        let audioBubbleHeight = kAudioBubbleHeight + Constants.kBubbleTopMargin + Constants.kBubbleBottomMargin + replyTopPadding
        
        if messageRow.transactionMessage.hasMessageContent() {
            let bubbleWidth = messageRow.isIncoming() ? kAudioReceivedBubbleWidth : kAudioSentBubbleWidth
            let margin = messageRow.isIncoming() ? Constants.kBubbleReceivedArrowMargin : Constants.kBubbleSentArrowMargin
            let bubbleSize = MessageBubbleView.getBubbleSizeFrom(messageRow: messageRow, containerViewWidth: bubbleWidth, bubbleMargin: margin)
            
            return bubbleSize.height + audioBubbleHeight + Constants.kComposedBubbleMessageMargin
        }
        
        return audioBubbleHeight
    }
}

extension CommonPodcastCommentCollectionViewItem : PodcastPlayerDelegate {
    func shouldToggleLoadingWheel(loading: Bool) {
        toggleLoadingAudio(loading: loading)
    }
    
    func shouldUpdateLabels(duration: Int, currentTime: Int) {
        guard let podcastPlayer = messageRow?.podcastPlayerHelper else {
            return
        }
        
        updateCurrentTime(duration: Double(duration), currentTime: Double(currentTime))

        if currentTime >= duration && podcastPlayer.playing {
            audioDidFinishPlaying()
        }
    }
}

extension CommonPodcastCommentCollectionViewItem : MouseDraggableViewDelegate {
    func mouseDownOn(x: CGFloat) {
        guard let podcastPlayer = messageRow?.podcastPlayerHelper else {
            return
        }
        
        wasPlayingOnDrag = podcastPlayer.playing
        podcastPlayer.stopPlaying()
        mouseDraggedOn(x: x)
    }
    
    func mouseUpOn(x: CGFloat) {
        guard let podcastPlayer = messageRow?.podcastPlayerHelper else {
            return
        }
        loading = wasPlayingOnDrag
        let progress = ((currentTimeDotLeftConstraint.constant * 100) / audioTrackLine.frame.size.width) / 100
        podcastPlayer.seekTo(progress: Double(progress), play: wasPlayingOnDrag)
        wasPlayingOnDrag = false
    }
    
    func mouseDraggedOn(x: CGFloat) {
        guard let podcastPlayer = messageRow?.podcastPlayerHelper else {
            return
        }
        
        let totalProgressWidth = audioTrackLine.frame.size.width
        let translation = (x < 0) ? 0 : ((x > totalProgressWidth) ? totalProgressWidth : x)
        let progress = ((translation * 100) / audioTrackLine.frame.size.width) / 100

        podcastPlayer.shouldUpdateTimeLabels(progress: Double(progress))
    }
}
