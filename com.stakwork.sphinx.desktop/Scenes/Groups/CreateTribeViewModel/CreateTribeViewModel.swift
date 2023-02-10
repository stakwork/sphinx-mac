//
//  CreateTribeViewModel.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 04/10/2022.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Cocoa
import SDWebImage

class CreateTribeViewModel {
    
    let groupsManager = GroupsManager.sharedInstance
    let messageBubbleHelper = NewMessageBubbleHelper()
    
    var chat: Chat? = nil
    var errorCallback: (() -> ())? = nil
    var successCallback: (() -> ())? = nil
    
    init(
        chat: Chat? = nil,
        successCallback: @escaping () -> (),
        errorCallback: @escaping () -> ()
    ) {
        self.chat = chat
        self.successCallback = successCallback
        self.errorCallback = errorCallback
        
        groupsManager.resetNewGroupInfo()
        
        if let tribeInfo = chat?.tribeInfo {
            groupsManager.newGroupInfo = tribeInfo
        }
    }
    
    func setInfo(
        name: String? = nil,
        description: String? = nil,
        img: String? = nil,
        priceToJoin: Int? = nil,
        pricePerMessage: Int? = nil,
        amountToStake: Int? = nil,
        timeToStake: Int? = nil,
        appUrl: String? = nil,
        feedUrl: String? = nil,
        feedType: FeedContentType? = nil,
        listInTribes: Bool,
        privateTribe: Bool
    ) {
        groupsManager.setInfo(
            name: name,
            description: description,
            img: img,
            priceToJoin: priceToJoin,
            pricePerMessage: pricePerMessage,
            amountToStake: amountToStake,
            timeToStake: timeToStake,
            appUrl: appUrl,
            feedUrl: feedUrl,
            feedType: feedType,
            listInTribes: listInTribes,
            privateTribe: privateTribe
        )
    }
    
    func updateTag(index: Int, selected: Bool) {
        if (groupsManager.newGroupInfo.tags.count >  index) {
            var tag = groupsManager.newGroupInfo.tags[index]
            tag.selected = selected
            groupsManager.newGroupInfo.tags[index] = tag
        }
    }
    
    func updateFeedType(type: FeedContentType) {
        groupsManager.newGroupInfo.feedContentType = type
    }
    
    func tribeInfo() -> GroupsManager.TribeInfo? {
        return groupsManager.newGroupInfo
    }
    
    func isEditing() -> Bool {
        return chat?.id != nil
    }
    
    func saveChanges(_ image: NSImage? = nil) {
        if let image = image, let imgData = image.sd_imageData(as: .JPEG, compressionQuality: 0.5) {

            let attachmentsManager = AttachmentsManager.sharedInstance
            attachmentsManager.delegate = self
            
            let attachmentObject = AttachmentObject(data: imgData, type: AttachmentsManager.AttachmentType.Photo)
            attachmentsManager.uploadPublicImage(attachmentObject: attachmentObject)
        } else {
            editOrCreateGroup()
        }
    }
    
    func editOrCreateGroup() {
        let params = groupsManager.getNewGroupParams()
        
        if let chat = chat {
            editGroup(id: chat.id, params: params)
        } else {
            createGroup(params: params)
        }
    }
    
    func createGroup(params: [String: AnyObject]) {
        API.sharedInstance.createGroup(params: params, callback: { chatJson in
            if let _ = Chat.insertChat(chat: chatJson) {
                self.didSuccessSavingTribe()
            } else {
                self.didFailSavingTribe()
            }
        }, errorCallback: {
            self.didFailSavingTribe()
        })
    }
    
    func editGroup(id: Int, params: [String: AnyObject]) {
        API.sharedInstance.editGroup(id: id, params: params, callback: { chatJson in
            if let chat = Chat.insertChat(chat: chatJson) {
                chat.tribeInfo = self.groupsManager.newGroupInfo
                self.didSuccessSavingTribe()
            } else {
                self.didFailSavingTribe()
            }
        }, errorCallback: {
            self.didFailSavingTribe()
        })
    }
    
    func didFailSavingTribe() {
        self.errorCallback?()
        self.messageBubbleHelper.showGenericMessageView(text: "generic.error.message".localized, delay: 3, textColor: NSColor.white, backColor: NSColor.Sphinx.BadgeRed, backAlpha: 1.0)
    }
    
    func didSuccessSavingTribe() {
        NotificationCenter.default.post(name: .shouldReloadTribeData, object: nil)
        NotificationCenter.default.post(name: .shouldReloadChatsList, object: nil)
        self.successCallback?()
    }
    
}

extension CreateTribeViewModel : AttachmentsManagerDelegate {
    func didUpdateUploadProgress(progress: Int) {}
    
    func didSuccessUploadingImage(url: String) {
        groupsManager.newGroupInfo.img = url
        
        editOrCreateGroup()
    }
}
