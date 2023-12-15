//
//  MediaDownloader.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 02/07/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import AppKit

class MediaDownloader {
    
    static func getFileName() -> String {
        return "sphinx.\(Date().getStringDate(format: "EEE.dd.MMM.hh.mm.ss"))".lowercased()
    }
    
    static func shouldSaveFile(message: TransactionMessage, completion: @escaping (Bool, String) -> ()) {
        func getErrorMessage(success: Bool, itemType: String) -> String {
            let successfulllySave = String(format: "item.successfully.saved".localized, itemType)
            let errorSaving = String(format: "error.saving.item".localized, itemType)
            
            return success ? successfulllySave : errorSaving
        }
        
        let fileName = getFileName()
        
        if message.isGif() || message.isGiphy() {
            saveGif(message: message, fileName: fileName, completion: { success in
                completion(success, getErrorMessage(success: success, itemType: "image".localized))
            })
        } else if message.isPicture() {
            saveImage(message: message, fileName: fileName, completion: { success in
                completion(success, getErrorMessage(success: success, itemType: "image".localized))
            })
        } else if message.isVideo() {
            saveVideo(message: message, fileName: fileName, completion: { success in
                completion(success, getErrorMessage(success: success, itemType: "video".localized))
            })
        } else if message.isPDF() {
            saveFile(message: message, fileName: message.mediaFileName ?? "\(fileName).pdf", completion: { success in
                completion(success, getErrorMessage(success: success, itemType: "PDF"))
            })
        } else {
            saveFile(message: message, fileName: message.mediaFileName ?? "\(fileName).txt", completion: { success in
                completion(success, getErrorMessage(success: success, itemType: "file".localized))
            })
        }
    }
    
    static func saveFile(message: TransactionMessage, fileName: String, completion: @escaping (Bool) -> ()) {
        if let url = message.getMediaUrl() {
            if let data = MediaLoader.getMediaDataFromCachedUrl(url: url.absoluteString) {
                message.saveFileSize(data.count)
                let success = saveFile(data: data, name: fileName)
                completion(success)
            } else {
                NewMessageBubbleHelper().showLoadingWheel(text: "downloading.file".localized)
                
                MediaLoader.loadFileData(url: url, message: message, completion: { (_, data) in
                    let success = saveFile(data: data, name: fileName)
                    completion(success)
                    NewMessageBubbleHelper().hideLoadingWheel()
                }, errorCompletion: { _ in
                    completion(false)
                    NewMessageBubbleHelper().hideLoadingWheel()
                })
            }
        } else {
            completion(false)
        }
    }
    
    static func saveVideo(message: TransactionMessage, fileName: String, completion: @escaping (Bool) -> ()) {
        if let url = message.getMediaUrl() {
            MediaLoader.loadVideo(url: url, message: message, completion: { (_, data, _) in
                let success = saveFile(data: data, name: "\(fileName).mov")
                completion(success)
            }, errorCompletion: { _ in
                completion(false)
            })
        } else {
            completion(false)
        }
    }
    
    static func saveImage(message: TransactionMessage, fileName: String, completion: @escaping (Bool) -> ()) {
        if let url = message.getMediaUrl() {
            MediaLoader.loadImage(url: url, message: message, completion: { (_, image) in
                if let tiffRepresentation = image.tiffRepresentation,
                    let bitmapImage = NSBitmapImageRep(data: tiffRepresentation),
                    let pngData = bitmapImage.representation(using: .png, properties: [:])
                {
                    let success = saveFile(data: pngData, name: "\(fileName).png")
                    completion(success)
                } else {
                    completion(false)
                }
            }, errorCompletion: { _ in
                completion(false)
            })
        } else {
            completion(false)
        }
    }
    
    static func saveImage(
        url:URL,
        message:TransactionMessage,
        completion:@escaping ()->(),
        errorCompletion:@escaping ()->()
    ){
         let fileName = getFileName()
        
         MediaLoader.loadImage(url: url, message: message, completion: { (_, image) in
             if let imgData = image.tiffRepresentation(using: .jpeg, factor: 1) {
                 let _ = saveFile(data: imgData, name: "\(String(describing: fileName)).jpg")
                 completion()
             } else {
                 errorCompletion()
             }
         }, errorCompletion: { _ in
             errorCompletion()
         })
     }
    
    static func getGifUrlFrom(message: TransactionMessage) -> URL? {
        if let url = message.getMediaUrl() {
            return url
        } else if let urlString = GiphyHelper.getUrlFrom(message: message.messageContent ?? "", small: false) {
            if let url = URL(string: urlString) {
                return url
            }
        }
        return nil
    }
    
    static func saveGif(message: TransactionMessage, fileName: String, completion: @escaping (Bool) -> ()) {
        if let url = getGifUrlFrom(message: message) {
            if let gifData = MediaLoader.getMediaDataFromCachedUrl(url: url.absoluteString) {
                let success = saveFile(data: gifData, name: "\(fileName).gif")
                completion(success)
            } else {
                completion(false)
            }
        } else {
            completion(false)
        }
    }
    
    static func saveDataToFile(data: Data, fileExtension: String) -> Bool {
        let name = "\(getFileName()).\(fileExtension)"
        return saveFile(data: data, name: name)
    }
    
    static func saveFile(data: Data, name: String) -> Bool {
        let fileManager = FileManager.default
        guard let url = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first else { return false }
        let urlWithFileName = url.appendingPathComponent(name)
        var completePath = urlWithFileName.absoluteString
        
        if fileManager.fileExists(atPath: urlWithFileName.path) {
            completePath = "\(urlWithFileName.deletingPathExtension())-copy.\(name.fileExtension())"
        }
        do {
            if let url = URL(string: completePath) {
                try data.write(to: url)
            }
        } catch {
            return false
        }
        return true
    }
}
