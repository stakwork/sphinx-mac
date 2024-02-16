//
//  ThreadListCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 28/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol ThreadListTableViewCellDelegate: AnyObject {
    func shouldLoadImageDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadPdfDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadFileDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadVideoDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadGiphyDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadAudioDataFor(messageId: Int, and rowIndex: Int)
    
    func didTapMediaButtonFor(messageId: Int, and rowIndex: Int)
    func didTapFileDownloadButtonFor(messageId: Int, and rowIndex: Int)
}

class ThreadListCollectionViewItem: NSCollectionViewItem {
    
    weak var delegate: ThreadListTableViewCellDelegate!
    
    var rowIndex: Int!
    var messageId: Int?
    
    @IBOutlet weak var originalMessageAvatarView: ChatSmallAvatarView!
    @IBOutlet weak var originalMessageSenderAliasLabel: NSTextField!
    @IBOutlet weak var originalMessageDateLabel: NSTextField!
    @IBOutlet weak var originalMessageTextLabel: NSTextField!
    
    @IBOutlet weak var mediaMessageView: MediaMessageView!
    @IBOutlet weak var fileDetailsView: FileInfoView!
    @IBOutlet weak var audioMessageView: AudioMessageView!
    
    @IBOutlet weak var reply1Container: NSView!
    @IBOutlet weak var reply1AvatarView: ChatSmallAvatarView!
    
    @IBOutlet weak var reply2Container: NSView!
    @IBOutlet weak var reply2AvatarView: ChatSmallAvatarView!
    
    @IBOutlet weak var reply3Container: NSView!
    @IBOutlet weak var reply3AvatarView: ChatSmallAvatarView!
    
    @IBOutlet weak var reply4Container: NSView!
    @IBOutlet weak var reply4AvatarView: ChatSmallAvatarView!
    
    @IBOutlet weak var reply5Container: NSView!
    @IBOutlet weak var reply5AvatarView: ChatSmallAvatarView!
    
    @IBOutlet weak var reply6Container: NSView!
    @IBOutlet weak var reply6AvatarView: ChatSmallAvatarView!
    @IBOutlet weak var reply6CountContainer: NSBox!
    @IBOutlet weak var reply6CountLabel: NSTextField!
    
    @IBOutlet weak var repliesCountLabel: NSTextField!
    @IBOutlet weak var lastReplyDateLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        reply1Container.wantsLayer = true
        reply1Container.layer?.masksToBounds = false
        
        reply2Container.wantsLayer = true
        reply2Container.layer?.masksToBounds = false
        
        reply3Container.wantsLayer = true
        reply3Container.layer?.masksToBounds = false
        
        reply4Container.wantsLayer = true
        reply4Container.layer?.masksToBounds = false
        
        reply5Container.wantsLayer = true
        reply5Container.layer?.masksToBounds = false
        
        reply6Container.wantsLayer = true
        reply6Container.layer?.masksToBounds = false
        
        reply1AvatarView.setInitialLabelSize(size: 12)
        reply2AvatarView.setInitialLabelSize(size: 12)
        reply3AvatarView.setInitialLabelSize(size: 12)
        reply4AvatarView.setInitialLabelSize(size: 12)
        reply5AvatarView.setInitialLabelSize(size: 12)
        reply6AvatarView.setInitialLabelSize(size: 12)
        
        fileDetailsView.wantsLayer = true
        fileDetailsView.layer?.backgroundColor = NSColor.Sphinx.HeaderBG.cgColor
        fileDetailsView.layer?.cornerRadius = 9
    }
    
    func hideAllSubviews() {
        mediaMessageView.isHidden = true
        fileDetailsView.isHidden = true
        audioMessageView.isHidden = true
        originalMessageTextLabel.isHidden = true
    }
    
    func configureWith(
        threadCellState: ThreadTableCellState,
        mediaData: MessageTableCellState.MediaData?,
        delegate: ThreadListTableViewCellDelegate?,
        indexPath: IndexPath
    ) {
        var mutableThreadCellState = threadCellState
        
        self.rowIndex = indexPath.item
        self.messageId = mutableThreadCellState.originalMessage?.id
        self.delegate = delegate
        
        hideAllSubviews()
        
        configureWith(threadLayoutState: mutableThreadCellState.threadMessagesState)
        configureWith(messageMedia: mutableThreadCellState.messageMedia, mediaData: mediaData)
        configureWith(genericFile: mutableThreadCellState.genericFile, mediaData: mediaData)
        configureWith(audio: mutableThreadCellState.audio, mediaData: mediaData)
    }
    
}
