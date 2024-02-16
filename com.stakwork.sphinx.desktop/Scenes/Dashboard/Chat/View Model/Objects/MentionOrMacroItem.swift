//
//  MentionOrMacroItem.swift
//  Sphinx
//
//  Created by James Carucci on 6/9/23.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation
import Cocoa

public enum MentionOrMacroType{
    case mention
    case macro
}


class MentionOrMacroItem: NSObject {
    
    var type: MentionOrMacroType
    var displayText: String =  ""
    var action: (()->())?
    var image: NSImage? = nil
    var icon: String? = nil
    var imageLink: String? = nil
    
    init(
        type: MentionOrMacroType,
        displayText: String,
        image: NSImage? = nil,
        imageLink: String? = nil,
        icon: String? = nil,
        action: (() -> ())?
    ) {
        self.type = type
        self.displayText = displayText
        self.action = action
        self.image = image
        self.icon = icon
        self.imageLink = imageLink
    }
}

