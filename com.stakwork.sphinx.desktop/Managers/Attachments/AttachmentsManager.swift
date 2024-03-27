//
//  AttachmentsManager.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 11/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON
import AVFoundation

@objc protocol AttachmentsManagerDelegate: AnyObject {
    @objc optional func didUpdateUploadProgress(progress: Int, provisionalMessageId: Int)
    @objc optional func didFailSendingMessage(provisionalMessage: TransactionMessage?)
    @objc optional func didFailSendingAttachment(provisionalMessage: TransactionMessage?)
    @objc optional func didSuccessSendingAttachment(message: TransactionMessage, image: NSImage?, provisionalMessageId: Int)
    @objc optional func didSuccessUploadingImage(url: String)
}

class AttachmentsManager {
    
    class var sharedInstance : AttachmentsManager {
        struct Static {
            static let instance = AttachmentsManager()
        }
        return Static.instance
    }
    
    public enum AttachmentType: Int {
        case Photo
        case Video
        case Audio
        case Gif
        case Text
        case PDF
        case GenericFile
    }
    
    var uploading = false
    var provisionalMessage: TransactionMessage? = nil
    var contact: UserContact? = nil
    var chat: Chat? = nil
    var uploadedImage: NSImage? = nil
    
    weak var delegate: AttachmentsManagerDelegate?
    
    func setData(delegate: AttachmentsManagerDelegate, contact: UserContact?, chat: Chat?, provisionalMessage: TransactionMessage? = nil) {
        self.delegate = delegate
        self.provisionalMessage = provisionalMessage
        self.contact = contact
        self.chat = chat
        self.uploadedImage = nil
    }
    
    func runAuthentication(
        forceAuthenticate: Bool = false
    ) {
        self.authenticate(
            forceAuthenticate: forceAuthenticate,
            completion: {_ in },
            errorCompletion: {}
        )
    }
    
    func authenticate(
        forceAuthenticate: Bool = false,
        completion: @escaping (String) -> (),
        errorCompletion: @escaping () -> ()
    ) {
        if let token: String = UserDefaults.Keys.attachmentsToken.get(), !forceAuthenticate {
            completion(token)
            return
        }
        
        guard let pubkey = UserContact.getOwner()?.publicKey else {
            errorCompletion()
            return
        }
        
        API.sharedInstance.askAuthentication(callback: { id, challenge in
            if let id = id, let challenge = challenge {
                
                self.delegate?.didUpdateUploadProgress?(progress: 10, provisionalMessageId: self.provisionalMessage?.id ?? -1)
                
                guard let sig = SphinxOnionManager.sharedInstance.signChallenge(challenge: challenge) else{
                    errorCompletion()
                    return
                }
                
                self.delegate?.didUpdateUploadProgress?(progress: 15, provisionalMessageId: self.provisionalMessage?.id ?? -1)
                
                API.sharedInstance.verifyAuthentication(id: id, sig: sig, pubkey: pubkey, callback: { token in
                    if let token = token {
                        UserDefaults.Keys.attachmentsToken.set(token)
                        completion(token)
                    } else {
                        errorCompletion()
                    }
                })
                
            } else {
                errorCompletion()
            }
        })
    }
    
    func cancelUpload() {
        API.sharedInstance.cancelUploadRequest()
        uploading = false
        provisionalMessage = nil
        delegate = nil
        uploadedImage = nil
    }
    
    func getMediaItemInfo(message: TransactionMessage, callback: @escaping MediaInfoCallback) {
        guard let token: String = UserDefaults.Keys.attachmentsToken.get() else {
            self.authenticate(completion: { token in
                self.getMediaItemInfo(message: message, callback: callback)
            }, errorCompletion: {
                UserDefaults.Keys.attachmentsToken.removeValue()
            })
            return
        }
        
        API.sharedInstance.getMediaItemInfo(message: message, token: token, callback: callback)
    }
    
    func uploadPublicImage(attachmentObject: AttachmentObject) {
        delegate?.didUpdateUploadProgress?(
            progress: 5,
            provisionalMessageId: provisionalMessage?.id ?? -1
        )
        
        guard let token: String = UserDefaults.Keys.attachmentsToken.get() else {
            self.authenticate(completion: { token in
                self.uploadPublicImage(attachmentObject: attachmentObject)
            }, errorCompletion: {
                UserDefaults.Keys.attachmentsToken.removeValue()
                self.uploadFailed()
            })
            return
        }
        
        delegate?.didUpdateUploadProgress?(
            progress: 10,
            provisionalMessageId: provisionalMessage?.id ?? -1
        )
        
        if let _ = attachmentObject.data {
            uploadData(attachmentObject: attachmentObject, route: "public", token: token) { fileJSON, _ in
                if let muid = fileJSON["muid"] as? String {
                    self.delegate?.didSuccessUploadingImage?(url: "\(API.kAttachmentsServerUrl)/public/\(muid)")
                }
            }
        }
    }
    
    func uploadAndSendAttachment(
        attachmentObject: AttachmentObject,
        chat: Chat?,
        replyingMessage: TransactionMessage? = nil,
        threadUUID: String? = nil
    ) {
        uploading = true
        
        delegate?.didUpdateUploadProgress?(
            progress: 5,
            provisionalMessageId: provisionalMessage?.id ?? -1
        )
        
        guard let token: String = UserDefaults.Keys.attachmentsToken.get() else {
            self.authenticate(completion: { token in
                self.uploadAndSendAttachment(
                    attachmentObject: attachmentObject,
                    chat: chat,
                    replyingMessage: replyingMessage,
                    threadUUID: threadUUID
                )
            }, errorCompletion: {
                UserDefaults.Keys.attachmentsToken.removeValue()
                self.uploadFailed()
            })
            return
        }
        
        delegate?.didUpdateUploadProgress?(
            progress: 10,
            provisionalMessageId: provisionalMessage?.id ?? -1
        )
        
        if let _ = attachmentObject.data {
            uploadData(attachmentObject: attachmentObject, token: token) { fileJSON, AttachmentObject in
                self.sendAttachment(
                    file: fileJSON,
                    chat: chat,
                    attachmentObject: attachmentObject,
                    replyingMessage: replyingMessage,
                    threadUUID: threadUUID
                    
                )
            }
        }
    }
    
    func uploadData(attachmentObject: AttachmentObject, route: String = "file", token: String, completion: @escaping (NSDictionary, AttachmentObject) -> ()) {
        API.sharedInstance.uploadData(attachmentObject: attachmentObject, route: route, token: token, progressCallback: { progress in
            let totalProgress = (progress * 85) / 100 + 10
            self.delegate?.didUpdateUploadProgress?(
                progress: totalProgress,
                provisionalMessageId: self.provisionalMessage?.id ?? -1
            )
        }, callback: { success, fileJSON in
            AttachmentsManager.sharedInstance.uploading = false
            
            if let fileJSON = fileJSON, success {
                self.uploadedImage = attachmentObject.image
                completion(fileJSON, attachmentObject)
            } else {
                self.uploadFailed()
            }
        })
    }
    
    func sendAttachment(
        file: NSDictionary,
        chat: Chat?,
        attachmentObject: AttachmentObject,
        replyingMessage: TransactionMessage? = nil,
        threadUUID: String? = nil
    ) {
        let _ = SphinxOnionManager.sharedInstance.sendAttachment(
            file: file,
            attachmentObject: attachmentObject,
            chat: chat,
            replyingMessage: replyingMessage,
            threadUUID: threadUUID
        )
    }
    
    func payAttachment(message: TransactionMessage, chat: Chat?, callback: @escaping (TransactionMessage?) -> ()) {
        guard let price = message.getAttachmentPrice(), let params = TransactionMessage.getPayAttachmentParams(message: message, amount: price, chat: chat) else {
            return
        }
        
        API.sharedInstance.payAttachment(params: params, callback: { m in
            if let message = TransactionMessage.insertMessage(
                m: m,
                existingMessage: TransactionMessage.getMessageWith(id: m["id"].intValue)
            ).0 {
                callback(message)
            }
        }, errorCallback: {
            callback(nil)

        })
    }
    
    func createLocalMessage(
        message: JSON,
        attachmentObject: AttachmentObject
    ) {
        let provisionalMessageId = provisionalMessage?.id
        
        if let message = TransactionMessage.insertMessage(
            m: message,
            existingMessage: provisionalMessage
        ).0 {
            delegate?.didUpdateUploadProgress?(
                progress: 100,
                provisionalMessageId: self.provisionalMessage?.id ?? -1
            )
            cacheImageAndMediaData(message: message, attachmentObject: attachmentObject)
            uploadSucceed(message: message)
            deleteMessageWith(id: provisionalMessageId)
        }
    }
    
    func deleteMessageWith(id: Int?) {
        if let id = id {
            TransactionMessage.deleteMessageWith(id: id)
        }
    }
    
    func cacheImageAndMediaData(message: TransactionMessage, attachmentObject: AttachmentObject) {
        if let mediaUrl = message.getMediaUrl()?.absoluteString {
            if let data = attachmentObject.data, message.shouldCacheData() {
                if let mediaKey = message.mediaKey {
                    if let decryptedData = SymmetricEncryptionManager.sharedInstance.decryptData(data: data, key: mediaKey) {
                        MediaLoader.storeMediaDataInCache(data: decryptedData, url: mediaUrl)
                    }
                }
            }
            
            if let image = uploadedImage {
                MediaLoader.storeImageInCache(img: image, url: mediaUrl)
            }
        }
    }
    
    func uploadFailed() {
        uploading = false
        delegate?.didFailSendingAttachment?(provisionalMessage: provisionalMessage)
    }
    
    func uploadSucceed(message: TransactionMessage) {
        uploading = false
        delegate?.didSuccessSendingAttachment?(
            message: message,
            image: self.uploadedImage,
            provisionalMessageId: provisionalMessage?.id ?? -1
        )
    }
    
    func getThumbnailFromVideo(videoURL: URL) -> NSImage? {
        var thumbnailImage: NSImage? = nil
        do {
            let asset = AVURLAsset(url: videoURL, options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            thumbnailImage = NSImage(cgImage: cgImage, size: NSSize(width: 220, height: 220))
        } catch _ {}
        
        return thumbnailImage
    }
    
    func getDataAndType(image: NSImage?, video: Data?, videoUrl: URL?) -> (Data?, AttachmentsManager.AttachmentType, NSImage?) {
        if let videoData = video {
            if let videoUrl = videoUrl , let thumbnail = getThumbnailFromVideo(videoURL: videoUrl) {
                return (videoData, AttachmentsManager.AttachmentType.Video, thumbnail)
            } else {
                return (videoData, AttachmentsManager.AttachmentType.Video, nil)
            }
        } else if let imageData = image?.tiffRepresentation(using: .jpeg, factor: 0.5) {
            return (imageData, AttachmentsManager.AttachmentType.Photo, image)
        }
        return (nil, AttachmentsManager.AttachmentType.Photo, nil)
    }
}
