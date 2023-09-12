//
//  FileInfoView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 12/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol FileInfoViewDelegate : AnyObject {
    func didTouchDownloadButton()
}

class FileInfoView: NSView, LoadableNib {
    
    weak var delegate: FileInfoViewDelegate?

    @IBOutlet var contentView: NSView!
    @IBOutlet weak var iconLabel: NSTextField!
    @IBOutlet weak var fileNameLabel: NSTextField!
    @IBOutlet weak var pagesLabel: NSTextField!
    @IBOutlet weak var downloadButton: CustomButton!
    
    var message: TransactionMessage! = nil
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
        setup()
    }
    
    func setup() {}
    
    func configure(
        fileInfo: MessageTableCellState.FileInfo
    ) {
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.Sphinx.ReceivedMsgBG.withAlphaComponent(0.95).cgColor
        
        iconLabel.stringValue = "insert_drive_file"
        fileNameLabel.stringValue = fileInfo.fileName
        pagesLabel.stringValue = "\(fileInfo.pagesCount ?? 0) \("pages".localized)"
    }
    
    func configure(
        data: Data,
        fileName: String
    ) {
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor
        
        iconLabel.stringValue = "insert_drive_file"
        fileNameLabel.stringValue = fileName
        pagesLabel.stringValue = data.formattedSize
        downloadButton.isHidden = true
    }
    
    @IBAction func downloadButtonClicked(_ sender: Any) {
//        delegate?.didTouchDownloadButton(button: downloadButton)
        
    }
}
