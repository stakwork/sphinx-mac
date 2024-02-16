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
    @IBOutlet weak var downloadingWheel: NSProgressIndicator!
    
    static let kViewHeight: CGFloat = 62
    static let kThreadsListViewHeight: CGFloat = 72
    
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
    
    func setup() {
        downloadButton.cursor = .pointingHand
    }
    
    func configure(
        fileInfo: MessageTableCellState.FileInfo
    ) {
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.Sphinx.ReceivedMsgBG.withAlphaComponent(0.95).cgColor
        
        iconLabel.stringValue = "insert_drive_file"
        fileNameLabel.stringValue = fileInfo.fileName
        pagesLabel.stringValue = "\(fileInfo.pagesCount ?? 0) \("pages".localized)"
        
        downloadButton.isHidden = true
    }
    
    func configureWith(
        mediaData: MessageTableCellState.MediaData?,
        and delegate: FileInfoViewDelegate?
    ) {
        self.delegate = delegate
        
        fileNameLabel.stringValue = mediaData?.fileInfo?.fileName ?? "file".localized
        pagesLabel.stringValue = mediaData?.fileInfo?.fileSize.formattedSize ?? "- kb"
        
        downloadButton.isHidden = mediaData == nil
        downloadingWheel.isHidden = mediaData != nil
        
        if let _ = mediaData {
            downloadButton.isHidden = false
            downloadingWheel.isHidden = true
            downloadingWheel.stopAnimation(nil)
        } else {
            downloadButton.isHidden = true
            downloadingWheel.isHidden = false
            downloadingWheel.startAnimation(nil)
        }
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
        delegate?.didTouchDownloadButton()
    }
}
