//
//  VideoCallHelper.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 10/07/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class VideoCallHelper {
    
    public enum CallMode: Int {
        case Audio
        case All
    }
    
    public static func getCallMode(link: String) -> CallMode {
        var mode = CallMode.All
        
        if link.contains("startAudioOnly") {
            mode = CallMode.Audio
        }
        
        return mode
    }
    
    public static func createCallMessage(mode: CallMode) -> String {
        let time = Date.timeIntervalSinceReferenceDate
        let room = "\(API.kVideoCallServer)\(TransactionMessage.kCallRoomName).\(time)"
        
        if mode == .Audio {
            return room + "#config.startAudioOnly=true"
        }
        return room
    }
    
}
