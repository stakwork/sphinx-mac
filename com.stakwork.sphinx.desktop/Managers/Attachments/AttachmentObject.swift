//
//  AttachmentObject.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 11/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

public struct AttachmentObject {
    var data: Data!
    var image: NSImage?
    var mediaKey: String?
    var type: AttachmentsManager.AttachmentType
    var text: String?
    var paidMessage: String?
    var price: Int = 0
    var fileName: String? = nil
    
    init(
        data: Data,
        fileName: String? = nil,
        mediaKey: String? = nil,
        type: AttachmentsManager.AttachmentType,
        text: String? = nil,
        paidMessage: String? = nil,
        image: NSImage? = nil,
        price: Int = 0
    ) {
        self.data = data
        self.fileName = fileName
        self.mediaKey = mediaKey
        self.type = type
        self.image = image
        self.text = text
        self.paidMessage = paidMessage
        self.price = price
    }
    
    func getUploadData() -> Data? {
        if type == AttachmentsManager.AttachmentType.Audio ||
           type == AttachmentsManager.AttachmentType.Gif ||
           type == AttachmentsManager.AttachmentType.Text ||
           type == AttachmentsManager.AttachmentType.GenericFile ||
           type == AttachmentsManager.AttachmentType.PDF {
            return data
        }
        return nil
    }
    
    func getMessageData() -> Data? {
        if type == AttachmentsManager.AttachmentType.Text {
            return data
        }
        return nil
    }
    
    func getDecryptedData() -> Data? {
        if
            let data = getUploadData(),
            let mediaKey = mediaKey,
            let decryptedData = SymmetricEncryptionManager.sharedInstance.decryptData(data: data, key: mediaKey)
        {
            return decryptedData
        }
        return nil
    }
    
    func getNameParam() -> String {
        switch(type) {
        case .Photo, .Gif:
            return "image"
        case .Video:
            return "video"
        case .Audio:
            return "audio"
        case .Text:
            return "text"
        case .PDF:
            return "file"
        case .GenericFile:
            return "file"
        }
    }
    
    func getMimeType() -> String {
        return getFileAndMime().1
    }
    
    func getFileName() -> String {
        return getFileAndMime().0
    }
    
    func getFileAndMime() -> (String, String) {
        return AttachmentObject.getFileAndMime(type: self.type, fileName: self.fileName)
    }
    
    func isPDFOrFile() -> Bool {
        return type == AttachmentsManager.AttachmentType.PDF || type == AttachmentsManager.AttachmentType.GenericFile
    }
    
    func isPDF() -> Bool {
        return type == AttachmentsManager.AttachmentType.PDF
    }
    
    func isAudio() -> Bool {
        return type == AttachmentsManager.AttachmentType.Audio
    }
    
    func getFileInfo() -> MessageTableCellState.FileInfo? {
        if !isPDFOrFile() {
            return nil
        }
        
        let pagesCount = isPDF() ? data.getPDFPagesCount() : 0
        let previewImage = isPDF() ? data.getPDFThumbnail() : nil
        
        return MessageTableCellState.FileInfo(
            fileSize: getDecryptedData()?.count ?? 0,
            fileName: getFileName(),
            pagesCount: pagesCount,
            previewImage: previewImage
        )
    }
    
    func getAudioInfo(duration: Double?) -> MessageTableCellState.AudioInfo? {
        if !isAudio() {
            return nil
        }
        
        return MessageTableCellState.AudioInfo(
            loading: false,
            playing: false,
            duration: duration ?? 0.0,
            currentTime: 0.0
        )
    }
    
    static func getFileAndMime(type: AttachmentsManager.AttachmentType, fileName: String?) -> (String, String) {
        switch (type) {
            case .Video:
                return ("video.mov", "video/mov")
            case .Photo:
                return ("image.jpg", "image/jpg")
            case .Audio:
                return ("audio.wav", "audio/wav")
            case .Text:
                return ("message.txt", "sphinx/text")
            case .Gif:
                return ("image.gif", "image/gif")
            case .PDF:
                return (fileName ?? "file.pdf", "application/pdf")
            case .GenericFile:
                return (fileName ?? "file", fileName?.mimeType() ?? "application/octet-stream")
        }
    }
}
