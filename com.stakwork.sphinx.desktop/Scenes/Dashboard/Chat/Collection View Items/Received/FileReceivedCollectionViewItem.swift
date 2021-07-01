//
//  FileReceivedCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class FileReceivedCollectionViewItem: CommonFileCollectionViewItem {
    
    @IBOutlet weak var paidAttachmentView: PaidAttachmentView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)

        commonConfigurationForMessages()
        configureStatus()
        configureFile()
        configurePayment()

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    func configureFile() {
        guard let messageRow = messageRow else {
            return
        }
        
        let bubbleSize = CGSize(width: Constants.kFileBubbleWidth, height: Constants.kFileBubbleHeight)
        bubbleView.showIncomingFileBubble(messageRow: messageRow, size: bubbleSize)
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: bubbleSize, incoming: true)
        
        tryLoadingData(messageRow: messageRow, bubbleSize: bubbleSize)
        
        messageBubbleView.clearBubbleView()

        if messageRow.transactionMessage.hasMessageContent() {
            let (label, _) = messageBubbleView.showIncomingMessageBubble(messageRow: messageRow, fixedBubbleWidth: Constants.kFileBubbleWidth)
            addLinksOnLabel(label: label)
        }
    }
    
    func configurePayment() {
        guard let messageRow = messageRow else {
            paidAttachmentView.isHidden = true
            return
        }
        paidAttachmentView.configure(messageRow: messageRow, delegate: self)
    }
    
    func configureStatus() {
        configureLockSign()
    }
    
    func tryLoadingData(messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        if let nsUrl = messageRow.transactionMessage.getMediaUrl() {
            loadFile(url: nsUrl, messageRow: messageRow, bubbleSize: bubbleSize)
        } else {
            fileLoadingFailed()
        }
    }
}

extension FileReceivedCollectionViewItem : PaidAttachmentViewDelegate {
    func didTapPayButton() {
        if let message = messageRow?.transactionMessage {
            let price = message.getAttachmentPrice() ?? 0
            paidAttachmentView.configure(status: TransactionMessage.TransactionMessageType.purchase, price: price)
            delegate?.didTapPayAttachment(transactionMessage: message)
        }
    }
}
