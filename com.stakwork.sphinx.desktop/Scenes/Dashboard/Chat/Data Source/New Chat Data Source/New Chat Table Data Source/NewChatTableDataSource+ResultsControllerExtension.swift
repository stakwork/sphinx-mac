//
//  NewChatTableDataSource+ResultsControllerExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa
import CoreData

extension NewChatTableDataSource {
    
    enum CollectionViewSection: Int, CaseIterable {
        case messages
    }
    
    typealias DataSource = NSCollectionViewDiffableDataSource<CollectionViewSection, MessageTableCellState>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<CollectionViewSection, MessageTableCellState>
    
    func makeDataSource() -> DataSource {
        let dataSource = DataSource(
            collectionView: self.collectionView,
            itemProvider: makeCellProvider(for: self.collectionView)
        )

        return dataSource
    }

    func configureDataSource() {
        dataSource = makeDataSource()

        restorePreloadedOrLoadMessages()        
    }
    
    func makeSnapshotForCurrentState() -> DataSourceSnapshot {
        var snapshot = DataSourceSnapshot()

        snapshot.appendSections([CollectionViewSection.messages])

        snapshot.appendItems(
            messageTableCellStateArray,
            toSection: .messages
        )

        return snapshot
    }
    
    func updateSnapshot(
        UIUpdateIndex: Int,
        completion: (() -> ())? = nil
    ) {
        let snapshot = makeSnapshotForCurrentState()
        let isSearching = !(self.delegate?.isOnStandardMode() ?? true)
        let animated = !isFirstLoad && !loadingMoreItems && !isSearching
        
        if UIUpdateIndex < self.UIUpdateIndex {
            return
        }
        
        DispatchQueue.main.async {
            CoreDataManager.sharedManager.saveContext()
            
            self.saveSnapshotCurrentState()
            self.dataSource.apply(snapshot, animatingDifferences: animated) {
                self.restoreScrollLastPosition()
                self.loadingMoreItems = false
                self.isFirstLoad = false
                
                completion?()
            }
        }
    }
    
    func updatePreloadedSnapshot() {
        let snapshot = makeSnapshotForCurrentState()
        self.dataSource.apply(snapshot, animatingDifferences: false)
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.1, completion: {
            self.restoreScrollLastPosition()
        })
    }
    
    func getCellFor(
        dataSourceItem: MessageTableCellState,
        indexPath: IndexPath
    ) -> NSCollectionViewItem {
        var cell: ChatCollectionViewItemProtocol? = nil
        var mutableDataSourceItem = dataSourceItem

        if let _ = mutableDataSourceItem.bubble {
            if mutableDataSourceItem.isThread {
                cell = collectionView.makeItem(
                    withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ThreadCollectionViewItem"),
                    for: indexPath
                ) as? ThreadCollectionViewItem
            } else if mutableDataSourceItem.isTextOnlyMessage {
                cell = collectionView.makeItem(
                    withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NewOnlyTextMessageCollectionViewitem"),
                    for: indexPath
                ) as? ChatCollectionViewItemProtocol
            } else {
                cell = collectionView.makeItem(
                    withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NewMessageCollectionViewItem"),
                    for: indexPath
                ) as? ChatCollectionViewItemProtocol
            }
        } else {
            cell = collectionView.makeItem(
                withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MessageNoBubbleCollectionViewItem"),
                for: indexPath
            ) as? ChatCollectionViewItemProtocol
        }

        let mediaData = (dataSourceItem.messageId != nil) ? self.mediaCached[dataSourceItem.messageId!] : nil
        let threadOriginalMessageMediaData = (dataSourceItem.threadOriginalMessage?.id != nil) ? self.mediaCached[dataSourceItem.threadOriginalMessage!.id] : nil
        let tribeData = (dataSourceItem.linkTribe?.uuid != nil) ? self.preloaderHelper.tribesData[dataSourceItem.linkTribe!.uuid] : nil
        let linkData = (dataSourceItem.linkWeb?.link != nil) ? self.preloaderHelper.linksData[dataSourceItem.linkWeb!.link] : nil
        let botWebViewData = (dataSourceItem.messageId != nil) ? self.botsWebViewData[dataSourceItem.messageId!] : nil
        let uploadProgressData = (dataSourceItem.messageId != nil) ? self.uploadingProgress[dataSourceItem.messageId!] : nil

        cell?.configureWith(
            messageCellState: dataSourceItem,
            mediaData: mediaData,
            threadOriginalMsgMediaData: threadOriginalMessageMediaData,
            tribeData: tribeData,
            linkData: linkData,
            botWebViewData: botWebViewData,
            uploadProgressData: uploadProgressData,
            delegate: self,
            searchingTerm: self.searchingTerm,
            indexPath: indexPath,
            collectionViewWidth: collectionView.frame.width
        )

        return (cell as? NSCollectionViewItem) ?? NSCollectionViewItem()
    }
}

extension NewChatTableDataSource {
    
    @objc func processMessages(
        messages: [TransactionMessage],
        UIUpdateIndex: Int
    ) {
        let chat = chat ?? contact?.getFakeChat()
        
        guard let chat = chat else {
            return
        }
        
        guard let owner = owner else {
            return
        }
        
        startSearchProcess()
        
        var newMsgCount = 0
        var array: [MessageTableCellState] = []
        
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

        let filteredThreadMessages: [TransactionMessage] = filterThreadMessagesFrom(
            messages: messages,
            threadMessagesMap: threadMessagesMap
        )
        
        let originalMessagesMap = getOriginalMessagesFor(
            threadMessages: filteredThreadMessages,
            threadMessagesMap: threadMessagesMap
        )

        for (index, message) in filteredThreadMessages.enumerated() {
            
            invoiceData = (
                invoiceData.0 + ((message.isPayment() && message.isIncoming(ownerId: owner.id)) ? -1 : 0),
                invoiceData.1 + ((message.isPayment() && message.isOutgoing(ownerId: owner.id)) ? -1 : 0)
            )
            
            let replyingMessage = (message.replyUUID != nil) ? replyingMessagesMap[message.replyUUID!] : nil
            let boostsMessages = (message.uuid != nil) ? (boostMessagesMap[message.uuid!] ?? []) : []
            let threadMessages = (message.threadUUID != nil) ? (threadMessagesMap[message.threadUUID!] ?? []) : []
            let threadOriginalMsg = (message.threadUUID != nil) ? originalMessagesMap[message.threadUUID!] : nil
            let purchaseMessages = purchaseMessagesMap[message.getMUID()] ?? [:]
            let linkContact = linkContactsArray[message.id]
            let linkTribe = linkTribesArray[message.id]
            let linkWeb = webLinksArray[message.id]
            
            let bubbleStateAndDate = getBubbleBackgroundForMessage(
                msg: threadMessages.last ?? message,
                with: index,
                in: filteredThreadMessages,
                and: originalMessagesMap,
                groupingDate: &groupingDate,
                isThreadRow: threadMessages.count > 1
            )
            
            if let separatorDate = bubbleStateAndDate.1 {
                array.append(
                    MessageTableCellState(
                        chat: chat,
                        owner: owner,
                        contact: contact,
                        tribeAdmin: tribeAdmin,
                        separatorDate: separatorDate,
                        invoiceData: (invoiceData.0 > 0, invoiceData.1 > 0)
                    )
                )
            }
            
            let messageTableCellState = MessageTableCellState(
                message: message,
                threadOriginalMessage: threadOriginalMsg,
                chat: chat,
                owner: owner,
                contact: contact,
                tribeAdmin: tribeAdmin,
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
            
            newMsgCount += getNewMessageCountFor(message: message, and: owner)
            
            processForSearch(
                message: message,
                messageTableCellState: messageTableCellState,
                index: array.count - 1
            )
        }
        
        messageTableCellStateArray = array
        
        updateSnapshot(
            UIUpdateIndex: UIUpdateIndex
        ) {
            self.delegate?.configureNewMessagesIndicatorWith(
                newMsgCount: newMsgCount
            )
            
            DelayPerformedHelper.performAfterDelay(seconds: 0.1, completion: {
                self.finishSearchProcess()
            })
        }
    }
    
    func filterThreadMessagesFrom(
        messages: [TransactionMessage],
        threadMessagesMap: [String: [TransactionMessage]]
    ) -> [TransactionMessage] {
        
        var filteredThreadMessages: [TransactionMessage] = []
        
        for message in messages {
            if let uuid = message.uuid {
                ///Remove original message, just last reply will show
                if let messagesInThread = threadMessagesMap[uuid], messagesInThread.count > 1 {
                    continue
                }
            }
            
            guard let threadUUID = message.threadUUID else {
                ///Message not on thread.
                filteredThreadMessages.append(message)
                continue
            }
            
            if let messagesInThread = threadMessagesMap[threadUUID] {
                if messagesInThread.count == 1 {
                    ///Just 1 reply, then show it
                    filteredThreadMessages.append(message)
                } else if messagesInThread.last?.id == message.id, messagesInThread.count > 1 {
                    ///More than 1 reply, show thread on last reply place
                    filteredThreadMessages.append(message)
                }
            } else {
                filteredThreadMessages.append(message)
            }
        }
        
        return filteredThreadMessages
    }
    
    func forceReload() {
        processMessages(messages: messagesArray, UIUpdateIndex: self.UIUpdateIndex)
        reloadAllVisibleRows()
    }
    
    func getMessagesCount() -> Int {
        return (messageTableCellStateArray.filter {
            var mutableState = $0
            return mutableState.isMessageRow
        }).count
    }
    
    func getNewMessageCountFor(
        message: TransactionMessage,
        and owner: UserContact
    ) -> Int {
        if (
            message.isIncoming(ownerId: owner.id) &&
            message.seen == false &&
            message.chat?.seen == false
        ) {
            return 1
        }
        return 0
    }
    
    func getNewMessageCountFor(
        message: TransactionMessage,
        and owner: UserContact,
        threadMessages: [TransactionMessage]
    ) -> Int {
        var newMsgsCount = 0
        
        if threadMessages.isEmpty {
            newMsgsCount = getNewMessageCountFor(message: message, and: owner)
        } else {
            for msg in threadMessages {
                newMsgsCount += getNewMessageCountFor(message: msg, and: owner)
            }
        }
        
        return newMsgsCount
    }
    
    func getBubbleBackgroundForMessage(
        msg: TransactionMessage,
        with index: Int,
        in messages: [TransactionMessage],
        and originalMessagesMap: [String: TransactionMessage],
        groupingDate: inout Date?,
        isThreadRow: Bool = false,
        threadHeaderMessage: TransactionMessage? = nil
    ) -> (MessageTableCellState.BubbleState?, Date?) {
        
        var previousMessage = (index > 0) ? messages[index - 1] : nil
        var nextMessage = (index < messages.count - 1) ? messages[index + 1] : nil
        
        let previousMessageDate = previousMessage?.date ?? threadHeaderMessage?.date
        let msgDate = msg.date
        
        previousMessage = getActualMessageFrom(message: previousMessage, originalMessagesMap: originalMessagesMap)
        nextMessage = getActualMessageFrom(message: nextMessage, originalMessagesMap: originalMessagesMap)
        
        guard let message = getActualMessageFrom(message: msg, originalMessagesMap: originalMessagesMap) else {
            return (nil, nil)
        }
        
        var separatorDate: Date? = nil
        
        if let previousMessageDate = previousMessageDate, let date = msgDate {
            if Date.isDifferentDay(firstDate: previousMessageDate, secondDate: date) {
                separatorDate = date
            }
        } else if previousMessage == nil {
            separatorDate = message.date
        }
        
        if message.isDeleted() || message.isGroupActionMessage() {
            return (nil, separatorDate)
        }
        
        if message.isPayment() {
            return (MessageTableCellState.BubbleState.Empty, separatorDate)
        }
        
        if message.isInvoice() && !message.isPaid() && !message.isExpired() {
            return (MessageTableCellState.BubbleState.Empty, separatorDate)
        }
        
        if isThreadRow {
            return (MessageTableCellState.BubbleState.Isolated, separatorDate)
        }
        
        let groupingMinutesLimit = 5
        let messageDate = message.date ?? Date(timeIntervalSince1970: 0)
        var date = groupingDate ?? messageDate

        let shouldAvoidGroupingWithPrevious = (previousMessage?.shouldAvoidGrouping() ?? true) || message.shouldAvoidGrouping()
        let isGroupedBySenderWithPrevious = previousMessage?.hasSameSenderThanMessage(message) ?? false
        let isGroupedByDateWithPrevious = messageDate.getMinutesDifference(from: date) < groupingMinutesLimit
        let groupedWithPrevious = (!shouldAvoidGroupingWithPrevious && isGroupedBySenderWithPrevious && isGroupedByDateWithPrevious)

        date = (groupedWithPrevious) ? date : messageDate

        let shouldAvoidGroupingWithNext = (nextMessage?.shouldAvoidGrouping() ?? true) || message.shouldAvoidGrouping()
        let isGroupedBySenderWithNext = nextMessage?.hasSameSenderThanMessage(message) ?? false
        let isGroupedByDateWithNext = (nextMessage != nil) ? (nextMessage?.date?.getMinutesDifference(from: date) ?? 0) < groupingMinutesLimit : false
        let groupedWithNext = (!shouldAvoidGroupingWithNext && isGroupedBySenderWithNext && isGroupedByDateWithNext)

        groupingDate = date
        
        if !groupedWithPrevious && !groupedWithNext {
            return (MessageTableCellState.BubbleState.Isolated, separatorDate)
        } else if groupedWithPrevious && !groupedWithNext {
            return (MessageTableCellState.BubbleState.Last, separatorDate)
        } else if !groupedWithPrevious && groupedWithNext {
            return (MessageTableCellState.BubbleState.First, separatorDate)
        } else if groupedWithPrevious && groupedWithNext {
            return (MessageTableCellState.BubbleState.Middle, separatorDate)
        }
        return (MessageTableCellState.BubbleState.Isolated, separatorDate)
    }
    
    func getActualMessageFrom(
        message: TransactionMessage?,
        originalMessagesMap: [String: TransactionMessage]
    ) -> TransactionMessage? {
        if let threadUUID = message?.threadUUID, let originalMsg = originalMessagesMap[threadUUID] {
            return originalMsg
        }
        return message
    }
    
    func getReplyingMessagesMapFor(
        messages: [TransactionMessage]
    ) -> [String: TransactionMessage] {
        
        let replayingUUIDs: [String] = messages.map({ $0.replyUUID ?? "" }).filter({ $0.isNotEmpty })
        let replyingMessages = TransactionMessage.getMessagesWith(uuids: replayingUUIDs)
        var replyingMessagesMap: [String: TransactionMessage] = [:]
        
        replyingMessages.map({ ( ($0.uuid ?? "-"), $0) }).forEach {
            replyingMessagesMap[$0.0] = $0.1
        }
        
        return replyingMessagesMap
    }
    
    func getPurchaseMessagesMapFor(
        messages: [TransactionMessage]
    ) -> [String: [Int: TransactionMessage]] {
        
        guard let chat = chat else {
            return [:]
        }
        
        let messageMUIDs: [String] = messages.map({ $0.getMUID() }).filter({ $0.isNotEmpty })
        let purchaseMessages = TransactionMessage.getPurchaseItemsFor(messageMUIDs, on: chat)
        
        var purchaseMessagesMap: [String: [Int: TransactionMessage]] = [:]
        
        for purchaseMessage in purchaseMessages {
            
            let muid = (purchaseMessage.originalMuid?.isNotEmpty == true) ? purchaseMessage.originalMuid : purchaseMessage.muid
            
            if let muid = muid, muid.isNotEmpty {
                if var _ = purchaseMessagesMap[muid] {
                    purchaseMessagesMap[muid]![purchaseMessage.type] = purchaseMessage
                } else {
                    purchaseMessagesMap[muid] = [purchaseMessage.type: purchaseMessage]
                }
            }
        }
        
        return purchaseMessagesMap
    }
    
    func getBoostMessagesMapFor(
        messages: [TransactionMessage]
    ) -> [String: [TransactionMessage]] {
        
        guard let chat = chat else {
            return [:]
        }
        
        let messageUUIDs: [String] = messages.map({ $0.uuid ?? "" }).filter({ $0.isNotEmpty })
        let boostMessages = TransactionMessage.getBoostMessagesFor(messageUUIDs, on: chat)
        
        var boostMessagesMap: [String: [TransactionMessage]] = [:]
        
        for boostMessage in boostMessages {
            if let replyUUID = boostMessage.replyUUID, replyUUID.isNotEmpty {
                if let map = boostMessagesMap[replyUUID], map.count > 0 {
                    boostMessagesMap[replyUUID]?.append(boostMessage)
                } else {
                    boostMessagesMap[replyUUID] = [boostMessage]
                }
            }
        }
        
        return boostMessagesMap
    }
    
    @objc func getThreadMessagesFor(
        messages: [TransactionMessage]
    ) -> [String: [TransactionMessage]] {
        
        guard let chat = chat else {
            return [:]
        }
        
        if !chat.isPublicGroup() {
            return [:]
        }
        
        let messageUUIDs: [String] = messages.filter({ !$0.isDeleted() }).map({ $0.uuid ?? "" }).filter({ $0.isNotEmpty })
        let threadMessages = TransactionMessage.getThreadMessagesFor(messageUUIDs, on: chat)
        
        var threadMessagesMap: [String: [TransactionMessage]] = [:]
        
        for threadMessage in threadMessages {
            if let threadUUID = threadMessage.threadUUID {
                if let map = threadMessagesMap[threadUUID], map.count > 0 {
                    threadMessagesMap[threadUUID]?.append(threadMessage)
                } else {
                    threadMessagesMap[threadUUID] = [threadMessage]
                }
            }
        }
        
        threadMessagesMap = threadMessagesMap.filter({
            $0.value.count > 1
        })
        
        return threadMessagesMap
    }
    
    func getOriginalMessagesFor(
        threadMessages: [TransactionMessage],
        threadMessagesMap: [String: [TransactionMessage]]
    ) -> [String: TransactionMessage] {
        
        guard let chat = chat else {
            return [:]
        }
        
        if !chat.isPublicGroup() {
            return [:]
        }
        
        let messageThreadUUIDs: [String] = threadMessages.map({ $0.threadUUID ?? "" }).filter({ $0.isNotEmpty })
        let originalMessages = TransactionMessage.getOriginalMessagesFor(messageThreadUUIDs, on: chat)
        
        var originalMessagesMap: [String: TransactionMessage] = [:]
        
        for originalMessage in originalMessages {
            if let uuid = originalMessage.uuid {
                if let threadMessages = threadMessagesMap[uuid], threadMessages.count > 1 {
                    originalMessagesMap[uuid] = originalMessage
                }
            }
        }
        
        return originalMessagesMap
    }
    
    func getLinkContactsArrayFor(
        messages: [TransactionMessage]
    ) -> [Int: MessageTableCellState.LinkContact] {
        
        var pubkeys: [Int: (String, String?)] = [:]
        
        messages.forEach({
            if $0.bubbleMessageContentString?.hasPubkeyLinks == true {
                if let link = $0.messageContent?.stringFirstLink, link.isPubKey {
                    pubkeys[$0.id] = (
                        link.pubkeyComponents.0,
                        link.pubkeyComponents.1
                    )
                }
            }
        })
        
        let contacts = UserContact.getContactsWith(pubkeys: Array(pubkeys.values.map({ $0.0 })))
        var linkContactsMap: [Int: MessageTableCellState.LinkContact] = [:]
        
        pubkeys.forEach({ (key, value) in
            linkContactsMap[key] = MessageTableCellState.LinkContact(
                pubkey: value.0,
                routeHint: value.1,
                contact: contacts.filter({ $0.publicKey == value.0 }).first
            )
        })
        
        return linkContactsMap
    }
    
    
    func getLinkTribesArrayFor(
        messages: [TransactionMessage]
    ) -> [Int: MessageTableCellState.LinkTribe] {
        
        var linksAndUUIDs: [Int: (String, String)] = [:]
        
        messages.forEach({
            if $0.bubbleMessageContentString?.hasTribeLinks == true {
                if let link = $0.messageContent?.stringFirstLink, link.isTribeJoinLink {
                    if let uuid = GroupsManager.sharedInstance.getGroupInfo(query: link)?.uuid {
                        linksAndUUIDs[$0.id] = (link, uuid)
                    }
                }
            }
        })
        
        let chats = Chat.getChatsWith(uuids: linksAndUUIDs.values.map({ $0.1 }))
        
        var linkTribesMap: [Int: MessageTableCellState.LinkTribe] = [:]
        
        linksAndUUIDs.forEach({ (key, value) in
            linkTribesMap[key] = MessageTableCellState.LinkTribe(
                link: value.0,
                uuid: value.1,
                isJoined: chats.filter({ $0.uuid == value.1 }).count > 0
            )
        })
        
        return linkTribesMap
    }
    
    func getWebLinksArrayFor(
        messages: [TransactionMessage]
    ) -> [Int: MessageTableCellState.LinkWeb] {
        
        var links: [Int: String] = [:]
        
        messages.forEach({
            if $0.bubbleMessageContentString?.hasLinks == true {
                if let link = $0.messageContent?.stringFirstLink, !link.isTribeJoinLink && !link.isPubKey {
                    links[$0.id] = link
                }
            }
        })
        
        var webLinkMap: [Int: MessageTableCellState.LinkWeb] = [:]
        
        links.forEach({ (key, value) in
            webLinkMap[key] = MessageTableCellState.LinkWeb(link: value)
        })
        
        return webLinkMap
    }
    
    func reloadWith(pinnedMessageId: Int) {
        self.pinnedMessageId = pinnedMessageId
        
        let result = messagesArray.filter({ $0.id == pinnedMessageId })
        
        if result.isEmpty {
            restorePreloadedOrLoadMessages()
        } else {
            restoreScrollLastPosition()
        }
        
        DelayPerformedHelper.performAfterDelay(seconds: 2.0, completion: {
            self.pinnedMessageId = nil
        })
    }
}



extension NewChatTableDataSource : NSFetchedResultsControllerDelegate {
    
    func startListeningToResultsController() {
        messagesResultsController?.delegate = self
        additionMessagesResultsController?.delegate = self
    }
    
    func stopListeningToResultsController() {
        messagesResultsController?.delegate = nil
        additionMessagesResultsController?.delegate = nil
    }
    
    @objc func getFetchRequestFor(
        chat: Chat,
        with items: Int
    ) -> NSFetchRequest<TransactionMessage> {
        return TransactionMessage.getChatMessagesFetchRequest(
            for: chat,
            with: items,
            pinnedMessageId: pinnedMessageId
        )
    }
    
    func configureResultsController(items: Int) {
        guard let chat = chat else {
            return
        }
        
        if messagesArray.count < messagesCount {
            return
        }
        
        messagesCount = items
        
        let fetchRequest = getFetchRequestFor(chat: chat, with: items)
        
        messagesResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataManager.sharedManager.persistentContainer.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        messagesResultsController.delegate = self
        
        do {
            try self.messagesResultsController.performFetch()
        } catch {}
    }
    
    func configureBoostAndPurchaseResultsController() {
        guard let chat = chat else {
            return
        }
        
        if let _ = additionMessagesResultsController {
            return
        }
        
        let fetchRequest = TransactionMessage.getBoostsAndPurchaseMessagesFetchRequestOn(chat: chat)

        additionMessagesResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataManager.sharedManager.persistentContainer.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        additionMessagesResultsController.delegate = self
        
        do {
            try self.additionMessagesResultsController.performFetch()
        } catch {}
    }
    
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        if let resultController = controller as? NSFetchedResultsController<NSManagedObject>,
            let firstSection = resultController.sections?.first {
            
            if controller == messagesResultsController {
                if let messages = firstSection.objects as? [TransactionMessage] {
                    self.messagesArray = messages.reversed().filter { $0.isOnlyText() }
                    
                    if !(self.delegate?.isOnStandardMode() ?? true) {
                        return
                    }
                    
                    self.UIUpdateIndex += 1
                    
                    self.processMessages(messages: self.messagesArray, UIUpdateIndex: self.UIUpdateIndex)
                    self.configureBoostAndPurchaseResultsController()
                }
            } else {
                if !(self.delegate?.isOnStandardMode() ?? true) {
                    return
                }
                
                self.UIUpdateIndex += 1
                
                self.processMessages(messages: self.messagesArray, UIUpdateIndex: self.UIUpdateIndex)
            }
        }
    }
    
    func resetFetchedResultsControllers() {
        additionMessagesResultsController = nil
        messagesResultsController = nil
    }
}
