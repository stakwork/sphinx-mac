//
//  CustomAudioPlayer.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 27/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import AVFoundation

protocol CustomAudioPlayerDelegate: AnyObject {
    func audioDidFinishPlaying()
}

class CustomAudioPlayer : NSObject {
    
    weak var delegate: CustomAudioPlayerDelegate?

    class var sharedInstance : CustomAudioPlayer {
        struct Static {
            static let instance = CustomAudioPlayer()
        }
        return Static.instance
    }
    
    var audioPlayer: AVAudioPlayer?
    
    func setDelegate(delegate: CustomAudioPlayerDelegate?) {
        self.delegate = delegate
    }
    
    func reset() {
        stop()
        audioPlayer = nil
    }
    
    func prepareAudioPlayer(url: URL) {
        do  {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 1.0
        } catch {
            audioPlayer = nil
        }
    }
    
    func play(atTime: Double? = nil) {
        if let atTime = atTime, atTime > 0 {
            audioPlayer?.currentTime = TimeInterval(atTime)
        }
        audioPlayer?.play()
    }
    
    func play() {
        audioPlayer?.play()
    }
    
    func stop() {
        audioPlayer?.stop()
    }
    
    func stopAndReset() {
        stop()
        audioPlayer = nil
    }
    
    func isPlaying() -> Bool {
        return audioPlayer?.isPlaying ?? false
    }
    
    func getCurrentTime() -> TimeInterval? {
        return audioPlayer?.currentTime
    }
    
    func setCurrentTime(currentTime: Double) {
        audioPlayer?.currentTime = currentTime
    }
    
    func getDuration() -> TimeInterval? {
        return audioPlayer?.duration
    }
}

extension CustomAudioPlayer  : AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            delegate?.audioDidFinishPlaying()
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {}

    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {}

    func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        player.play()
    }
}
