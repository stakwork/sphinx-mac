//
//  ChatDataSource.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 18/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol ChatDataSourceDelegate: AnyObject {
    func didScrollToBottom()
    func shouldScrollToBottom(provisional: Bool)
    func didFinishLoading()
    func didDeleteGroup()
    func chatUpdated(chat: Chat)
}

class ChatDataSource : NSObject {
    var delegate: ChatDataSourceDelegate?
    var cellDelegate: MessageCellDelegate?
    
    var contact: UserContact? = nil
    var chat: Chat? = nil
    var contactIdsDictionary = [Int: UserContact] ()
    
    var chatMessagesCount = 0
    var messagesArray = [TransactionMessage]()
    var messageRowsArray = [TransactionMessageRow]()
    var messageIdsArray = [Int]()
    var boosts: [String: TransactionMessage.Reactions] = [String: TransactionMessage.Reactions]()
    var collectionView : NSCollectionView!
    var lastViewedMessageID : Int?
    
    var indexesToInsert = [IndexPath]()
    var indexesToUpdate = [IndexPath]()
    
    var userId : Int = -1
    var page = 1
    var itemsPerPage = 25
    var insertedRowsCount = 0
    var insertingRows = false
    
    var paymentForInvoiceReceived: Bool = false
    var paymentForInvoiceSent: Bool = false
    var paymentHashForInvoiceSent: String? = nil
    var paymentHashForInvoiceReceived: String? = nil
    
    let chatHelper = ChatHelper()
    var referenceMessageDate:Date? = nil
    
    init(collectionView: NSCollectionView, delegate: ChatDataSourceDelegate, cellDelegate: MessageCellDelegate) {
        super.init()
        self.collectionView = collectionView
        self.delegate = delegate
        self.cellDelegate = cellDelegate
        self.userId = UserData.sharedInstance.getUserId()
        
        chatHelper.registerCellsForChat(collectionView: collectionView)
    }
    
    func setDelegates(_ delegate: NSViewController?) {
        self.delegate = (delegate as? ChatDataSourceDelegate)
        self.cellDelegate = (delegate as? MessageCellDelegate)
    }
    
    func updateFrame() {
        self.collectionView.collectionViewLayout?.invalidateLayout()
    }
    
    func setDataAndReload(contact: UserContact? = nil, chat: Chat? = nil, forceReload: Bool = false) {
        let isOtherChat = (self.chat?.id ?? -1) != (chat?.id ?? -2)
        
        self.contact = contact
        self.chat = chat
        
        let newMessagesCount = (chat?.getNewMessagesCount(lastMessageId: self.messageIdsArray.last) ?? 0)
        if newMessagesCount == 0 && messagesArray.count > 0 && !isOtherChat && !forceReload {
            return
        }
        
        if isOtherChat {
            itemsPerPage = 25
        } else {
            itemsPerPage = getInitialItemsPerPage() + newMessagesCount
        }
        
        shouldStopPlayingAudios(item: nil)
        resetPrevChatValues()
        
        chatMessagesCount = chat?.getAllMessagesCount() ?? 0
        messagesArray = chat?.getAllMessages(limit: itemsPerPage) ?? [TransactionMessage]()
        messageIdsArray = []
        messageRowsArray = []
        boosts = [:]
        createContactIdsDictionary()
        
        chatHelper.processMessagesReactionsFor(chat: chat, messagesArray: messagesArray, boosts: &boosts)
        processMessagesArray(newObjectsCount: messagesArray.count)

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.reloadData()
        
        collectionView.collectionViewLayout?.invalidateLayout()
    }
    
    func getInitialItemsPerPage() -> Int {
        if messagesArray.count > 0 {
            return messagesArray.count
        }
        return itemsPerPage
    }
    
    func createContactIdsDictionary() {
        contactIdsDictionary = [Int: UserContact] ()
        
        if let chat = chat {
            for c in chat.getContacts() {
                contactIdsDictionary[c.id] = c
            }
        } else if let contact = contact {
            contactIdsDictionary[contact.id] = contact
        }
    }
    
    func getContactFor(messageRow: TransactionMessageRow) -> UserContact? {
        var messageContact = self.contact
        if let senderId = messageRow.transactionMessage?.senderId, let sender = contactIdsDictionary[senderId] {
            messageContact = sender
        }
        return messageContact
    }
    
    func updateContact(contact: UserContact) {
        self.contact = contact
        self.chat = contact.getConversation()
    }
    
    func resetPrevChatValues() {
        referenceMessageDate = nil
        
        paymentForInvoiceReceived = false
        paymentForInvoiceSent = false
        paymentHashForInvoiceSent = nil
        paymentHashForInvoiceReceived = nil
        
        page = 1
        insertingRows = false
        insertedRowsCount = 0
    }
    
    func processMessagesArray(newObjectsCount: Int) {
        if newObjectsCount == 0 {
            return
        }
        
        chatHelper.processGroupedMessages(array: messagesArray, referenceMessageDate: &referenceMessageDate)
        
        let limit = 0
        let start = newObjectsCount - 1
        
        for x in stride(from: start, through: limit, by: -1) {
            let message = messagesArray[x]
            
            if message.isUnknownType() || message.isMessageReaction() {
                addLoadingMoreAndFirstDateRows(x: x, limit: limit, date: message.date)
                
                let previousMessage = x - 1 >= limit ? messagesArray[x - 1] : nil
                
                if TransactionMessage.isDifferentDayMessage(lastMessage: message, newMessage: previousMessage) {
                    messageRowsArray.insert(getDayHeaderRow(date: message.date), at: 0)
                }
                continue
            }
            
            message.addPurchaseItems()
            message.reactions = boosts[message.uuid ?? ""]
            
            let previousMessage = x - 1 >= limit ? messagesArray[x - 1] : nil

            message.uploadingObject = nil
            
            let messageRow = TransactionMessageRow(message: message)

            let messageType = Int(message.type)
            switch (messageType) {
            case TransactionMessage.TransactionMessageType.invoice.rawValue:
                let incoming = message.isIncoming()
                let paymentHash = incoming ? paymentHashForInvoiceReceived : paymentHashForInvoiceSent
                if let invoicePaymentHash = message.paymentHash, let paymentHash = paymentHash, invoicePaymentHash == paymentHash {
                    if incoming {
                        paymentForInvoiceReceived = false
                        paymentHashForInvoiceReceived = nil
                    } else {
                        paymentForInvoiceSent = false
                        paymentHashForInvoiceSent = nil
                    }
                }
                break
            case TransactionMessage.TransactionMessageType.payment.rawValue:
                let isPaid = message.isPaid()
                if message.isIncoming() {
                    paymentForInvoiceSent = isPaid ? true : paymentForInvoiceSent
                    paymentHashForInvoiceSent = isPaid ? message.paymentHash : nil
                } else {
                    paymentForInvoiceReceived = isPaid ? true : paymentForInvoiceReceived
                    paymentHashForInvoiceReceived = isPaid ? message.paymentHash : nil
                }
                break
            default:
                break
            }
            
            messageRow.shouldShowRightLine = paymentForInvoiceReceived
            messageRow.shouldShowLeftLine = paymentForInvoiceSent

            let id = Int(message.id)
            if !messageIdsArray.contains(id) {
                messageRowsArray.insert(messageRow, at: 0)
                messageIdsArray.insert(id, at: 0)
            }
            
            if TransactionMessage.isDifferentDayMessage(lastMessage: message, newMessage: previousMessage) {
                messageRowsArray.insert(getDayHeaderRow(date: message.date), at: 0)
            }
            
            addLoadingMoreAndFirstDateRows(x: x, limit: limit, date: message.date)
        }
    }
    
    func addLoadingMoreAndFirstDateRows(x: Int, limit: Int, date: Date?) {
        if x == limit {
            if chatMessagesCount > messagesArray.count {
                let loadingMoreRow = TransactionMessageRow()
                messageRowsArray.insert(loadingMoreRow, at: 0)
            } else {
                let dayHeaderRow = TransactionMessageRow()
                dayHeaderRow.headerDate = date
                messageRowsArray.insert(dayHeaderRow, at: 0)
            }
        }
    }
    
    func showMoreMessages() {
        itemsPerPage = 50
        
        let newMessages = chat?.getAllMessages(limit: itemsPerPage, lastMessage: messagesArray[0]) ?? [TransactionMessage]()
        
        if newMessages.count > 0 {
            chatHelper.processMessagesReactionsFor(chat: chat, messagesArray: newMessages, boosts: &boosts)
            messagesArray.insert(contentsOf: newMessages, at: 0)
            
            insertObjectsToModel(newObjectsCount: newMessages.count)
            appendCells()
            
            DelayPerformedHelper.performAfterDelay(seconds: 0.5) {
                self.insertingRows = false
            }
        }
    }
    
    func insertObjectsToModel(newObjectsCount: Int) {
        page = page + 1
        messageRowsArray.remove(at: 0)
        processMessagesArray(newObjectsCount: newObjectsCount)
    }
    
    func appendCells() {
        let oldContentHeight = self.collectionView.collectionViewLayout?.collectionViewContentSize.height ?? 0
        let oldOffsetY = self.collectionView.enclosingScrollView?.contentView.bounds.origin.y ?? 0
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            
            let newContentHeight: CGFloat = self.collectionView.collectionViewLayout?.collectionViewContentSize.height ?? 0
            self.collectionView.enclosingScrollView?.contentView.scroll(to: NSPoint(x: 0.0, y: oldOffsetY + (newContentHeight - oldContentHeight)))
        }
    }
    
    func scrollTo(message: TransactionMessage) {
        if let messageRowToUpdate = getMessageRowToUpdate(m: message) {
            let ctx = NSAnimationContext.current
            ctx.duration = 0.2
            ctx.allowsImplicitAnimation = true
            
            self.collectionView.scrollToItems(at: [IndexPath(item: messageRowToUpdate.0, section: 0)], scrollPosition: .bottom)
        }
    }
    
    func getMessageRowToUpdate(m: TransactionMessage) -> (Int, TransactionMessageRow)? {
        let limit = messageRowsArray.count > itemsPerPage ? itemsPerPage : messageRowsArray.count
        for (index, messageRow) in messageRowsArray.enumerated().reversed()[0..<limit] {
            if let message = messageRow.transactionMessage {
                if message.id == m.id {
                    return (index, messageRow)
                }
            }
        }
        return nil
    }
    
    func isDifferentChat(message: TransactionMessage, vcChat: Chat?) -> Bool {
        if let chat = vcChat, let messageChatId = message.chat?.id, chat.id == messageChatId {
            return false
        }
        return true
    }
    
    func reloadAttachmentRow(m: TransactionMessage) -> IndexPath? {
        let limit = messageRowsArray.count > itemsPerPage ? itemsPerPage : messageRowsArray.count
        for (index, messageRow) in messageRowsArray.enumerated().reversed()[0..<limit] {
            if let message = messageRow.transactionMessage {
                let mMUID = m.getMUID()
                let originalMUID = m.originalMuid ?? ""
                let messageMUID = message.getMUID()
                
                if !messageMUID.isEmpty && !mMUID.isEmpty && (messageMUID == mMUID || messageMUID == originalMUID) {    
                    message.addPurchaseItems()
                    messageRow.transactionMessage = message
                    
                    let indexToReload = IndexPath(item: index, section: 0)
                    collectionView.reloadItems(at: [indexToReload])
                    return indexToReload
                }
            }
        }
        return nil
    }
    
    func processBoost(message: TransactionMessage) {
        chatHelper.processMessageReaction(
            message: message,
            owner: UserContact.getOwner(),
            contact: self.chat?.getContact(),
            boosts: &boosts
        )
        
        if let boostedMessage = message.getReplyingTo() {
            boostedMessage.reactions = boosts[message.replyUUID ?? ""]
            addMessageAndReload(message: boostedMessage)
        }
        
        DelayPerformedHelper.performAfterDelay(seconds: 1.0, completion: {
            NotificationCenter.default.post(name: .onBalanceDidChange, object: nil)
        })
    }
    
    func addMessageAndReload(message: TransactionMessage, provisional: Bool = false, confirmation: Bool = false) {
        if isDifferentChat(message: message, vcChat: self.chat) {
            return
        }
        
        if message.isUnknownType() {
            return
        }
        
        if message.isMessageReaction() {
            processBoost(message: message)
            return
        }
        
        var messageRowToUpdate : (Int, TransactionMessageRow)? = nil
        messageRowToUpdate = getMessageRowToUpdate(m: message)
        
        let id = Int(message.id)
        
        if let messageRowToUpdate = messageRowToUpdate {
            messageRowToUpdate.1.transactionMessage = message
            
            if !self.messageIdsArray.contains(id) {
                self.messagesArray.append(message)
                self.messageIdsArray.append(id)
            }
            
            let indexes = getIndexesToUpdateOnUpdate(index: messageRowToUpdate.0)
            indexesToUpdate.append(contentsOf: indexes)
        } else if confirmation {
            DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
                self.addMessageAndReload(message: message, provisional: provisional, confirmation: false)
            })
            return
        } else {
            let messageRow = TransactionMessageRow(message: message)
            
            if !self.messageIdsArray.contains(id) {
                
                if TransactionMessage.isDifferentDay(lastMessage: messagesArray.last, newMessageDate: message.date) {
                    messageRowsArray.append(getDayHeaderRow(date: message.date))
                    indexesToInsert.append(IndexPath(item: self.messageRowsArray.count - 1, section: 0))
                }
                
                self.chatHelper.processGroupedNewMessage(array: messagesArray, referenceMessageDate: &referenceMessageDate, message: messageRow.transactionMessage)
                self.messageRowsArray.append(messageRow)
                
                if id >= 0 {
                    self.messagesArray.append(message)
                    self.messageIdsArray.append(id)
                }
                
                indexesToInsert.append(IndexPath(item: self.messageRowsArray.count - 1, section: 0))
            }
        }
        
        if indexesToInsert.count == 0 && indexesToUpdate.count == 0 {
            return
        }
        
        DispatchQueue.main.async {
            self.insertAndUpdateRows(provisional: provisional)
        }
    }
    
    func reloadPreviousRow(row: Int) {
        let previousIndex = (row - 1 >= 0) ? IndexPath(item: row - 1, section: 0) : nil
        
        if let previousIndex = previousIndex {
            let currentMessage = messageRowsArray[row].transactionMessage
            let previousMessage = messageRowsArray[previousIndex.item].transactionMessage
             
             if currentMessage?.isOutgoing() ?? false && previousMessage?.isIncoming() ?? false {
                return
            }
            
            collectionView.reloadItems(at: [previousIndex])
        }
    }
    
    func insertAndUpdateRows(provisional: Bool) {
        if indexesToInsert.count > 0 {
            if shouldInsertRows() {
                insertedRowsCount = insertedRowsCount + indexesToInsert.count
                collectionView.insertItems(at: Set(indexesToInsert))
                
                reloadPreviousRow(row: indexesToInsert[0].item)
            }
            
            indexesToInsert = [IndexPath]()
            delegate?.shouldScrollToBottom(provisional: provisional)
        }
        
        if indexesToUpdate.count > 0 {
            let indexes = getIndexesToUpdate()
            collectionView.reloadItems(at: Set(indexes))
            indexesToUpdate = [IndexPath]()
        }
    }
    
    func shouldInsertRows() -> Bool {
        return messageRowsArray.count == collectionView.numberOfItems(inSection: 0) + indexesToInsert.count
    }
    
    func getIndexesToUpdate() -> [IndexPath] {
        var fixedIndexes = [IndexPath]()
        let numberOfRows = collectionView.numberOfItems(inSection: 0)
        
        for index in indexesToUpdate {
            if index.item < numberOfRows {
                fixedIndexes.append(index)
            }
        }
        return fixedIndexes
    }
    
    func getDayHeaderRow(date: Date?) -> TransactionMessageRow {
        let dayHeaderRow = TransactionMessageRow()
        dayHeaderRow.headerDate = date ?? Date()
        return dayHeaderRow
    }
    
    func getLoadingRow() -> TransactionMessageRow {
        let dayHeaderRow = TransactionMessageRow()
        return dayHeaderRow
    }
    
    func deleteCellFor(m: TransactionMessage) {
        for (index, messageRow) in self.messageRowsArray.enumerated().reversed() {
            if let message = messageRow.transactionMessage {
                if message.id == m.id {
                    deleteObjectWith(id: m.id, and: index)
                    return
                }
            }
        }
    }
    
    func deleteObjectWith(id: Int, and index: Int) {
        let consecutiveRows = getPreviousAndNextRows(index: index)
        updatePreviousAndNext(index: index, consecutiveRows: consecutiveRows)
        
        messagesArray = messagesArray.filter { $0.id != id }
        messageIdsArray = messageIdsArray.filter {$0 != id }
        
        let indexPathsToRemove = getIndexPathsToRemove(index: index, consecutiveRows: consecutiveRows)
        
        for index in indexPathsToRemove {
            messageRowsArray.remove(at: index.item)
        }
        
        insertedRowsCount = insertedRowsCount - indexPathsToRemove.count
        chatMessagesCount = chatMessagesCount - 1
        
        collectionView.deleteItems(at: Set(indexPathsToRemove))
    }
    
    func updateDeletedMessage(m: TransactionMessage) {
        for (index, messageRow) in self.messageRowsArray.enumerated().reversed() {
            if let message = messageRow.transactionMessage {
                if message.id == m.id {
                    let indexesToUpdate = getIndexesToUpdateOnUpdate(index: index)
                    collectionView.reloadItems(at: Set(indexesToUpdate))
                    break
                }
            }
        }
    }
    
    func getIndexesToUpdateOnUpdate(index: Int) -> [IndexPath] {
        var indexes: [IndexPath] = []
        indexes.append(IndexPath(item: index, section: 0))
        
        if !(messageRowsArray[index].transactionMessage?.isDeleted() ?? false) {
            return indexes
        }
        
        let consecutiveRows = getPreviousAndNextRows(index: index)
        chatHelper.processGroupedMessagesOnUpdate(updatedMessageRow: messageRowsArray[index], previousRow: consecutiveRows.0, nextRow: consecutiveRows.1)
        
        if let _ = consecutiveRows.0 {
            indexes.append(IndexPath(item: index - 1, section: 0))
        }
        if let _ = consecutiveRows.1 {
            indexes.append(IndexPath(item: index + 1, section: 0))
        }
        return indexes
    }
    
    func getIndexPathsToRemove(index: Int, consecutiveRows: (TransactionMessageRow?, TransactionMessageRow?)) -> [IndexPath] {
        var indexPathsToRemove = [IndexPath(item: index, section: 0)]
        
        if let previousRow = consecutiveRows.0, previousRow.isDayHeader {
            if consecutiveRows.1 == nil || (consecutiveRows.1?.isDayHeader ?? false) {
                indexPathsToRemove.append(IndexPath(item: index - 1, section: 0))
            }
        }
        
        return indexPathsToRemove
    }
    
    func updatePreviousAndNext(index: Int, consecutiveRows: (TransactionMessageRow?, TransactionMessageRow?)) {
        let (shouldUpdatePrev, shouldUpdateNext) = chatHelper.processGroupedMessagesOnDelete(rowToDelete: messageRowsArray[index], previousRow: consecutiveRows.0, nextRow: consecutiveRows.1)
        
        if shouldUpdatePrev {
            collectionView.reloadItems(at: [IndexPath(item: index - 1, section: 0)])
        } else if shouldUpdateNext {
            collectionView.reloadItems(at: [IndexPath(item: index + 1, section: 0)])
        }
    }
    
    func getPreviousAndNextRows(index: Int) -> (TransactionMessageRow?, TransactionMessageRow?) {
        let previousRow = (index > 0) ? messageRowsArray[index - 1] : nil
        let nextRow = (index < messageRowsArray.count - 1) ? messageRowsArray[index + 1] : nil
        return (previousRow, nextRow)
    }
}

extension ChatDataSource : NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return getSizeForRowAt(indexPath: indexPath)
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        MessageOptionsHelper.sharedInstance.hideMenu()
        collectionView.deselectAll(nil)
    }
    
    func getSizeForRowAt(indexPath: IndexPath) -> CGSize {
        let messageRow = messageRowsArray[indexPath.item]
        
        guard let _ = messageRow.getType() else {
            if let _  = messageRow.headerDate {
                return NSSize(width: collectionView.frame.width, height: DayHeaderCollectionViewItem.kHeaderHeight)
            } else {
                return NSSize(width: collectionView.frame.width, height: LoadingMoreCollectionViewItem.kLoadingHeight)
            }
        }
        
        let incoming = messageRow.isIncoming()
        let height: CGFloat = chatHelper.getRowHeight(incoming: incoming, messageRow: messageRow, chatWidth: collectionView.frame.width)
        return NSSize(width: collectionView.frame.width, height: height)
    }
}

extension ChatDataSource : NSCollectionViewDataSource {
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
 
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return messageRowsArray.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
        
        let messageRow = messageRowsArray[indexPath.item]
        let sender = getContactFor(messageRow: messageRow)
        self.lastViewedMessageID = messageRow.getMessageId()
        print("lastViewedMessageID:\(lastViewedMessageID) - \(messageRow.getMessageContent())")
        if let item = item as? DayHeaderCollectionViewItem {
            item.configureCell(messageRow: messageRow)
        } else if let item = item as? MessageRowProtocol {
            item.configureMessageRow(messageRow: messageRow, contact: sender, chat: chat, chatWidth: collectionView.frame.width)
            item.delegate = cellDelegate
            item.audioDelegate = self
        } else if let item = item as? GroupActionRowProtocol {
            item.configureMessage(message: messageRow.transactionMessage)
            item.delegate = self
        }
        
        if indexPath.item == collectionView.numberOfItems(inSection: 0) - 1 && page == 1 {
            delegate?.didFinishLoading()
        }
    }
 
    func collectionView(_ itemForRepresentedObjectAtcollectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let messageRow = messageRowsArray[indexPath.item]
        return chatHelper.getItemFor(messageRow: messageRow, indexPath: indexPath, on: collectionView)
    }
}

extension ChatDataSource {
    func scrollViewDidScroll() {
        guard let scrollView = collectionView.enclosingScrollView else {
            return
        }
        
        MessageOptionsHelper.sharedInstance.hideMenu()
        
        if scrollView.contentView.bounds.origin.y >= (collectionView.bounds.height - scrollView.frame.size.height) {
            delegate?.didScrollToBottom()
        }

        if scrollView.contentView.bounds.origin.y <= LoadingMoreCollectionViewItem.kLoadingHeight && !insertingRows {
            if chatMessagesCount <= messagesArray.count {
                return
            }

            insertingRows = true

            DelayPerformedHelper.performAfterDelay(seconds: 1.0, completion: {
                self.showMoreMessages()
            })
        }
    }
}

extension ChatDataSource : AudioCellDelegate {
    func shouldStopPlayingAudios(item: AudioCollectionViewItem?) {
        var itemIndexPath: Int = -1
        if let collectionVItem = item as? NSCollectionViewItem, let indexPath = collectionView.indexPath(for: collectionVItem) {
            itemIndexPath = indexPath.item
        }
        
        let shouldReset = itemIndexPath < 0
        for item in collectionView.visibleItems() {
            if let ip = collectionView.indexPath(for: item), let item = item as? AudioCollectionViewItem, ip.item != itemIndexPath {
                item.stopPlaying(shouldReset: shouldReset)
            }
        }
    }
}

extension ChatDataSource : GroupRowDelegate {
    func shouldDeleteGroup() {
        AlertHelper.showTwoOptionsAlert(title: "delete.group".localized, message: "confirm.delete.group".localized, confirm: {
            let bubbleHelper = NewMessageBubbleHelper()
            bubbleHelper.showLoadingWheel()
            
            GroupsManager.sharedInstance.deleteGroup(chat: self.chat, completion: { success in
                bubbleHelper.hideLoadingWheel()
                
                if success {
                    self.delegate?.didDeleteGroup()
                } else {
                    AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
                }
            })
        })
    }
    
    func shouldApproveMember(requestMessage: TransactionMessage) {
        respondToRequest(message: requestMessage, action: "approved", completion: { (chat, message) in
            self.delegate?.chatUpdated(chat: chat)
            self.addMessageAndReload(message: message)
        })
    }
    
    func shouldRejectMember(requestMessage: TransactionMessage) {
        respondToRequest(message: requestMessage, action: "rejected", completion: { (chat, message) in
            self.delegate?.chatUpdated(chat: chat)
            self.addMessageAndReload(message: message)
        })
    }
    
    func respondToRequest(message: TransactionMessage, action: String, completion: @escaping (Chat, TransactionMessage) -> ()) {
        API.sharedInstance.requestAction(messageId: message.id, contactId: message.senderId, action: action, callback: { json in
            if let chat = Chat.insertChat(chat: json["chat"]), let message = TransactionMessage.insertMessage(m: json["message"]).0 {
                completion(chat, message)
                return
            }
            self.processingRequestFailed()
        }, errorCallback: {
            self.processingRequestFailed()
        })
    }
    
    func processingRequestFailed() {
        NewMessageBubbleHelper().hideLoadingWheel()
        AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
    }
}


