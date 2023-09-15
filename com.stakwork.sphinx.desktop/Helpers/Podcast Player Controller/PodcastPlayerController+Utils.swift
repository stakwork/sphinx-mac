//
//  PodcastPlayerController+Utils.swift
//  sphinx
//
//  Created by Tomas Timinskas on 18/01/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import AVKit

extension PodcastPlayerController {
    func updatePodcastObject(
        podcastId: String,
        episodeId: String? = nil,
        currentTime: Int? = nil,
        duration: Int? = nil,
        playerSpeed: Float? = nil,
        clipInfo: PodcastData.ClipInfo? = nil
    ) {
        if let _ = clipInfo {
            ///Avoid persisting state data when playing chat clips
            return
        }
        
        guard let podcast = getPodcastWith(podcastId: podcastId) else {
            return
        }
        
        ///Updates attributes on podcast object to be persisted in UserDeftaults
        
        if let episodeId = episodeId {
            podcast.currentEpisodeId = episodeId
        }
        
        if let currentTime = currentTime {
            podcast.currentTime = currentTime
        }
        
        if let duration = duration {
            podcast.duration = duration
        }
        
        if let playerSpeed = playerSpeed {
            podcast.playerSpeed = playerSpeed
        }
        
    }
    
    func getPodcastWith(podcastId: String) -> PodcastFeed? {
        var podcast: PodcastFeed? = nil
        
        if let pd = self.podcast, pd.feedID == podcastId {
            podcast = pd
        } else {
            if let contentFeed = ContentFeed.getFeedById(feedId: podcastId) {
                let podcastFeed = PodcastFeed.convertFrom(contentFeed: contentFeed)
                
                podcast = podcastFeed
            }
        }
        
        return podcast
    }
}

extension PodcastPlayerController {
    
    func invalidateTime() {
        playingTimer?.invalidate()
        playingTimer = nil
        
        paymentsTimer?.invalidate()
        paymentsTimer = nil
        
        syncPodcastTimer?.invalidate()
        syncPodcastTimer = nil
    }
    
    func configureTimer() {
        updateCurrentTime()
        
        playingTimer?.invalidate()
        playingTimer = Timer.scheduledTimer(
            timeInterval: Double(1) / Double(podcastData?.speed ?? 1.0),
            target: self,
            selector: #selector(updateCurrentTime),
            userInfo: nil,
            repeats: true
        )
        
        paymentsTimer?.invalidate()
        paymentsTimer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(updatePlayedTime),
            userInfo: nil,
            repeats: true
        )
        
        syncPodcastTimer?.invalidate()
        syncPodcastTimer = Timer.scheduledTimer(
            timeInterval: 15,
            target: self,
            selector: #selector(shouldSyncPodcast),
            userInfo: nil,
            repeats: true
        )
    }
    
    @objc func shouldSyncPodcast() {
        if let feedId = podcast?.feedID {
            FeedsManager.sharedInstance.saveContentFeedStatus(for: feedId)
        }
    }
    
    @objc func updateCurrentTime() {
        guard let player = player, let item = player.currentItem else {
            return
        }
        
        let duration = Int(Double(item.asset.duration.value) / Double(item.asset.duration.timescale))
        let currentTime = Int(round(Double(player.currentTime().value) / Double(player.currentTime().timescale)))

        guard let podcastData = podcastData else {
            return
        }
        
        self.podcastData?.currentTime = currentTime
        self.podcastData?.duration = duration
        
        updatePodcastObject(
            podcastId: podcastData.podcastId,
            currentTime: currentTime,
            duration: duration,
            clipInfo: podcastData.clipInfo
        )

        runPlayingStateUpdate()

        if currentTime >= duration {
            didEndEpisode()
        }
    }
    
    func didEndEpisode() {
        trackItemFinished(shouldSaveAction: true)
        pausePlaying()
        
        guard let podcastData = self.podcastData else {
            return
        }
        
        self.podcastData?.currentTime = 0
        
        updatePodcastObject(
            podcastId: podcastData.podcastId,
            currentTime: 0,
            clipInfo: podcastData.clipInfo
        )
        
        markEpisodeAsPlayed()
        runEndedStateUpdate()
    }
    
    func loadEpisodeImage() {
        self.playingEpisodeImage = nil
        
        if let urlString = podcast?.getCurrentEpisode()?.imageURLPath, let url = URL(string: urlString) {
            MediaLoader.loadDataFrom(
                URL: url,
                includeToken: false,
                completion: { (data, fileName) in
                    
                    if let img = NSImage(data: data) {
                        self.playingEpisodeImage = img
                    }
                }, errorCompletion: {
                    self.playingEpisodeImage = nil
                }
            )
        }
    }
    
    func markEpisodeAsPlayed() {
        guard let podcastData = self.podcastData else {
            return
        }
        
        if let podcast = getPodcastWith(podcastId: podcastData.podcastId) {
            if let episode = podcast.getEpisodeWith(id: podcastData.podcastId) {
                episode.wasPlayed = true
            }
        }
    }
}

extension PodcastPlayerController {
    
    var isPlaying: Bool {
        get {
            return player?.timeControlStatus == AVPlayer.TimeControlStatus.playing ||
                   player?.timeControlStatus == AVPlayer.TimeControlStatus.waitingToPlayAtSpecifiedRate ||
                   isLoadingOrPlaying
        }
    }
    
    var playingPodcastId: String? {
        get {
            return podcastData?.podcastId
        }
    }
    
    var playingEpisodeId: String? {
        get {
            return podcastData?.episodeId
        }
    }
    
    func isPlaying(
        podcastId: String
    ) -> Bool {
        return isPlaying && podcastData?.podcastId == podcastId
    }
    
    func isPlaying(
        episodeId: String
    ) -> Bool {
        return isPlaying && podcastData?.episodeId == episodeId
    }
    
    func isPlayerItemSetWith(
        episodeUrl: URL
    ) -> Bool {
        return ((player?.currentItem?.asset) as? AVURLAsset)?.url.absoluteString == episodeUrl.absoluteString
    }
    
    func isPlaying(
        messageId: Int
    ) -> Bool {
        return isPlaying && podcastData?.clipInfo?.messageId == messageId
    }
    
    func isPlayingRecommendations() -> Bool {
//        return isPlaying && podcastData?.podcastId == RecommendationsHelper.kRecommendationPodcastId
        return false
    }
}
