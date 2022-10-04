//
//  TribeTagsView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 04/10/2022.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Cocoa

class TribeTagsView: NSView, LoadableNib {
    
    weak var delegate: TribeTagViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var tagsContainerView: NSView!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    func configureWith(tags: [GroupsManager.Tag]) {
        for tagView in tagsContainerView.subviews {
            if let tagView = tagView as? TribeTagView {
                let tag = tags[tagView.tagIdentifier]
                
                tagView.configure(selectedValue: tag.selected)
            }
        }
    }
    
    func setDelegate(delegate: TribeTagViewDelegate?) {
        self.delegate = delegate
        
        for tagView in tagsContainerView.subviews {
            if let tagView = tagView as? TribeTagView {
                tagView.delegate = delegate
            }
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        self.isHidden = true
        return
    }
    
    override func mouseDragged(with event: NSEvent) {
        return
    }
    
    override func mouseUp(with event: NSEvent) {
        return
    }
    
    override func scrollWheel(with event: NSEvent) {
        return
    }
    
}
