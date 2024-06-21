//
//  TransactionMessageMediaExtension.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 11/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import Cocoa
import CoreData

extension TransactionMessage {
    func getMediaType() -> Int? {
        if self.type == TransactionMessage.TransactionMessageType.attachment.rawValue {
            if let mediaType = self.mediaType, mediaType != "" {
                if mediaType.contains("image") || mediaType.contains("gif") {
                    return TransactionMessage.TransactionMessageType.imageAttachment.rawValue
                } else if mediaType.contains("video") {
                    return TransactionMessage.TransactionMessageType.videoAttachment.rawValue
                } else if mediaType.contains("audio") {
                    return TransactionMessage.TransactionMessageType.audioAttachment.rawValue
                } else if mediaType.contains("sphinx/text") {
                    return TransactionMessage.TransactionMessageType.textAttachment.rawValue
                } else if mediaType.contains("pdf") {
                    return TransactionMessage.TransactionMessageType.pdfAttachment.rawValue
                }
                return TransactionMessage.TransactionMessageType.fileAttachment.rawValue
            } else {
                return TransactionMessage.TransactionMessageType.imageAttachment.rawValue
            }
        }
        return nil
    }
    
    func isPaidAttachment() -> Bool {
        if let price = getAttachmentPrice(), price > 0 {
            return true
        }
        return false
    }
    
    func isPaymentWithImage() -> Bool {
        return self.type == TransactionMessage.TransactionMessageType.directPayment.rawValue && self.mediaToken != nil
    }
    
    func isAttachmentAvailable() -> Bool {
        if isOutgoing() {
            return true
        }
        
        if isMediaExpired() {
            return false
        }
        
        if let price = getAttachmentPrice(), price > 0, getPurchaseAcceptItem() == nil {
            return false
        }
        
        return true
    }
    
    func canBeDownloaded() -> Bool {
        return (type == TransactionMessageType.attachment.rawValue && getMediaType() != TransactionMessageType.textAttachment.rawValue) || isGiphy()
    }
    
    func shouldCacheData() -> Bool {
        return isVideo() || isAudio() || isGif() || isPDF() || isPDF() || isFileAttachment()
    }
    
    func shouldShowPaidAttachmentView() -> Bool {
        if let price = getAttachmentPrice(), price > 0, isIncoming() {
            return true
        }
        return false
    }
    
    func isMediaExpired() -> Bool {
        if let expirationDate = getMediaExpirationDate() {
            let expired = Date().timeIntervalSince1970 > expirationDate.timeIntervalSince1970
            return expired
        }
        return false
    }
    
    func hasMediaKey() -> Bool {
        if let mediaKey = mediaKey {
            return mediaKey.trim() != ""
        }
        return false
    }
    
    func getGiphyUrl() -> URL? {
        if let messageContent = messageContent,
            let urlString = GiphyHelper.getUrlFrom(message: messageContent, small: false) {
            return URL(string: urlString)
        }
        return nil
    }
    
    func getMediaUrl(queryDB: Bool = true) -> URL? {
        let incoming = isIncoming()
        
        if let price = getAttachmentPrice(), price > 0 && incoming {
            if let purchaseAcceptItem = getPurchaseAcceptItem(queryDB: queryDB), let _ = purchaseAcceptItem.mediaToken {
                return purchaseAcceptItem.getMediaUrlFromMediaToken()
            } else {
                return nil
            }
        }
        
        if let url = getMediaUrlFromMediaToken() {
            return url
        }
        
        return nil
    }
    
    func getMediaKey() -> String? {
        let incoming = isIncoming()
        
        if let price = getAttachmentPrice(), price > 0 && incoming {
            if let purchaseAcceptItem = getPurchaseAcceptItem(), let mediaKey = purchaseAcceptItem.mediaKey {
                return mediaKey
            } else {
                return nil
            }
        }
        
        return self.mediaKey
    }
    
    func getMediaUrlFromMediaToken() -> URL? {
        if let mediaToken = mediaToken, let host = getHost() {
            let mediaUrl = "https://\(host)/file/\(mediaToken)".trim()
                        
            if let nsUrl = URL(string: mediaUrl), mediaUrl != "" {
                return nsUrl
            }
        }
        return nil
    }
    
    func getTemplateURL() -> URL? {
        let muid = getMUID()
        if let host = getHost(), let url = URL(string: "https://\(host)/template/\(muid)"), !muid.isEmpty {
            return url
        }
        return nil
    }
    
    func getHost() -> String? {
        if let host = getItemAtIndex(index: 0)?.base64Decoded {
            return host
        }
        return nil
    }
    
    func getMUID() -> String {
        if let muid = self.muid, muid != "" {
            return muid
        }
        
        if let mmuid = getItemAtIndex(index: 1) {
            return mmuid
        }
        return ""
    }
    
    func getMediaExpirationDate() -> Date? {
        if let expiration = getItemAtIndex(index: 3) {
            let miliseconds = (String(expiration).dataFromString)!.uint32
            return Date(timeIntervalSince1970: Double(miliseconds))
        }
        return nil
    }
    
    func getImageRatio() -> Double? {
        if let attributeValue = getMediaAttribute(attribute: "dim") {
            let dimentions = attributeValue.split(separator: "x")
            
            if dimentions.count > 1 {
                if let width = Double(String(dimentions[0])), let height = Double(String(dimentions[1])) {
                    return height / width
                }
            }
        }
        return nil
    }
    
    func getAttachmentPrice() -> Int? {
        if let attributeValue = getMediaAttribute(attribute: "amt") {
            if let price = Int(attributeValue) {
                return price
            }
        } else if let price = self.uploadingObject?.price {
            return price
        }
        return nil
    }
    
    func getItemAtIndex(index: Int) -> String? {
        if let mediaToken = self.mediaToken {
            if let item = TransactionMessage.getItemAtIndex(index: index, on: mediaToken) {
                return item
            }
        }
        return nil
    }
    
    func getMediaAttribute(attribute: String) -> String? {
        if let metaDataItems = getItemAtIndex(index: 4)?.base64Decoded?.split(separator: "&") {
            for mdItem in metaDataItems {
                if String(mdItem).contains("\(attribute)=") {
                    let attributeValue = String(mdItem).replacingOccurrences(of: "\(attribute)=", with: "")
                    return String(attributeValue)
                }
            }
        }
        return nil
    }
    
    func getPurchaseItems(includeAttachment: Bool = false) -> [TransactionMessage] {
        let muid = self.getMUID()
        if muid.isEmpty || isDirectPayment() {
            return []
        }
        
        let attachmentType = TransactionMessageType.attachment.rawValue
        var predicate : NSPredicate!
        if includeAttachment {
            predicate = NSPredicate(format: "(muid == %@ || originalMuid == %@)", muid, muid)
        } else {
            predicate = NSPredicate(format: "(muid == %@ || originalMuid == %@) AND type != %d", muid, muid, attachmentType)
        }
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        let messages: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage")
        
        return messages
    }
    
    func getPurchaseItemWithType(type: Int) -> TransactionMessage? {
        guard let muid = self.muid else {
            return nil
        }
        
        let predicate = NSPredicate(format: "(muid == %@ || originalMuid == %@) AND type == %d", muid, muid, type)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let message: TransactionMessage? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage")
        
        return message
    }
    
    func getPurchaseStateItem() -> (TransactionMessage?, Bool) {
        let purchaseItems = getPurchaseItems(includeAttachment: true)
        for item in purchaseItems {
            if item.isIncoming() {
                return (purchaseItems.last, item.seen)
            }
        }
        return (purchaseItems.last, true)
    }
    
    func addPurchaseItems() {
        if self.type != TransactionMessageType.attachment.rawValue {
            self.purchaseItems = []
            return
        }
        self.purchaseItems = getPurchaseItems()
    }
    
    func getPurchaseItem(queryDB: Bool = true) -> TransactionMessage? {
        return getPurchaseItemWith(type: TransactionMessageType.purchase.rawValue, queryDB: queryDB)
    }
    
    func getPurchaseAcceptItem(queryDB: Bool = true) -> TransactionMessage? {
        return getPurchaseItemWith(type: TransactionMessageType.purchaseAccept.rawValue, queryDB: queryDB)
    }
    
    func getPurchaseDenyItem(queryDB: Bool = true) -> TransactionMessage? {
        return getPurchaseItemWith(type: TransactionMessageType.purchaseDeny.rawValue, queryDB: queryDB)
    }
    
    func getPurchaseItemWith(type: Int, queryDB: Bool = true) -> TransactionMessage? {
        for item in purchaseItems {
            if item.type == type {
                return item
            }
        }
        
        if !queryDB {
            return nil
        }
        
        if let item = getPurchaseItemWithType(type: type) {
            purchaseItems.append(item)
            return item
        }
        
        return nil
    }
    
    func getPurchaseStatus(queryDB: Bool = true) -> TransactionMessageType {
        if let _ = getPurchaseAcceptItem(queryDB: queryDB) {
            return TransactionMessageType.purchaseAccept
        }

        if let _ = getPurchaseDenyItem(queryDB: queryDB) {
            return TransactionMessageType.purchaseDeny
        }
        
        if let _ = getPurchaseItem(queryDB: queryDB) {
            return TransactionMessageType.purchase
        }
        
        return TransactionMessageType(fromRawValue: self.type)
    }
    
    func getPurchaseStatusLabel(queryDB: Bool = true) -> (String, NSColor) {
        let status = getPurchaseStatus(queryDB: queryDB)
        switch(status) {
        case TransactionMessageType.purchaseAccept:
            return ("purchase.succeeded".localized, NSColor.Sphinx.PrimaryGreen)
        case TransactionMessageType.purchaseDeny:
            return ("purchase.denied".localized, NSColor.Sphinx.PrimaryRed)
        case TransactionMessageType.purchase:
            return ("processing".localized, NSColor.Sphinx.PrimaryGreen)
        default:
            return ("pending".localized, NSColor.Sphinx.PrimaryGreen)
        }
    }
    
    func saveFileName(_ fileName: String?) {
        guard let fileName = fileName, !fileName.isEmpty else {
            return
        }
        self.mediaFileName = fileName
    }
    
    func saveFileSize(_ size: Int?) {
        guard let size = size, size > 0 else {
            return
        }
        self.mediaFileSize = size
    }
    
    func saveFileInfo(filename: String?, size: Int?) {
        if let filename = filename, !filename.isEmpty {
            self.mediaFileName = filename
        }
        
        if let size = size, size > 0 {
            self.mediaFileSize = size
        }
    }
    
    //Static methods
    static func getMUIDFrom(mediaToken: String?) -> String? {
        if let mediaToken = mediaToken, let mmuid = getItemAtIndex(index: 1, on: mediaToken) {
            return mmuid
        }
        return nil
    }
    
    static func getItemAtIndex(index: Int, on mediaToken: String) -> String? {
        let items = mediaToken.split(separator: ".", omittingEmptySubsequences: false)
        if items.count > index {
            let item = String(items[index])
            if item.trim() != "" {
                return item
            }
        }
        return nil
    }
}
