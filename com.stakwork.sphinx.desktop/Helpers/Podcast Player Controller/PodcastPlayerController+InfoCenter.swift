//
//  PodcastPlayerController+InfoCenter.swift
//  sphinx
//
//  Created by Tomas Timinskas on 13/01/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Cocoa
import MediaPlayer

extension PodcastPlayerController {
    
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
    
    func shouldSkip15Back() {
        let newTime = (self.podcastData?.currentTime ?? 0) - kSkipBackSeconds
        self.podcastData?.currentTime = newTime
        self.podcast?.currentTime = newTime

        if let podcastData = self.podcastData {
            self.seek(podcastData)
        }
    }
    
    func shouldSkip30Forward() {
        let newTime = (self.podcastData?.currentTime ?? 0) + kSkipForwardSeconds
        self.podcastData?.currentTime = newTime
        self.podcast?.currentTime = newTime

        if let podcastData = self.podcastData {
            self.seek(podcastData)
        }
    }
    
    func shouldPlay() {
        if isPlaying {
            return
        }
        
        if let podcastData = self.podcastData {
            self.play(podcastData)
        }
    }
    
    func shouldPause() {
        if !isPlaying {
            return
        }
        
        if let podcastData = self.podcastData {
            self.pause(podcastData)
        }
    }
}
