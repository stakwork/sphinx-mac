//
//  PdfInfoView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class PdfInfoView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var pdfInfoBubbleView: PdfInfoBubbleView!
    @IBOutlet weak var fileNameLabel: NSTextField!
    @IBOutlet weak var pagesLabel: NSTextField!
    @IBOutlet weak var downloadButton: CustomButton!
    
    var message: TransactionMessage! = nil
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
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
        downloadButton.alphaValue = 0.7
        downloadButton.cursor = .pointingHand
    }
    
    func configure(message: TransactionMessage) {
        self.message = message
        
        fileNameLabel.stringValue = message.mediaFileName ?? "file.pdf"
        pdfInfoBubbleView.showPdfInfoBubbleView(message: message)
        
        if let url = message.getMediaUrl(), message.isPDF() {
            if let data = MediaLoader.getMediaDataFromCachedUrl(url: url.absoluteString) {
                self.showPDFInfo(data: data, fileName: message.mediaFileName)
            } else {
                MediaLoader.loadFileData(url: url, message: message, completion: { _, data in
                    DispatchQueue.main.async {
                        self.showPDFInfo(data: data, fileName: message.mediaFileName)
                    }
                }, errorCompletion: { _ in
                    DispatchQueue.main.async {
                        self.isHidden = true
                    }
                })
            }
        }
    }
    
    func showPDFInfo(data: Data, fileName: String?) {
        if let pagesCount = data.getPDFPagesCount() {
            let pagesText = (pagesCount > 1 ? "pages" : "page").localized
            pagesLabel.stringValue = "\(pagesCount) \(pagesText)"
        }
        fileNameLabel.stringValue = fileName ?? "file.pdf"
        downloadButton.isHidden = false
    }
    
    @IBAction func downloadButtonClicked(_ sender: Any) {
        MediaDownloader.shouldSaveFile(message: message, completion: { (success, alertMessage) in
            DispatchQueue.main.async {
                NewMessageBubbleHelper().showGenericMessageView(text: alertMessage)
            }
        })
    }
}
