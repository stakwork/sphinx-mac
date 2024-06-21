//
//  ThreadTableDataSource+ResultsControllerExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 28/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

extension ThreadTableDataSource {
    func getThreadCellFor(
        dataSourceItem: MessageTableCellState,
        indexPath: IndexPath
    ) -> NSCollectionViewItem {
        return super.getCellFor(
            dataSourceItem: dataSourceItem,
            indexPath: indexPath
        )
    }
    
    override func processMessages(
        messages: [TransactionMessage],
        UIUpdateIndex: Int
    ) {
        let chat = chat ?? contact?.getFakeChat()
        
        guard let chat = chat else {
            return
        }
        
        guard let owner = UserContact.getOwner() else {
            return
        }
        
//        startSearchProcess()
        
        var array: [MessageTableCellState] = []
        
        let admin = chat.getAdmin()
        let contact = chat.getConversationContact()
        
        let replyingMessagesMap = getReplyingMessagesMapFor(messages: messages)
        let boostMessagesMap = getBoostMessagesMapFor(messages: messages)
        let threadMessagesMap = getThreadMessagesFor(messages: messages)
        let purchaseMessagesMap = getPurchaseMessagesMapFor(messages: messages)
        let linkContactsArray = getLinkContactsArrayFor(messages: messages)
        let linkTribesArray = getLinkTribesArrayFor(messages: messages)
        let webLinksArray = getWebLinksArrayFor(messages: messages)
        
        var groupingDate: Date? = nil
        var invoiceData: (Int, Int) = (0, 0)
        
        chat.processAliasesFrom(messages: messages)

        for (index, message) in messages.enumerated() {
            
            invoiceData = (
                invoiceData.0 + ((message.isPayment() && message.isIncoming(ownerId: owner.id)) ? -1 : 0),
                invoiceData.1 + ((message.isPayment() && message.isOutgoing(ownerId: owner.id)) ? -1 : 0)
            )
            
            let replyingMessage = (message.replyUUID != nil) ? replyingMessagesMap[message.replyUUID!] : nil
            let boostsMessages = (message.uuid != nil) ? (boostMessagesMap[message.uuid!] ?? []) : []
            let threadMessages = (message.threadUUID != nil) ? (threadMessagesMap[message.threadUUID!] ?? []) : []
            let purchaseMessages = purchaseMessagesMap[message.getMUID()] ?? [:]
            let linkContact = linkContactsArray[message.id]
            let linkTribe = linkTribesArray[message.id]
            let linkWeb = webLinksArray[message.id]
            
            let bubbleStateAndDate = getBubbleBackgroundForMessage(
                msg: threadMessages.last ?? message,
                with: index,
                in: messages,
                and: [:],
                groupingDate: &groupingDate,
                threadHeaderMessage: nil
            )
            
            if let separatorDate = bubbleStateAndDate.1 {
                array.append(
                    MessageTableCellState(
                        chat: chat,
                        owner: owner,
                        contact: contact,
                        tribeAdmin: admin,
                        separatorDate: separatorDate,
                        invoiceData: (invoiceData.0 > 0, invoiceData.1 > 0)
                    )
                )
            }
            
            let messageTableCellState = MessageTableCellState(
                message: message,
                chat: chat,
                owner: owner,
                contact: contact,
                tribeAdmin: admin,
                separatorDate: nil,
                bubbleState: bubbleStateAndDate.0,
                contactImage: headerImage,
                replyingMessage: replyingMessage,
                threadMessages: threadMessages,
                boostMessages: boostsMessages,
                purchaseMessages: purchaseMessages,
                linkContact: linkContact,
                linkTribe: linkTribe,
                linkWeb: linkWeb,
                invoiceData: (invoiceData.0 > 0, invoiceData.1 > 0)
            )
            
            array.append(messageTableCellState)
            
            invoiceData = (
                invoiceData.0 + ((message.isInvoice() && message.isPaid() && message.isOutgoing(ownerId: owner.id)) ? 1 : 0),
                invoiceData.1 + ((message.isInvoice() && message.isPaid() && message.isIncoming(ownerId: owner.id)) ? 1 : 0)
            )
        }
        
        messageTableCellStateArray = array
        
        updateSnapshot(UIUpdateIndex: UIUpdateIndex)
        
        delegate?.configureNewMessagesIndicatorWith(newMsgCount: messages.count)
        delegate?.shouldReloadThreadHeader()
    }
    
    override func getFetchRequestFor(
        chat: Chat,
        with items: Int
    ) -> NSFetchRequest<TransactionMessage> {
        return TransactionMessage.getChatMessagesFetchRequest(
            for: chat,
            threadUUID: threadUUID,
            with: items
        )
    }
    
    override func getThreadMessagesFor(
        messages: [TransactionMessage]
    ) -> [String: [TransactionMessage]] {
        return [:]
    }
    
    override func didTapAvatarViewFor(messageId: Int, and rowIndex: Int) {
        ///Nothing to do
    }
}
