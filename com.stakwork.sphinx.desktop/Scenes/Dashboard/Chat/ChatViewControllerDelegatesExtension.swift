//
//  ChatViewControllerDelegatesExtension.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 15/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import WebKit

extension ChatViewController : NSTextViewDelegate, MessageFieldDelegate {
    func didDetectImagePaste(pasteBoard: NSPasteboard) -> Bool {
        return draggingView.performPasteOperation(pasteBoard: pasteBoard)
    }
    
    
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        if let replacementString = replacementString, replacementString == "\n" {
            if sendButton.isEnabled {
                shouldSendMessage()
            }
            return false
        }
        
        let currentString = textView.string as NSString
        let currentChangedString = currentString.replacingCharacters(in: affectedCharRange, with: replacementString ?? "")
        return (currentChangedString.count <= kCharacterLimit)
    }
    
    func textDidChange(_ notification: Notification) {
        chat?.setOngoingMessage(text: messageTextView.string)
        
        processMention(text: messageTextView.string, cursorPosition: messageTextView.cursorPosition)
        
        let didUpdateHeight = updateBottomBarHeight()
        if !didUpdateHeight {
            return
        }
        
        if chatCollectionView.shouldScrollToBottom() {
            chatCollectionView.scrollToBottom(animated: false)
        }
    }
    
    func didTapTab(){
        if let selectedMention = chatMentionAutocompleteDataSource?.getSelectedValue() {
            populateMentionAutocomplete(autocompleteText: selectedMention)
        }
    }
    func populateMentionAutocomplete(autocompleteText: String) {
        let text = messageTextView.string
        if let typedMentionText = self.getAtMention(text: text, cursorPosition: messageTextView.cursorPosition){
            let initialPosition = messageTextView.cursorPosition
            
            messageTextView.string = text
                .replacingOccurrences(of: typedMentionText, with: "@\(autocompleteText) ")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
                self.messageTextView.string = self.messageTextView.string.replacingOccurrences(of: "\t", with: "")
                
                if var position = initialPosition {
                    position += ("@\(autocompleteText) ".count - typedMentionText.count)
                    self.messageTextView.setSelectedRange(NSRange(location: position, length: 0))
                }
            })
        }
        chatMentionAutocompleteDataSource?.updateMentionSuggestions(suggestions: [])
    }
    
    func didTapUpArrow() -> Bool {
        chatMentionAutocompleteDataSource?.moveSelectionUp()
        
        return chatMentionAutocompleteDataSource?.isTableVisible() ?? false
    }
    
    func didTapDownArrow() -> Bool  {
        chatMentionAutocompleteDataSource?.moveSelectionDown()
        
        return chatMentionAutocompleteDataSource?.isTableVisible() ?? false
    }
    
    func getAtMention(text:String,cursorPosition:Int?)->String?{
        let relevantText = text[0..<(cursorPosition ?? text.count)]
        if let lastLetter = relevantText.last, lastLetter == " " {
            return nil
        }
        if let lastWord = relevantText.split(separator: " ").last {
            if let firstLetter = lastWord.first, firstLetter == "@" {
                return String(lastWord)
            }
        }
        return nil
    }
    
    func processMention(text:String,cursorPosition:Int?){
        var suggestions : [String] = []
        if let mention = getAtMention(text: text, cursorPosition:cursorPosition){
            let mentionText = String(mention).replacingOccurrences(of: "@", with: "").lowercased()
            let possibleMentions = self.chat?.aliases.filter(
            {
                if(mentionText.count > $0.count){
                    return false
                }
                let substring = $0.substring(range: NSRange(location: 0, length: mentionText.count))
                return (substring.lowercased() == mentionText && mentionText != "")
            }).sorted()
            suggestions = possibleMentions ?? []
        }
        chatMentionAutocompleteDataSource?.updateMentionSuggestions(suggestions: suggestions)
    }
    
    func updateBottomBarHeight() -> Bool {
        let messageFieldContentHeight = messageTextView.contentSize.height
        let maximumFieldHeight:CGFloat = 76
        let newFieldHeight = min(messageFieldContentHeight, maximumFieldHeight)
        
        if bottomBarHeightConstraint.constant == newFieldHeight + kBottomBarMargins {
            messageTextView.scrollRangeToVisible(NSMakeRange(messageTextView.string.length, 0))
            return false
        }
        
        if(isInCodeMode == false){
            bottomBarHeightConstraint.constant = newFieldHeight + kBottomBarMargins
        }
        
        bottomBar.layoutSubtreeIfNeeded()
        
        messageTextView.scrollRangeToVisible(NSMakeRange(messageTextView.string.length, 0))
        return true
    }
    
    func shouldSendMessage() {
        if shouldUploadMedia() {
            uploadAndSend()
            return
        }
        
        let text = giphyText() ?? messageTextView.string.trim()
        sendMessageWith(text: text)
    }
    
    func shouldUploadMedia() -> Bool {
        return draggingView.isSendingMedia() || isPaidTextMessage()
    }
    
    func giphyText() -> String? {
        let text = messageTextView.string.trim()
        let (sendingGiphy, giphyObject) = draggingView.isSendingGiphy()
        
        if let giphyObject = giphyObject, sendingGiphy {
            draggingView.setup()
            return GiphyHelper.getMessageStringFrom(media: giphyObject, text: text)
        }
        return nil
    }
    
    func sendMessageWith(
        text: String,
        type: Int? = nil
    ) {
        var messageText = text
        
        if messageText.isEmpty {
           return
        }
        
        if let podcastComment = messageReplyView.getReplyingPodcast() {
            messageText = podcastComment.getJsonString(withComment: text) ?? text
        }
        
        let (botAmount, wrongAmount) = isWrongBotCommandAmount(text: messageText)
        if wrongAmount {
            return
        }
        
        let messageType = type ?? TransactionMessage.TransactionMessageType.message.rawValue
        let _ = createProvisionalAndSend(messageText: messageText, type: messageType, botAmount: botAmount)
        hideMessageReplyView()
        resetMessageField()
    }
    
    func isWrongBotCommandAmount(text: String) -> (Int, Bool) {
        let (botAmount, failureMessage) = GroupsManager.sharedInstance.calculateBotPrice(chat: chat, text: text)
        if let failureMessage = failureMessage {
            AlertHelper.showAlert(title: "generic.error.title".localized, message: failureMessage)
            return (botAmount, true)
        }
        return (botAmount, false)
    }
    
    func createProvisionalAndSend(messageText: String, type: Int, botAmount: Int) -> TransactionMessage? {
        let provisionalMessage = insertPrivisionalMessage(text: messageText, type: type, chat: chat)
        sendMessage(provisionalMessage: provisionalMessage, text: messageText, botAmount: botAmount)
        return provisionalMessage
    }
    
    func sendMessage(
        provisionalMessage: TransactionMessage?,
        text: String,
        botAmount: Int = 0
    ) {
        let messageType = TransactionMessage.TransactionMessageType(fromRawValue: provisionalMessage?.type ?? 0)
        
        guard let params = TransactionMessage.getMessageParams(contact: contact, chat: chat, type: messageType, text: text, botAmount: botAmount, replyingMessage: messageReplyView.getReplyingMessage()) else {
            DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
                self.didFailSendingMessage(provisionalMessage: provisionalMessage)
            })
            return
        }
        sendMessage(provisionalMessage: provisionalMessage, params: params)
    }
    
    func sendMessage(
        provisionalMessage: TransactionMessage?,
        params: [String: AnyObject],
        completion: ((Bool) -> ())? = nil
    ) {
        let podcastComment = messageReplyView.getReplyingPodcast()
        
        API.sharedInstance.sendMessage(params: params, callback: { m in
            if let message = TransactionMessage.insertMessage(m: m, existingMessage: provisionalMessage).0 {
                message.setPaymentInvoiceAsPaid()
                self.insertSentMessage(message: message)
            }
            if let podcastComment = podcastComment {
                ActionsManager.sharedInstance.trackClipComment(podcastComment: podcastComment)
            }
            completion?(true)
        }, errorCallback: {
             if let provisionalMessage = provisionalMessage {
                provisionalMessage.status = TransactionMessage.TransactionMessageStatus.failed.rawValue
                provisionalMessage.saveMessage()
                self.insertSentMessage(message: provisionalMessage)
             }
            completion?(false)
        })
    }
    
    func insertPrivisionalMessage(text: String, type: Int, chat: Chat?) -> TransactionMessage? {
        let message = TransactionMessage.createProvisionalMessage(messageContent: text, type: type, date: Date(), chat: chat, replyUUID: messageReplyView.getReplyingMessage()?.uuid)
        
        if let message = message {
            chatDataSource?.addMessageAndReload(message: message, provisional: true)
        }
        return message
    }
    
    func insertSentMessage(message: TransactionMessage) {
        updateViewChat(updatedChat: chat ?? contact?.getConversation())
        enableViewAndComplete()
        chatDataSource?.addMessageAndReload(message: message)
        delegate?.shouldReloadChatList()
        joinIfCallMessage(message: message)
    }
    
    func joinIfCallMessage(message: TransactionMessage) {
        if message.type == TransactionMessage.TransactionMessageType.call.rawValue {
            if let link = message.messageContent {
                let linkUrl = VoIPRequestMessage.getFromString(link)?.link ?? link
                
                if let url = URL(string: linkUrl) {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
    
    func resetMessageField() {
        sendButton.isEnabled = false
        priceTextField.isEditable = false
        
        messageTextView.string = ""
        priceTextField.stringValue = ""
        chat?.resetOngoingMessage()
        let _ = updateBottomBarHeight()
        updatePriceFieldWidth()
        
        cleanupCodeMode()
        
        view.window?.makeFirstResponder(messageTextView)
    }
    
    func enableViewAndComplete() {
        sendButton.isEnabled = true
        messageTextView.isEditable = chat?.isStatusApproved() ?? true
        priceTextField.isEditable = true
    }
    
    func showErrorAlert() {
        AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
    }
    
    func forceKeysExchange(contactId: Int) {
        contactsService.exchangeKeys(id: contactId)
    }
}

extension ChatViewController : NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        updatePriceFieldWidth()
    }
    
    func updatePriceFieldWidth() {
        let currentString = (priceTextField?.stringValue ?? "")
        let width = NSTextField().getStringSize(text: currentString, font: NSFont.systemFont(ofSize: 15, weight: .semibold)).width
        priceTextFieldWidth.constant = (width < (kMinimumPriceFieldWidth - kPriceFieldPadding)) ? kMinimumPriceFieldWidth : width + kPriceFieldPadding
        priceTextField.superview?.layoutSubtreeIfNeeded()
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
            if sendButton.isEnabled {
                shouldSendMessage()
            }
            return true
        }
        return false
    }
}

extension ChatViewController : ChatDataSourceDelegate {
    func didScrollToBottom() {
        setMessagesAsSeen()
        trackChatScrollPosition()
    }
    
    func didFinishLoading() {
        chatCollectionView.alphaValue = 1.0
    }
    
    func didDeleteGroup() {
        NotificationCenter.default.post(name: .shouldUpdateDashboard, object: nil)
        NotificationCenter.default.post(name: .shouldResetChat, object: nil)
    }
    
    func chatUpdated(chat: Chat) {
        updateViewChat(updatedChat: chat)
        messageBubbleHelper.hideLoadingWheel()
    }
}

extension ChatViewController : MessageCellDelegate {
    func didTapPayButton(transactionMessage: TransactionMessage, item: NSCollectionViewItem) {
        guard let invoice = transactionMessage.invoice else {
            return
        }
        
        let parameters: [String : AnyObject] = ["payment_request" : invoice as AnyObject]

        API.sharedInstance.payInvoice(parameters: parameters, callback: { payment in
            if let message = TransactionMessage.insertMessage(m: payment).0 {
                message.setPaymentInvoiceAsPaid()
                self.reloadMessages(newMessageCount: 1)
            }
        }, errorCallback: {
            if let indexPath = self.chatCollectionView.indexPath(for: item) {
                self.chatCollectionView.reloadItems(at: [indexPath])
            }
            self.showErrorAlert()
        })
    }
    
    func didTapAttachmentRow(message: TransactionMessage) {
        shouldShowFullMediaFor(message: message)
    }
    
    func didTapAttachmentCancel(transactionMessage: TransactionMessage) {
        enableViewAndComplete()
        AttachmentsManager.sharedInstance.cancelUpload()
        chatDataSource?.deleteCellFor(m: transactionMessage)
        CoreDataManager.sharedManager.deleteObject(object: transactionMessage)
    }
    
    func didTapAvatarView(message: TransactionMessage) {
        childVCContainer.showTribeMemberPopupViewOn(parentVC: self, with: message, delegate: self)
    }
    
    func shouldShowFullMediaFor(message: TransactionMessage? = nil) {
        if draggingView.isSendingMedia() {
            return
        }
        
        if let message = message {
            delegate?.shouldShowFullMediaFor(message: message)
        }
    }
    
    func shouldStartCall(link: String, audioOnly: Bool) {
        var linkUrl = VoIPRequestMessage.getFromString(link)?.link ?? link
        
        if audioOnly && !linkUrl.contains("startAudioOnly") {
            linkUrl = "\(linkUrl)#config.startAudioOnly=true"
        }
        
        if let url = URL(string: linkUrl) {
            NSWorkspace.shared.open(url)
        }
    }
    
    func didTapPayAttachment(transactionMessage: TransactionMessage) {
        let attachmentsManager = AttachmentsManager.sharedInstance
        attachmentsManager.payAttachment(message: transactionMessage, chat: chat, callback: { purchaseMessage in
            if let purchaseMessage = purchaseMessage {
                let _ = self.chatDataSource?.reloadAttachmentRow(m: purchaseMessage)
            } else {
                AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
            }
        })
    }
    
    func shouldReload(item: NSCollectionViewItem) {
        if let indexPath = chatCollectionView.indexPath(for: item) {
            chatCollectionView.reloadItems(at: [indexPath])
            shouldScrollToBottom()
        }
    }
    
    func shouldScrollTo(message: TransactionMessage) {
        chatDataSource?.scrollTo(message: message)
    }
    
    func shouldScrollToBottom() {
        if chatCollectionView.shouldScrollToBottom() {
            chatCollectionView.scrollToBottom(animated: false)
        }
    }
    
    func shouldShowOptionsFor(message: TransactionMessage, from button: NSButton) {
        messageOptionsHelper.showMenuFor(message: message, in: self.view, from: button, with: self)
    }
    
    func toggleMessageReplyView() {
        messageReplyViewHeight.constant = messageReplyView.getViewHeight()
        toggleSearchTopView()
    }
    
    func trackChatScrollPosition(){
        if let dataSource = chatDataSource,
           let tablePosition = dataSource.getTableViewPosition(),
           let valid_chat = chat
        {
            GroupsManager.sharedInstance.setChatLastRead(chatID: valid_chat.id, tablePosition: tablePosition)
        }
    }
    
    func hideMessageReplyView() {
        messageReplyView.resetObjects()
        messageReplyView.isHidden = true
        toggleMessageReplyView()
    }
    
    func toggleGiphySearchView() {
        toggleSearchTopView()
    }
    
    func hideGiphySearchView() {
        giphySearchView.isHidden = true
        toggleGiphySearchView()
    }
    
    func toggleSearchTopView() {
        let viewHeight = messageReplyView.getViewHeight() + giphySearchView.getViewHeight()
        if (viewHeight == 0) { bottomBar.addShadow(location: VerticalLocation.top, color: NSColor.black, opacity: 0.3, radius: 5.0) }
        self.searchTopViewHeight.constant = viewHeight
        self.searchTopView.layoutSubtreeIfNeeded()
    }
}

extension ChatViewController : SearchTopViewDelegate {
    func didCloseReplyView() {
        toggleMessageReplyView()
    }
    
    func didCloseGiphyView() {
        toggleGiphySearchView()
    }
    
    func didSelectGiphy(object: GiphyObject, data: Data) {
        draggingView.showGiphyPreview(data: data, object: object)
    }
}

extension ChatViewController : MessageOptionsDelegate {
    func shouldDeleteMessage(message: TransactionMessage) {
        if message.id < 0 {
            chatDataSource?.deleteCellFor(m: message)
            CoreDataManager.sharedManager.deleteObject(object: message)
            return
        }
        
        chatViewModel.shouldDeleteMessage(message: message, completion: { (success, updatedMessage) in
            if success {
                self.chatDataSource?.updateDeletedMessage(m: updatedMessage ?? message)
            } else {
                self.messageBubbleHelper.showGenericMessageView(text: "generic.error.message".localized, in: self.view)
            }
        })
    }
    
    func shouldBoostMessage(message: TransactionMessage) {
        guard let params = TransactionMessage.getBoostMessageParams(contact: contact, chat: chat, replyingMessage: message) else {
            return
        }
        sendMessage(provisionalMessage: nil, params: params)
    }
    
    func shouldReplyToMessage(message: TransactionMessage) {
        bottomBar.removeShadow()
        messageReplyView.configureForKeyboard(with: message, and: self)
        willReplay()
    }
    
    func shouldResendMessage(message: TransactionMessage) {
        if let text = message.messageContent {
            
            message.status = TransactionMessage.TransactionMessageStatus.pending.rawValue
            
            sendMessage(provisionalMessage: message, text: text)
            willReplay()
        }
    }
    
    func willReplay() {
        toggleMessageReplyView()
        if chatCollectionView.shouldScrollToBottom() { chatCollectionView.scrollToBottom(animated: false) }
        view.window?.makeFirstResponder(messageTextView)
    }
}

extension ChatViewController : GroupDetailsDelegate {
    func shouldExitTribeOrGroup(completion: @escaping () -> ()) {
        exitAndDeleteGroup(completion: {
            completion()
        })
    }
}

extension ChatViewController : ChatMentionAutocompleteDelegate{
    func processAutocomplete(text: String) {
        populateMentionAutocomplete(autocompleteText: text)
        self.chatMentionAutocompleteDataSource?.updateMentionSuggestions(suggestions: [])
    }
    
    func getTableHeightConstraint() -> NSLayoutConstraint?{
        return mentionScrollViewHeight
    }
}

extension String {
    func substring(range: NSRange) -> String {
        let botIndex = self.index(self.startIndex, offsetBy: range.location)
        let newRange = botIndex..<self.index(botIndex, offsetBy: range.length)
        return String(self[newRange])
   }
}


extension ChatViewController : WKNavigationDelegate{
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //printWebViewHTML(webView: webView)//for debug
        styleView(webView: webView, fontSize: "14", fontColor: "#FFFFFF", bubbleColor: "#466085")
    }
    
    func printWebViewHTML(webView:WKWebView){
        webView.evaluateJavaScript("document.body.innerHTML") {(result, error) in
            guard error == nil else {
                print(error!)
                return
            }
            
            print(String(describing: result))
        }
    }
    
    func styleView(webView:WKWebView,fontSize:String,fontColor:String,bubbleColor:String){
        let fontChangeJS = """
        code = document.querySelectorAll('.hljs');
          code.forEach((p) => {
            p.style.fontSize = "14px" ;
          });
        paragraphs = document.querySelectorAll('p');
          paragraphs.forEach((p) => {
            p.style.fontSize = "\(fontSize)px" ;
            p.style.color = "\(fontColor)";
          })
        document.body.style.backgroundColor = "\(bubbleColor)";
        """
        
        webView.evaluateJavaScript(fontChangeJS) {(result, error) in
            guard error == nil else {
                print(error!)
                return
            }
            
            print(String(describing: result))
        }
    }
    
}
