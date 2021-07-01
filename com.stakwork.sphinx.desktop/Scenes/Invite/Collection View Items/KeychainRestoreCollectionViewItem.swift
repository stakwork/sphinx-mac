//
//  KeychainRestoreCollectionViewItem.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 13/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class KeychainRestoreCollectionViewItem: NSCollectionViewItem {
    
    @IBOutlet weak var pubKeyLabel: NSTextField!
    
    var pubKey: String? {
      didSet {
        guard isViewLoaded else { return }
        if let pubKey = pubKey {
            pubKeyLabel.stringValue = pubKey
        } else {
            pubKeyLabel.stringValue = ""
        }
      }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.Sphinx.Body.cgColor
    }
    
}
