//
//  NewChatViewController+CollectionViewExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa
import SDWebImage

extension NewChatViewController {
    func configureCollectionView() {
        chatCollectionView.alphaValue = 0.0
        
        if let ds = chatTableDataSource {
            if ds.isFinalDS() {
                return
            }
        } else if chat == nil {
            chatCollectionView.alphaValue = 1.0
            shimmeringView.toggle(show: false)
        }
        
        chatTableDataSource = NewChatTableDataSource(
            chat: chat,
            contact: contact,
            collectionView: chatCollectionView,
            collectionViewScroll: chatScrollView,
            shimmeringView: shimmeringView,
            headerImage: getContactImage(),
            bottomView: chatBottomView,
            webView: botWebView,
            delegate: self
        )
        
        newChatViewModel?.setDataSource(chatTableDataSource)
    }
    
    func getContactImage() -> NSImage? {
        let imageView = chatTopView.chatHeaderView.profileImageView
        
        if imageView?.isHidden == true {
            return nil
        }
        
        return imageView?.image
    }
}

extension NewChatViewController : NewChatTableDataSourceDelegate {
    func configureNewMessagesIndicatorWith(newMsgCount: Int) {}
    
    func didScrollToBottom() {}
    func didScrollOutOfBottomArea() {}
    
    func shouldGoToMediaFullScreenFor(messageId: Int) {
        if let message = TransactionMessage.getMessageWith(id: messageId) {
            delegate?.shouldShowFullMediaFor(message: message)
        }
    }
    
    func didTapOnContactWith(pubkey: String, and routeHint: String?) {
        var pubkey = pubkey
        
        if let routeHint = routeHint, routeHint.isNotEmpty {
            pubkey = "\(pubkey):\(routeHint)"
        }
        
        let userInfo: [String: Any] = ["pub-key" : pubkey]
        NotificationCenter.default.post(name: .onPubKeyClick, object: nil, userInfo: userInfo)
    }
    
    func didTapOnTribeWith(joinLink: String) {
        let userInfo: [String: Any] = ["tribe_link" : joinLink]
        NotificationCenter.default.post(name: .onJoinTribeClick, object: nil, userInfo: userInfo)
    }
    
    func didDeleteTribe() {
        
    }
    
    func didUpdateChat(_ chat: Chat) {
        
    }
    
    func shouldShowMemberPopupFor(messageId: Int) {
        if let message = TransactionMessage.getMessageWith(id: messageId) {
            childViewControllerContainer.showTribeMemberPopupViewOn(parentVC: self, with: message, delegate: self)
        }
    }
    
    func shouldReplyToMessage(message: TransactionMessage) {
        let isAtBottom = isChatAtBottom()
        
        newChatViewModel.replyingTo = message
        
        chatBottomView.configureReplyViewFor(
            message: message,
            owner: self.owner,
            withDelegate: self
        )
        
        if isAtBottom {
            shouldScrollToBottom()
        }
    }
    
    func shouldOpenActivityVCFor(url: URL) {
        
    }
    
    func shouldPayInvoiceFor(messageId: Int) {
        
    }
    
    func isOnStandardMode() -> Bool {
        return true
    }
    
    func didFinishSearchingWith(matchesCount: Int, index: Int) {
        
    }
    
    func shouldToggleSearchLoadingWheel(active: Bool) {
        
    }
    
    func shouldShowOptionsFor(messageId: Int, from button: NSButton) {
        if let message = TransactionMessage.getMessageWith(id: messageId) {
            MessageOptionsHelper.sharedInstance.showMenuFor(
                message: message,
                in: self.view,
                from: button,
                with: self
            )
        }
    }
}
