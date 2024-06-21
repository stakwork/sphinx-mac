//
//  PodcastPlayerCollectionViewItem+Delegates.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 06/02/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation

extension PodcastPlayerCollectionViewItem : MouseDraggableViewDelegate {
    func mouseDownOn(x: CGFloat) {
        dragging = true
//        livePodcastDataSource?.resetData()
        
        mouseDraggedOn(x: x)
    }
    
    func mouseUpOn(x: CGFloat) {
        dragging = false
        
        guard let episode = podcast.getCurrentEpisode(), let duration = episode.duration else {
            return
        }
        
        let progress = ((progressLineWidth.constant * 100) / durationLine.frame.size.width) / 100
        let currentTime = Int(Double(duration) * progress)
        
        guard let podcastData = podcast.getPodcastData(
            currentTime: currentTime
        ) else {
            return
        }
        
        podcastPlayerController.submitAction(
            UserAction.Seek(podcastData)
        )
        
        delegate?.shouldSyncPodcast()
    }
    
    func mouseDraggedOn(x: CGFloat) {
        let totalProgressWidth = CGFloat(durationLine.frame.size.width)
        let translation = (x < 0) ? 0 : ((x > totalProgressWidth) ? totalProgressWidth : x)
        
        if !translation.isFinite || translation < 0 {
            return
        }

        progressLineWidth.constant = translation
        progressLine.layoutSubtreeIfNeeded()
        
        guard let episode = podcast.getCurrentEpisode(), let duration = episode.duration else {
            return
        }
        
        let progress = ((progressLineWidth.constant * 100) / durationLine.frame.size.width) / 100
        let currentTime = Int(Double(duration) * progress)
        setProgress(duration: duration, currentTime: currentTime)
    }
}

extension PodcastPlayerCollectionViewItem : PlayerDelegate {
    func loadingState(_ podcastData: PodcastData) {
        if podcastData.podcastId != podcast?.feedID {
            return
        }
        
        configureControls(playing: true)
        showInfo()
        audioLoading = true
    }
    
    func playingState(_ podcastData: PodcastData) {
        if dragging {
            return
        }
        if podcastData.podcastId != podcast?.feedID {
            return
        }
        delegate?.shouldReloadEpisodesTable()
        configureControls(playing: true)
        setProgress(duration: podcastData.duration ?? 0, currentTime: podcastData.currentTime ?? 0)
        addMessagesFor(ts: podcastData.currentTime ?? 0)
        audioLoading = false
    }
    
    func pausedState(_ podcastData: PodcastData) {
        if podcastData.podcastId != podcast?.feedID {
            return
        }
        delegate?.shouldReloadEpisodesTable()
        configureControls(playing: false)
        setProgress(duration: podcastData.duration ?? 0, currentTime: podcastData.currentTime ?? 0)
        audioLoading = false
    }
    
    func endedState(_ podcastData: PodcastData) {
        if podcastData.podcastId != podcast?.feedID {
            return
        }
        configureControls(playing: false)
        setProgress(duration: podcastData.duration ?? 0, currentTime: podcastData.currentTime ?? 0)
    }
    
    func errorState(_ podcastData: PodcastData) {
        if podcastData.podcastId != podcast?.feedID {
            return
        }
        audioLoading = false
        configureControls(playing: false)
        
//        delegate?.didFailPlayingPodcast()
    }
}

extension PodcastPlayerCollectionViewItem : BoostButtonViewDelegate {
    func didTouchButton() {
        let amount: Int = UserDefaults.Keys.tipAmount.get(defaultValue: 100)
        
        if let episode = podcast.getCurrentEpisode() {
            
            let itemID = episode.itemID
            let currentTime = podcast.getCurrentEpisode()?.currentTime ?? 0
            
            if let boostMessage = feedBoostHelper.getBoostMessage(itemID: itemID, amount: amount, currentTime: currentTime) {
                
                feedBoostHelper.processPayment(itemID: itemID, amount: amount, currentTime: currentTime)
                
                feedBoostHelper.sendBoostMessage(
                    message: boostMessage,
                    episodeId: episode.itemID,
                    amount: amount,
                    completion: { (message, success) in
                        guard let _ = message else {
                            return
                        }
//                        self.addToLiveMessages(message: message)
//                        self.livePodcastDataSource?.insert(messages: [message])
                    }
                )
            }
        }
    }
}
