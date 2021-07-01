//
//  GifOverlayView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 28/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol GifOverlayDelegate: AnyObject {
    func didTapButton()
}

class GifOverlayView: NSView, LoadableNib {
    
    weak var delegate: GifOverlayDelegate?

    @IBOutlet var contentView: NSView!
    @IBOutlet weak var gifIconContainer: NSBox!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    func configure(delegate: GifOverlayDelegate) {
        self.delegate = delegate
        
        gifIconContainer.wantsLayer = true
        gifIconContainer.layer?.cornerRadius = gifIconContainer.frame.size.height / 2
    }

    @IBAction func buttonClicked(_ sender: Any) {
        delegate?.didTapButton()
    }
    
}
