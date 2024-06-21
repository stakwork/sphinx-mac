//
//  PodcastDetailActionCell.swift
//  Sphinx
//
//  Created by James Carucci on 3/31/23.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

public enum FeedItemActionType{
    case download
    case share
    case markAsPlayed
    case copyLink
    case markAsUnplayed
    case erase
}

class PodcastDetailActionCell: NSCollectionViewItem {
    @IBOutlet weak var actionLabel: NSTextField!
    @IBOutlet weak var actionIconImage: NSImageView!
    @IBOutlet weak var divider: NSBox!
    
    var actionType : FeedItemActionType? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor.Sphinx.SecondaryText.withAlphaComponent(0.5).cgColor
    }
    
    func configureView(
        type: FeedItemActionType
    ){
        actionIconImage.isHidden = false
        //circularProgressView.isHidden = true
        
        switch(type){
        case .download:
            actionLabel.stringValue = "download".localized
            actionIconImage.image = NSImage(named: "itemDetailsDownload")
            actionIconImage.contentTintColor = NSColor.Sphinx.Text.withAlphaComponent(0.5)
            break
        case .copyLink:
            actionLabel.stringValue = "copy.link".localized
            actionIconImage.image = NSImage(named: "itemDetailsCopy")
            actionIconImage.contentTintColor = NSColor.Sphinx.Text.withAlphaComponent(0.5)
            break
        case .markAsPlayed:
            actionLabel.stringValue = "mark.as.played".localized
            actionIconImage.image = NSImage(named: "itemDetailsMark")
            actionIconImage.contentTintColor = NSColor.Sphinx.Text.withAlphaComponent(0.5)
            break
        case .share:
            actionLabel.stringValue = "share".localized
            actionIconImage.image = NSImage(named: "itemDetailsShare")
            actionIconImage.contentTintColor = NSColor.Sphinx.Text.withAlphaComponent(0.5)
            break
        case .markAsUnplayed:
            actionLabel.stringValue = "mark.as.unplayed".localized
            actionIconImage.image = NSImage(named: "itemDetailsPlayed")
            actionIconImage.contentTintColor = NSColor.Sphinx.ReceivedIcon
            break
        case .erase:
            actionLabel.stringValue = "erase.from.device".localized
            actionIconImage.image = NSImage(named: "itemDetailsDownloaded")
            actionIconImage.contentTintColor = NSColor.Sphinx.ReceivedIcon
            break
        }
    }
}
