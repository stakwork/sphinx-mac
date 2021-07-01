//
//  VideoCallBubbleView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 02/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class VideoCallBubbleView : CommonBubbleView {
    
    func showIncomingVideoCallBubble(messageRow: TransactionMessageRow, size: CGSize) {
        showIncomingEmptyBubble(messageRow: messageRow, size: size)
    }
    
    func showOutgoingVideoCallBubble(messageRow: TransactionMessageRow, size: CGSize) {
        showOutgoingEmptyBubble(messageRow: messageRow, size: size)
    }
}
