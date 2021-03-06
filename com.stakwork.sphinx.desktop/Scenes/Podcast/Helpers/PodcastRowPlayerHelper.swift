//
//  PodcastRowPlayerHelper.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 15/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import AVKit

class PodcastRowPlayerHelper {
    
    weak var delegate: PodcastPlayerDelegate?
    
    var currentTime : Int = 0
    var playedSeconds: Int = 0

    var duration : Double? = nil
    var item: AVPlayerItem? = nil
    
    var playingTimer : Timer? = nil
    var playing = false
    
    var progressCallback: (Double, Double) -> Void = { (_, _) in }
    var endCallback: () -> Void = {}
    var pauseCallback: () -> Void = {}
    
    var messageId : Int? = nil
    var podcastComment: PodcastComment? = nil
    var podcastPaymentsHelper = PodcastPaymentsHelper()
    var podcast: PodcastFeed? = nil
    
    let customAudioPlayer = PodcastRowAudioPlayer.sharedInstance
    
    func createPlayerItemWith(podcastComment: PodcastComment,
                              podcast: PodcastFeed?,
                              delegate: PodcastPlayerDelegate,
                              for messageId: Int,
                              completion: @escaping (Int) -> ()) {
        
        self.podcastComment = podcastComment
        self.podcast = podcast
        self.delegate = delegate
        
        if let urlString = podcastComment.url, let url = URL(string: urlString) {
            
            if self.item != nil {
                let _ = self.getAudioDuration()
                completion(messageId)
                return
            }
            
            let asset = AVAsset(url: url)
            asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                if self.item == nil {
                    self.item = AVPlayerItem(asset: asset)
                }
                let _ = self.getAudioDuration()
                DispatchQueue.main.async {
                    completion(messageId)
                }
            })
        }
    }
    
    func reset() {
        stopPlaying()
        customAudioPlayer.reset()
    }
    
    func setInitialTime(startTime: Double) {
        if currentTime == 0 {
            currentTime = Int(startTime)
        }
    }
    
    func getAudioDuration() -> Double {
        if let duration = duration {
            return duration
        }
        guard let item = item else {
            return 0
        }
        duration = Double(item.asset.duration.value) / Double(item.asset.duration.timescale)
        return duration!
    }
    
    func playAudioFrom(messageId: Int) -> Bool {
        guard let item = item else {
            return false
        }
        
        if playing {
            pausePlayingAudio()
            return false
        }
        
        self.messageId = messageId
        
        customAudioPlayer.prepareAudioPlayer(item: item)
        shouldPlay()
        return true
    }
    
    func shouldPlay() {
        playingTimer?.invalidate()
        playingTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(updateCurrentTime), userInfo: nil, repeats: true)
        
        playing = true
        
        setResumingTime()
        customAudioPlayer.play()
    }
    
    func setCallbacks(progressCallback: @escaping (Double, Double) -> (), endCallback: @escaping () -> (), pauseCallback: @escaping () -> ()) {
        self.progressCallback = progressCallback
        self.endCallback = endCallback
        self.pauseCallback = pauseCallback
    }
    
    func pausePlayingAudio() {
        stopPlaying()
        pauseCallback()
    }
    
    func stopPlaying() {
        customAudioPlayer.stop()
        playing = false
        playingTimer?.invalidate()
        playingTimer = nil
    }
    
    func setResumingTime(force: Bool = false) {
        if currentTime > 0 || force {
            customAudioPlayer.setCurrentTime(currentTime: currentTime)
        }
    }
    
    func seekTo(progress: Double, play: Bool) {
        if let item = item {
            let duration = Double(item.asset.duration.value) / Double(item.asset.duration.timescale)
            currentTime = Int(duration * progress)
            setResumingTime(force: true)
        }
        
        if play { shouldPlay() }
    }
    
    func shouldUpdateTimeLabels(progress: Double) {
        guard let item = item else {
            return
        }
        let duration = Double(item.asset.duration.value) / Double(item.asset.duration.timescale)
        let currentTime = (duration * progress)
        
        delegate?.shouldUpdateLabels(duration: Int(duration), currentTime: Int(currentTime))
    }
    
    @objc func updateCurrentTime() {
        if let audioPlayerDuration = customAudioPlayer.getDuration(), let audioPlayerCurrentTime = customAudioPlayer.getCurrentTime(), audioPlayerDuration > 0 {
            if audioPlayerCurrentTime > currentTime {
                if audioPlayerCurrentTime == currentTime + 1 {
                    updatePlayedTime()
                }
            }
            currentTime = audioPlayerCurrentTime
            
            if audioPlayerCurrentTime > 0 {
                progressCallback(audioPlayerDuration, Double(audioPlayerCurrentTime))
            }
        } else {
            audioDidFinishPlaying()
        }
    }
    
    func updatePlayedTime() {
        delegate?.shouldToggleLoadingWheel(loading: false)
        
        playedSeconds = playedSeconds + 1
        
        if playedSeconds > 0 && playedSeconds % PodcastPlayerHelper.kSecondsBeforePMT == 0 {
            DispatchQueue.global().async {
                self.processPayment()
            }
        }
    }
    
    func processPayment() {
        let itemId = self.podcastComment?.itemId ?? 0
        let clipSenderPK = self.podcastComment?.pubkey
        let uuid = self.podcastComment?.uuid
        self.podcastPaymentsHelper.processPaymentsFor(podcastFeed: self.podcast, itemId: itemId, currentTime: Int(self.currentTime), clipSenderPubKey: clipSenderPK, uuid: uuid)
    }
    
    func audioDidFinishPlaying() {
        resetCurrentAudio()
        endCallback()
    }
    
    func resetCurrentAudio() {
        playing = false
        currentTime = 0
        playingTimer?.invalidate()
        playingTimer = nil
    }
}
