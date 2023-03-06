//
//  CommonFileCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class CommonFileCollectionViewItem : CommonReplyCollectionViewItem {
    
    @IBOutlet weak var bubbleView: FileBubbleView!
    @IBOutlet weak var messageBubbleView: MessageBubbleView!
    @IBOutlet weak var lockSign: NSTextField!
    @IBOutlet weak var fileInfoContainer: NSView!
    @IBOutlet weak var fileNameLabel: NSTextField!
    @IBOutlet weak var fileSizeLabel: NSTextField!
    @IBOutlet weak var downloadButton: CustomButton!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    
    static let kPictureMessageMargin: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        downloadButton.cursor = .pointingHand
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)
    }
    
    func loadFile(url: URL, messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        loadFileInfo(messageRow: messageRow, data: messageRow.transactionMessage.uploadingObject?.getDecryptedData())
        toggleLoadingImage(loading: true)
        
        MediaLoader.getFileAttachmentData(url: url, message: messageRow.transactionMessage, completion: { (messageId, data) in
            if self.isDifferentRow(messageId: messageId) { return }
            self.getMediaItemInfo(messageRow: messageRow)
        }, errorCompletion: { messageId in
            if self.isDifferentRow(messageId: messageId) { return }
            self.getMediaItemInfo(messageRow: messageRow)
        })
    }
    
    func getMediaItemInfo(messageRow: TransactionMessageRow) {
        guard let message = messageRow.transactionMessage else {
            return
        }
        
        if let filename = message.mediaFileName, !filename.isEmpty && message.mediaFileSize > 0 {
            self.loadFileInfo(fileName: filename, size: message.mediaFileSize)
        } else if let muid = messageRow.transactionMessage.muid, !muid.isEmpty {
            AttachmentsManager.sharedInstance.getMediaItemInfo(message: message, callback: { (messageId, filename, size) in
                if self.isDifferentRow(messageId: messageId) { return }
                self.messageRow?.transactionMessage.saveFileInfo(filename: filename, size: size)
                self.loadFileInfo(fileName: filename, size: size)
            })
        }
    }
    
    func loadFileInfo(messageRow: TransactionMessageRow, data: Data? = nil) {
        loadFileInfo(fileName: messageRow.transactionMessage.mediaFileName, size: data?.count)
    }
    
    func loadFileInfo(fileName: String?, size: Int?) {
        fileNameLabel.stringValue = fileName ?? "file".localized
        fileSizeLabel.stringValue = size?.formattedSize ?? "- kb"
        toggleLoadingImage(loading: false)
    }
    
    func toggleLoadingImage(loading: Bool) {
        loadingWheel.isHidden = !loading
        downloadButton.isHidden = loading

        if loading {
            loadingWheel.startAnimation(nil)
        } else {
            loadingWheel.stopAnimation(nil)
        }
    }
    
    func fileLoadingFailed() {
        toggleLoadingImage(loading: false)
        fileNameLabel.stringValue = "File"
        fileSizeLabel.stringValue = "- kb"
    }
    
    func configureLockSign() {
        let encrypted = (messageRow?.transactionMessage.encrypted ?? false)
        let hasMediaKey = (messageRow?.transactionMessage.hasMediaKey() ?? false)
        let isGiphy = (messageRow?.transactionMessage.isGiphy() ?? false)
        let imageEncrypted = encrypted && (hasMediaKey || isGiphy)
        lockSign.stringValue = imageEncrypted ? "lock" : ""
    }
    
    @IBAction func downloadButtonClicked(_ sender: Any) {
        let bubbleHelper = NewMessageBubbleHelper()
        if let message = messageRow?.transactionMessage {
            MediaDownloader.shouldSaveFile(message: message, completion: { (success, alertMessage) in
                DispatchQueue.main.async {
                    bubbleHelper.hideLoadingWheel()
                    bubbleHelper.showGenericMessageView(text: alertMessage)
                }
            })
        }
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        var height: CGFloat = 0.0
        let bubbleHeight = messageRow.isPaidSentAttachment ? Constants.kPaidFileBubbleHeight : Constants.kFileBubbleHeight
        let bubbleWidth = Constants.kFileBubbleWidth
        let payButtonHeight: CGFloat = messageRow.shouldShowPaidAttachmentView() ? PaidAttachmentView.kViewHeight : 0.0
        let replyTopPadding = CommonChatCollectionViewItem.getReplyTopPadding(message: messageRow.transactionMessage)
        let margin = messageRow.isIncoming() ? Constants.kBubbleReceivedArrowMargin : Constants.kBubbleSentArrowMargin
        
        if messageRow.transactionMessage.hasMessageContent() {
            let bubbleSize = MessageBubbleView.getBubbleSizeFrom(messageRow: messageRow, containerViewWidth: bubbleWidth, bubbleMargin: margin)
            height = bubbleHeight + bubbleSize.height + Constants.kComposedBubbleMessageMargin
        } else {
            let bottomBubblePadding = messageRow.isBoosted ? Constants.kReactionsViewHeight : 0
            height = bubbleHeight + bottomBubblePadding
        }
        
        return height + Constants.kBubbleTopMargin + Constants.kBubbleBottomMargin + payButtonHeight + replyTopPadding
    }
}

