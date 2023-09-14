//
//  NewAudioPlayerHelper.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation
import AVFoundation

protocol AudioPlayerHelperDelegate: AnyObject {
    func progressCallback(messageId: Int?, rowIndex: Int?, duration: Double, currentTime: Double)
    func pauseCallback(messageId: Int?, rowIndex: Int?)
    func endCallback(messageId: Int?, rowIndex: Int?)
}

class NewAudioPlayerHelper : NSObject {
    
    weak var delegate: AudioPlayerHelperDelegate?
    
    var playingTimer : Timer? = nil
    var playing = false
    
    var messageId : Int? = nil
    var rowIndex : Int? = nil
    
    let customAudioPlayer = CustomAudioPlayer.sharedInstance
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getAudioDuration(data: Data) -> Double? {
        let fileURL = getDocumentsDirectory().appendingPathComponent("audio_length.wav")
        
        do {
            try data.write(to: fileURL)
        } catch {
            return 0.0
        }
        
        var lengthAudioPlayer : AVAudioPlayer?
        do  {
            lengthAudioPlayer = try AVAudioPlayer(contentsOf: fileURL)
        } catch {
            lengthAudioPlayer = nil
        }
        
        return lengthAudioPlayer?.duration
    }
    
    func playAudioFrom(
        data: Data,
        messageId: Int,
        rowIndex: Int,
        atTime: Double? = nil,
        delegate: AudioPlayerHelperDelegate?
    ) {
        self.delegate = delegate
        
        if playing {
            pausePlayingAudio()
        }
        
        playingTimer?.invalidate()
        playingTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateCurrentTime), userInfo: nil, repeats: true)
        
        self.messageId = messageId
        self.rowIndex = rowIndex
        
        let fileURL = getDocumentsDirectory().appendingPathComponent("playing.wav")
        
        do {
            try data.write(to: fileURL)
        } catch {
            return
        }
        
        playing = true
        customAudioPlayer.prepareAudioPlayer(url: fileURL)
        customAudioPlayer.play(atTime: atTime)
    }
    
    func pausePlayingAudio() {
        stopPlaying()
        
        delegate?.pauseCallback(
            messageId: messageId,
            rowIndex: rowIndex
        )
    }
    
    func stopPlaying() {
        customAudioPlayer.stop()
        playing = false
        playingTimer?.invalidate()
        playingTimer = nil
    }
    
    @objc func updateCurrentTime() {
        if let audioPlayerDuration = customAudioPlayer.getDuration(),
            let audioPlayerCurrentTime = customAudioPlayer.getCurrentTime(), audioPlayerDuration > 0 {
            
            print("PLAYER DURATION \(audioPlayerDuration)")
            print("PLAYER CURRENT TIME \(audioPlayerCurrentTime)")
            
            if audioPlayerCurrentTime > 0 {
                delegate?.progressCallback(
                    messageId: messageId,
                    rowIndex: rowIndex,
                    duration: audioPlayerDuration,
                    currentTime: audioPlayerCurrentTime
                )
            } else {
                audioDidFinishPlaying()
            }
        } else {
            audioDidFinishPlaying()
        }
    }
    
    func resetCurrentAudio() {
        playing = false
        playingTimer?.invalidate()
        playingTimer = nil
    }
    
    func isPlayingMessageWith(_ messageId: Int) -> Bool {
        return playing && self.messageId == messageId
    }
}

extension NewAudioPlayerHelper  : CustomAudioPlayerDelegate {
    func audioDidFinishPlaying() {
        resetCurrentAudio()
        
        delegate?.endCallback(
            messageId: messageId,
            rowIndex: rowIndex
        )
    }
}
