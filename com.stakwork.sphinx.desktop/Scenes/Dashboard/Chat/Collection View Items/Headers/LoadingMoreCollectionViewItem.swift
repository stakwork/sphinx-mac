//
//  LoadingMoreCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 25/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class LoadingMoreCollectionViewItem: NSCollectionViewItem {
    
    public static let kLoadingHeight: CGFloat = 50.0
    
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    @IBOutlet weak var loadingMoreLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingWheel.set(tintColor: NSColor.Sphinx.SecondaryText)
    }
    
    func configureCell(text: String) {
        loadingMoreLabel.stringValue = text
        loadingWheel.startAnimation(nil)
    }
    
}
