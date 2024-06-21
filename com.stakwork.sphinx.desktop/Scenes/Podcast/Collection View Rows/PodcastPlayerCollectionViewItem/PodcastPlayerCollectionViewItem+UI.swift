//
//  PodcastPlayerCollectionViewItem+UI.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 06/02/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation
import AVKit

extension PodcastPlayerCollectionViewItem {
    func setupView() {
        audioLoading = podcastPlayerController.isPlaying(podcastId: podcast.feedID)
        
        podcastSatsView.configureWith(chat: chat)
        showInfo()
        configureControls()
    }
    
    func addMessagesFor(ts: Int) {
//        if !podcastPlayerController.isPlaying {
//            return
//        }
//        
//        if let liveM = liveMessages[ts] {
//            livePodcastDataSource?.insert(messages: liveM)
//        }
    }
    
    func showInfo() {
        if let imageURL = podcast.getImageURL() {
            loadImage(imageURL: imageURL)
        }

        episodeLabel.stringValue = podcast.getCurrentEpisode()?.title ?? ""
        
        loadTime()
        loadMessages()
    }
    
    func loadMessages() {
//        liveMessages = [:]
//
//        guard let episodeId = podcast.getCurrentEpisode()?.itemID else {
//            return
//        }
//        let messages = TransactionMessage.getLiveMessagesFor(chat: chat, episodeId: episodeId)
//
//        for m in messages {
//            addToLiveMessages(message: m)
//        }
//
//        if livePodcastDataSource == nil {
//            livePodcastDataSource = PodcastLiveDataSource(collectionView: liveCollectionView, scrollView: liveScrollView, chat: chat)
//        }
//        livePodcastDataSource?.resetData()
    }
    
    func addToLiveMessages(message: TransactionMessage) {
//        if let ts = message.getTimeStamp() {
//            var existingM = liveMessages[ts] ?? Array<TransactionMessage>()
//            existingM.append(message)
//            liveMessages[ts] = existingM
//        }
    }
    
    func loadTime() {
        let episode = podcast.getCurrentEpisode()
        
        if let duration = episode?.duration {
            setProgress(
                duration: duration,
                currentTime: episode?.currentTime ?? 0
            )
        } else if let url = episode?.getAudioUrl() {
            audioLoading = true
            
            setProgress(
                duration: 0,
                currentTime: 0
            )
            
            let asset = AVAsset(url: url)
            asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                let duration = Int(Double(asset.duration.value) / Double(asset.duration.timescale))
                episode?.duration = duration
                
                DispatchQueue.main.async {
                    self.setProgress(
                        duration: duration,
                        currentTime: episode?.currentTime ?? 0
                    )
                    self.audioLoading = false
                }
            })
        }
    }
    
    func setProgress(
        duration: Int,
        currentTime: Int
    ) {
        let currentTimeString = currentTime.getPodcastTimeString()
        
        currentTimeLabel.stringValue = currentTimeString
        durationLabel.stringValue = duration.getPodcastTimeString()
        
        let progress = (Double(currentTime) * 100 / Double(duration))/100
        let durationLineWidth = self.view.frame.width - kDurationLineMargins
        var progressWidth = durationLineWidth * CGFloat(progress)

        if !progressWidth.isFinite || progressWidth < 0 {
            progressWidth = 0
        }

        progressLineWidth.constant = progressWidth
        progressLine.layoutSubtreeIfNeeded()
    }
    
    func loadImage(imageURL: URL?) {
        guard let url = imageURL else {
            episodeImageView.image = NSImage(named: "podcastPlaceholder")!
            return
        }
        
        episodeImageView.sd_setImage(
            with: url,
            placeholderImage: NSImage(named: "podcastPlaceholder"),
            options: [.highPriority],
            progress: nil
        )
    }
    
    func configureControls(
        playing: Bool? = nil
    ) {
        let isPlaying = playing ?? podcastPlayerController.isPlaying(podcastId: podcast.feedID)
        playPauseButton.title = isPlaying ? "pause" : "play_arrow"

        let selectedValue = podcast.playerSpeed.speedDescription + "x"
        
        speedButton.removeAllItems()
        speedButton.addItems(withTitles: speedValues)

        let selectedIndex = speedValues.firstIndex(of: selectedValue)
        speedButton.selectItem(at: selectedIndex ?? 2)
        
        mouseDraggableView.delegate = self
    }
}
