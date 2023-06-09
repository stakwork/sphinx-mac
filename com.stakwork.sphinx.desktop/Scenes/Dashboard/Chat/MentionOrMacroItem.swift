//
//  MentionOrMacroItem.swift
//  Sphinx
//
//  Created by James Carucci on 6/9/23.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation


public enum MentionOrMacroType{
    case mention
    case macro
}


class MentionOrMacroItem:NSObject{
    
    var type : MentionOrMacroType
    var displayText : String =  ""
    var action : (()->())?
    
    init(type: MentionOrMacroType, displayText: String, action: (() -> ())?) {
        self.type = type
        self.displayText = displayText
        self.action = action
    }
    
}
