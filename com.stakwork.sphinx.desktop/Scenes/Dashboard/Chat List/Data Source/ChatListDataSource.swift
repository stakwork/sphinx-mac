//
//  ChatListDataSource.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 14/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol ChatListDataSourceDelegate: AnyObject {
    func didClickOnChatRow(object: ChatListCommonObject)
//    func didTapAddNewContact()
//    func didTapCreateGroup()
}

class ChatListDataSource : NSObject {
    
    weak var delegate: ChatListDataSourceDelegate?
    
    var chatListObjects = [ChatListCommonObject]()
    
    var collectionView: NSCollectionView! = nil
    
    var selectedChatId : Int? = nil
    var selectedContactId : Int? = nil
    
    init(collectionView: NSCollectionView, delegate: ChatListDataSourceDelegate) {
        super.init()
        
        self.delegate = delegate
        self.collectionView = collectionView
    }
    
    func resetSelection() {
        selectedChatId = nil
        selectedContactId = nil
    }
    
    func updateFrame() {
        self.collectionView.collectionViewLayout?.invalidateLayout()
    }
    
    func setDataAndReload(chatListObjects: [ChatListCommonObject]) {
        self.collectionView.registerItem(ChatListCollectionViewItem.self)
        
        self.chatListObjects = chatListObjects
        self.collectionView.allowsMultipleSelection = false
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.reloadData()
    
        self.collectionView.collectionViewLayout?.invalidateLayout()
        self.collectionView.enclosingScrollView?.contentView.scroll(to: NSPoint(x: 0, y: 0))
    }
    
    func updateDataAndReload(chatListObjects: [ChatListCommonObject]) {
        self.chatListObjects = chatListObjects
        self.collectionView.reloadSections(IndexSet(integer: 0))
    }
    
    func updateContactAndReload(object: ChatListCommonObject) {
        var contactRowIndex:Int? = nil
        
        guard let contact = object as? UserContact else {
            return
        }

        for (index, o) in  chatListObjects.enumerated() {
            let c = (o as? UserContact) ?? (o as? Chat)?.getContact()
            if let c = c {
                var isContactToReplace = false

                if let pk = c.publicKey, let cpk = contact.publicKey, pk != "" && pk == cpk {
                    isContactToReplace = true
                } else if let i = c.invite, let cI = contact.invite, let iS = i.inviteString, let cIS = cI.inviteString {
                    if iS == cIS {
                        isContactToReplace = true
                    }
                }

                if isContactToReplace {
                    chatListObjects[index] = contact.getConversation() ?? contact
                    contactRowIndex = index
                    break
                }
            }
        }

        guard let indexToUpdate = contactRowIndex else {
            return
        }

        let indexPath = IndexPath(item: indexToUpdate, section: 0)
        collectionView.reloadItems(at: [indexPath])
    }
    
    func updateChatAndReload(object: ChatListCommonObject) {
        var chatRowIndex:Int? = nil
        
        guard let chat = object as? Chat else {
            return
        }

        for (index, o) in  chatListObjects.enumerated() {
            let chatObject = (o as? Chat) ?? o.getConversation()
            
            if let c = chatObject {
                if c.id == chat.id {
                    chatListObjects[index] = chat
                    chatRowIndex = index
                    break
                }
            }
        }

        guard let indexToUpdate = chatRowIndex else {
            return
        }

        let indexPath = IndexPath(item: indexToUpdate, section: 0)
        collectionView.reloadItems(at: [indexPath])
    }
}

extension ChatListDataSource : NSCollectionViewDataSource {
  
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
  
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return chatListObjects.count
    }
  
    func collectionView(_ itemForRepresentedObjectAtcollectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ChatListCollectionViewItem"), for: indexPath)
        guard let collectionViewItem = item as? ChatListCollectionViewItem else { return item }
        collectionViewItem.isSelected = false
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
        guard let collectionViewItem = item as? ChatListCollectionViewItem else { return }
        
        let chatListObject = chatListObjects[indexPath.item]
        let isLastRow = indexPath.item == chatListObjects.count - 1
        
        if chatListObject.isConfirmed() {
            let selected = isSelected(chatListObject: chatListObject)
            collectionViewItem.configureChatListRow(object: chatListObject, isLastRow: isLastRow, selected: selected)
        } else if let contact = chatListObject as? UserContact {
            collectionViewItem.configureInvitation(contact: contact, isLastRow: isLastRow)
        }
    }
    
    func isSelected(chatListObject: ChatListCommonObject) -> Bool {
        if let chat = (chatListObject as? Chat) ?? (chatListObject as? UserContact)?.getConversation() {
            return selectedChatId == chat.id
        } else if let contact = (chatListObject as? UserContact) {
            return selectedContactId == contact.id
        }
        return false
    }
    
    func reloadSelectedRow() {
        if let indexPath = getIndexPathOfSelectedRow() {
            collectionView.reloadItems(at: [indexPath])
        }
    }
    
    func getIndexPathOfSelectedRow() -> IndexPath? {
        for (index, chatListObject) in  chatListObjects.enumerated() {
            if let chat = (chatListObject as? Chat) ?? (chatListObject as? UserContact)?.getConversation(), selectedChatId == chat.id {
                return IndexPath(item: index, section: 0)
            } else if let contact = (chatListObject as? UserContact), selectedContactId == contact.id {
                return IndexPath(item: index, section: 0)
            }
        }
        return nil
    }
    
    func getIndexPathOfListObject(_ object: ChatListCommonObject) -> IndexPath? {
        for (index, chatListObject) in  chatListObjects.enumerated() {
            if chatListObject.getObjectId() == object.getObjectId() {
                return IndexPath(item: index, section: 0)
            }
        }
        return nil
    }
}

extension ChatListDataSource : NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return NSSize(width: collectionView.frame.width, height: Constants.kChatListRowHeight)
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        if let indexPath = indexPaths.first {
            chatRowClicked(indexPath: indexPath)
        }
    }
    
    func chatRowClicked(indexPath: IndexPath) {
        let chatListObject = chatListObjects[indexPath.item]
        let previouslySelectedIndexPath = getIndexPathOfSelectedRow()
        
        if let chat = (chatListObject as? Chat) ?? (chatListObject as? UserContact)?.getConversation() {
            chat.setChatMessagesAsSeen(shouldSync: false, shouldSave: false)
            
            selectedChatId = chat.id
            selectedContactId = nil
        } else if let contact = (chatListObject as? UserContact), contact.isConfirmed() {
            selectedContactId = contact.id
            selectedChatId = nil
        }
        
        if let previouslySelectedIndexPath = previouslySelectedIndexPath {
            getPreviouslySelectedChat(index: previouslySelectedIndexPath.item)?.setChatMessagesAsSeen(shouldSave: false)
            collectionView.reloadItems(at: [previouslySelectedIndexPath, indexPath])
        } else {
            collectionView.reloadItems(at: [indexPath])
        }
        delegate?.didClickOnChatRow(object: chatListObject)
    }
    
    func shouldSelectContactOrChat(_ object: ChatListCommonObject) {
        if let indexPath = getIndexPathOfListObject(object) {
            chatRowClicked(indexPath: indexPath)
        }
    }
    
    func getPreviouslySelectedChat(index: Int) -> Chat? {
        if let chat = chatListObjects[index] as? Chat {
            return chat
        } else if let chat = (chatListObjects[index] as? UserContact)?.getConversation() {
            return chat
        }
        return nil
    }
}
