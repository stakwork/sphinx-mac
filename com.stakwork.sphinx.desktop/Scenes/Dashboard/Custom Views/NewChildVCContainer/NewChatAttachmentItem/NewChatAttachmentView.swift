//
//  NewChatAttachmentView.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 13/06/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol AddAttachmentDelegate: AnyObject {
    func addAttachmentClicked()
}
class NewChatAttachmentView: NSView, LoadableNib {
    
    enum CollectionViewSection: Int, CaseIterable {
        case title
    }
    
    weak var attachmentDelegate: AddAttachmentDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var attachmentsCollectionView: NSCollectionView!
    @IBOutlet weak var attachmentScrollView: NSScrollView!
    @IBOutlet weak var attachmentBoxContainer: NSBox!
    @IBOutlet weak var addButtonLeadingConstraint: NSLayoutConstraint!
    
    var menuDataSource: NewChatAttachmentDataSource? = nil
    
    typealias CollectionViewCell = NewMenuListItem
    
    var menuItems: [NewAttachmentItem] = []
    var allMediaData: [MediaObjectInfo] = []
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setup()
    }
    
    private func setup() {
        

        attachmentBoxContainer.layer?.borderWidth = 1
        let bgColor = NSColor.init(red: 0, green: 0, blue: 0, alpha: 0.1)
        attachmentBoxContainer.layer?.borderColor = bgColor.cgColor
        attachmentBoxContainer.layer?.masksToBounds = false
    }
    
    func configureDataSource(delegate: NewChatAttachmentDelegate) {
        if menuDataSource == nil {
            menuDataSource = NewChatAttachmentDataSource(collectionView: attachmentsCollectionView, delegate: delegate)
            
        }
        menuDataSource?.setDataAndReload(objects: menuItems)
    }
    
    func updateCollectionView(menuItems: [NewAttachmentItem]) {
        self.menuItems = menuItems
        menuDataSource?.setDataAndReload(objects: menuItems)
    }
    
    @IBAction func attachmentButtonTapped(_ sender: NSButton) {
        attachmentDelegate?.addAttachmentClicked()
    }
}
