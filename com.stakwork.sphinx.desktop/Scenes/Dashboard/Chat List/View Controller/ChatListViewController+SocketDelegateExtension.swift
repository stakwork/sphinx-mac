//
//  ChatListSocketDelegateExtension.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 15/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

extension ChatListViewController {    
    func shouldShowAlert(message: String) {
        AlertHelper.showAlert(title: "Hey!", message: message)
    }
}
