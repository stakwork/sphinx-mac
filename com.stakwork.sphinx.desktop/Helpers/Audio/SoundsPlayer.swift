//
//  PlayAudioHelper.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 14/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import AVFoundation

class SoundsPlayer {
    
    static let PaymentSent: SystemSoundID = 1008
    static let keySoundID: SystemSoundID = 1123
    static let deleteSoundID: SystemSoundID = 1155
    static let VibrateSoundID: SystemSoundID = 4095
    static let MessageReceivedSoundID: SystemSoundID = 1002
    
    public static func playKeySound() {
        NSSound.pop?.play()
    }
    
    public static func playSound(name: String) {
        let components = name.components(separatedBy: ".")

        if components.count < 2 {
            return
        }

        guard let fileExtension = components.last else {
            return
        }

        var fileName = name.replacingOccurrences(of: fileExtension, with: "")
        fileName.removeLast()

        if let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) {
            var soundId: SystemSoundID = 0

            AudioServicesCreateSystemSoundID(url as CFURL, &soundId)

            AudioServicesAddSystemSoundCompletion(soundId, nil, nil, { (soundId, clientData) -> Void in
              AudioServicesDisposeSystemSoundID(soundId)
            }, nil)

            AudioServicesPlaySystemSound(soundId)
        }
    }
}
