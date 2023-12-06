//
//  MediaLoader.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 14/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import AVFoundation
import SDWebImage

class MediaLoader {
    
    static let cache = SphinxCache()
    
    class func loadDataFrom(URL: URL, includeToken: Bool = true, completion: @escaping (Data, String?) -> (), errorCompletion: @escaping () -> ()) {
        if !ConnectivityHelper.isConnectedToInternet {
            errorCompletion()
            return
        }
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 30
        sessionConfig.timeoutIntervalForResource = 30
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: URL as URL)
        
        if let token: String = UserDefaults.Keys.attachmentsToken.get(), includeToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if let _ = error {
                errorCompletion()
            } else if let data = data {
                completion(data, response?.getFileName())
            }
        })
        task.resume()
    }
    
    class func asyncLoadImage(imageView: NSImageView, nsUrl: URL, placeHolderImage: NSImage?, completion: (() -> ())? = nil) {
        imageView.sd_setImage(with: nsUrl, placeholderImage: placeHolderImage, options: [SDWebImageOptions.progressiveLoad, SDWebImageOptions.retryFailed], completed: { (image, error, _, _) in
            if let completion = completion, let _ = image {
                DispatchQueue.main.async {
                    completion()
                }
            }
        })
    }
    
    class func asyncLoadImage(imageView: NSImageView, nsUrl: URL, placeHolderImage: NSImage?, id: Int, completion: @escaping ((NSImage, Int) -> ()), errorCompletion: ((Error) -> ())? = nil) {
        imageView.sd_setImage(with: nsUrl, placeholderImage: placeHolderImage, options: SDWebImageOptions.progressiveLoad, completed: { (image, error, _, _) in
            if let image = image {
                DispatchQueue.main.async {
                    completion(image, id)
                }
            } else if let errorCompletion = errorCompletion, let error = error {
                DispatchQueue.main.async {
                    errorCompletion(error)
                }
            }
        })
    }
    
    class func asyncLoadImage(imageView: NSImageView, nsUrl: URL, placeHolderImage: NSImage?, completion: @escaping ((NSImage) -> ()), errorCompletion: ((Error) -> ())? = nil) {
        imageView.sd_setImage(with: nsUrl, placeholderImage: placeHolderImage, options: [SDWebImageOptions.progressiveLoad, SDWebImageOptions.retryFailed], completed: { (image, error, _, _) in
            if let image = image {
                DispatchQueue.main.async {
                    completion(image)
                }
            } else if let errorCompletion = errorCompletion, let error = error {
                DispatchQueue.main.async {
                    errorCompletion(error)
                }
            }
        })
    }
    
    class func loadImage(url: URL, message: TransactionMessage, completion: @escaping (Int, NSImage) -> (), errorCompletion: @escaping (Int) -> ()) {
        let messageId = message.id
        let isGif = message.isGif()
        
        if message.isMediaExpired() {
            clearImageCacheFor(url: url.absoluteString)
            errorCompletion(messageId)
            return
        } else if let cachedImage = getImageFromCachedUrl(url: url.absoluteString) {
            if !isGif || (isGif && getMediaDataFromCachedUrl(url: url.absoluteString) != nil) {
                completion(messageId, cachedImage)
                return
            }
        }
        
        loadDataFrom(URL: url, completion: { data, fileName in
            message.saveFileName(fileName)
            DispatchQueue.main.async {
                loadImageFromData(data: data, url: url, message: message, completion: completion, errorCompletion: errorCompletion)
            }
        }, errorCompletion: {
            DispatchQueue.main.async {
                errorCompletion(messageId)
            }
        })
    }
    
    class func loadImageFromData(data: Data, url: URL, message: TransactionMessage, completion: @escaping (Int, NSImage) -> (), errorCompletion: @escaping (Int) -> ()) {
        let messageId = message.id
        let isGif = message.isGif()
        let isPdf = message.isPDF()
        var decryptedImage:NSImage? = nil
        
        if let image = NSImage(data: data) {
            decryptedImage = image
        } else if let mediaKey = message.getMediaKey(), mediaKey != "" {
            if let decryptedData = SymmetricEncryptionManager.sharedInstance.decryptData(data: data, key: mediaKey) {
                message.saveFileSize(decryptedData.count)
                
                if isGif || isPdf {
                    storeMediaDataInCache(data: decryptedData, url: url.absoluteString)
                }
                
                decryptedImage = getImageFromData(decryptedData, isPdf: isPdf)
            }
        }
        
        if let decryptedImage = decryptedImage {
            storeImageInCache(img: decryptedImage, url: url.absoluteString)
            
            DispatchQueue.main.async {
                completion(messageId, decryptedImage)
            }
        } else {
            DispatchQueue.main.async {
                errorCompletion(messageId)
            }
        }
    }
    
    class func getImageFromData(_ data: Data, isPdf: Bool) -> NSImage? {
        if isPdf {
            if let image = data.getPDFThumbnail() {
                return image
            }
        }
        return NSImage(data: data)
    }
    
    class func loadMessageData(url: URL, message: TransactionMessage, completion: @escaping (Int, String) -> (), errorCompletion: @escaping (Int) -> ()) {
        let messageId = message.id
        
        loadDataFrom(URL: url, completion: { data, fileName in
            if let mediaKey = message.getMediaKey(), mediaKey != "" {
                if let data = SymmetricEncryptionManager.sharedInstance.decryptData(data: data, key: mediaKey) {
                    let str = String(decoding: data, as: UTF8.self)
                    if str != "" {
                        DispatchQueue.main.async {
                            message.messageContent = str
                            completion(messageId, str)
                        }
                        return
                    }
                }
            }
            DispatchQueue.main.async {
                errorCompletion(messageId)
            }
        }, errorCompletion: {
            DispatchQueue.main.async {
                errorCompletion(messageId)
            }
        })
    }
    
    class func loadVideo(url: URL, message: TransactionMessage, completion: @escaping (Int, Data, NSImage?) -> (), errorCompletion: @escaping (Int) -> ()) {
        let messageId = message.id
        
        if message.isMediaExpired() {
            clearImageCacheFor(url: url.absoluteString)
            clearMediaDataCacheFor(url: url.absoluteString)
            errorCompletion(messageId)
        } else if let data = getMediaDataFromCachedUrl(url: url.absoluteString) {
            let image = self.getImageFromCachedUrl(url: url.absoluteString) ?? nil
            if image == nil {
                self.getThumbnailImageFromVideoData(data: data, videoUrl: url.absoluteString, completion: { image in
                    DispatchQueue.main.async {
                        completion(messageId, data, image)
                    }
                })
            } else {
                DispatchQueue.main.async {
                    completion(messageId, data, image)
                }
            }
        } else {
            loadDataFrom(URL: url, completion: { data, fileName in
                message.saveFileName(fileName)
                self.loadMediaFromData(data: data, url: url, message: message, completion: { data in
                    self.getThumbnailImageFromVideoData(data: data, videoUrl: url.absoluteString, completion: { image in
                        DispatchQueue.main.async {
                            completion(messageId, data, image)
                        }
                    })
                }, errorCompletion: errorCompletion)
            }, errorCompletion: {
                DispatchQueue.main.async {
                    errorCompletion(messageId)
                }
            })
        }
    }
    
    class func loadAudio(url: URL, message: TransactionMessage, completion: @escaping (Int, Data) -> (), errorCompletion: @escaping (Int) -> ()) {
        loadFileData(url: url, message: message, completion: completion, errorCompletion: errorCompletion)
    }
    
    class func loadPDF(url: URL, message: TransactionMessage, completion: @escaping (Int, Data) -> (), errorCompletion: @escaping (Int) -> ()) {
        loadFileData(url: url, message: message, completion: completion, errorCompletion: errorCompletion)
    }
    
    class func loadFileData(url: URL, message: TransactionMessage, completion: @escaping (Int, Data) -> (), errorCompletion: @escaping (Int) -> ()) {
        let messageId = message.id
        
        if message.isMediaExpired() {
            clearMediaDataCacheFor(url: url.absoluteString)
            errorCompletion(messageId)
        } else if let data = getMediaDataFromCachedUrl(url: url.absoluteString) {
            DispatchQueue.main.async {
                completion(messageId, data)
            }
        } else {
            loadDataFrom(URL: url, completion: { data, fileName in
                message.saveFileName(fileName)
                self.loadMediaFromData(data: data, url: url, message: message, completion: { data in
                    DispatchQueue.main.async {
                        completion(messageId, data)
                    }
                }, errorCompletion: errorCompletion)
            }, errorCompletion: {
                DispatchQueue.main.async {
                    errorCompletion(messageId)
                }
            })
        }
    }
    
    class func getFileAttachmentData(url: URL, message: TransactionMessage, completion: @escaping (Int, Data) -> (), errorCompletion: @escaping (Int) -> ()) {
        let messageId = message.id
        
        if let data = getMediaDataFromCachedUrl(url: url.absoluteString) {
            DispatchQueue.main.async {
                completion(messageId, data)
            }
        } else {
            DispatchQueue.main.async {
                errorCompletion(messageId)
            }
        }
    }
    
    class func loadMediaFromData(data: Data, url: URL, message: TransactionMessage, completion: @escaping (Data) -> (), errorCompletion: @escaping (Int) -> ()) {
        if let mediaKey = message.getMediaKey(), mediaKey != "" {
            if let decryptedData = SymmetricEncryptionManager.sharedInstance.decryptData(data: data, key: mediaKey) {
                message.saveFileSize(decryptedData.count)
                storeMediaDataInCache(data: decryptedData, url: url.absoluteString)
                DispatchQueue.main.async {
                    completion(decryptedData)
                }
                return
            }
            DispatchQueue.main.async {
                errorCompletion(message.id)
            }
        } else {
            storeMediaDataInCache(data: data, url: url.absoluteString)
            DispatchQueue.main.async {
                completion(data)
            }
        }
    }
    
    class func loadAvatarImage(url: String, objectId: Int, completion: @escaping (NSImage?, Int) -> ()) {
        if let data = getMediaDataFromCachedUrl(url: url) {
            if let image = NSImage(data: data) {
                DispatchQueue.main.async {
                    completion(image, objectId)
                }
                return
            }
        }
        
        if let nsurl = URL(string: url) {
            loadDataFrom(URL: nsurl, completion: { data, _ in
                storeMediaDataInCache(data: data, url: nsurl.absoluteString)
                if let image = NSImage(data: data) {
                    DispatchQueue.main.async {
                        completion(image, objectId)
                    }
                }
            }, errorCompletion: {
                DispatchQueue.main.async {
                    completion(nil, objectId)
                }
            })
        }
    }
    
    class func loadTemplate(row: Int, muid: String, completion: @escaping (Int, String, NSImage) -> ()) {
        let urlString = "\(API.kAttachmentsServerUrl)/template/\(muid)"
        
        if let url = URL(string: urlString) {
            if let cachedImage = getImageFromCachedUrl(url: url.absoluteString) {
                DispatchQueue.main.async {
                    completion(row, muid, cachedImage)
                }
            } else {
                loadDataFrom(URL: url, includeToken: true, completion: { data, _ in
                    if let image = NSImage(data: data) {
                        self.storeImageInCache(img: image, url: url.absoluteString)
                        
                        DispatchQueue.main.async {
                            completion(row, muid, image)
                        }
                        return
                    }
                }, errorCompletion: {})
            }
        }
    }
    
    class func getDataFromUrl(url: URL) -> Data? {
        var videoData: Data?
        do {
            videoData = try Data(contentsOf: url as URL, options: Data.ReadingOptions.alwaysMapped)
        } catch _ {
            videoData = nil
        }
        
        guard let data = videoData else {
            return nil
        }
        return data
    }
    
    class func getThumbnailImageFromVideoData(data: Data, videoUrl: String?, completion: @escaping ((_ image: NSImage?)->Void)) {
        guard var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        url.appendPathComponent("video.mov")
        do {
            try data.write(to: url)
        } catch {
            return
        }
        
        let asset = AVAsset(url: url)
        
        DispatchQueue.global().async {
            let avAssetImageGenerator = AVAssetImageGenerator(asset: asset)
            avAssetImageGenerator.appliesPreferredTrackTransform = true
            let thumnailTime = CMTimeMake(value: 5, timescale: 1)
            do {
                let cgThumbImage = try avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil)
                let thumbImage = NSImage(cgImage: cgThumbImage, size: NSSize(width: 220, height: 220))
                deleteItemAt(url: url)
                
                if let videoUrl = videoUrl {
                    storeImageInCache(img: thumbImage, url: videoUrl)
                }
                DispatchQueue.main.async {
                    completion(thumbImage)
                }
            } catch {
                deleteItemAt(url: url)
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    class func clearMessageMediaCache(message: TransactionMessage) {
        if let url = message.getMediaUrl() {
            clearImageCacheFor(url: url.absoluteString)
            clearMediaDataCacheFor(url: url.absoluteString)
        }
    }
    
    class func clearImageCacheFor(url: String) {
        SDImageCache.shared.removeImage(forKey: url, withCompletion: nil)
        cache.removeValue(forKey: url)
    }
    
    class func storeImageInCache(img: NSImage, url: String) {
        SDImageCache.shared.store(img, forKey: url, completion: nil)
    }
    
    class func getImageFromCachedUrl(url: String) -> NSImage? {
        return SDImageCache.shared.imageFromCache(forKey: url)
    }
    
    class func storeMediaDataInCache(data: Data, url: String) {
        cache[url] = data
    }
    
    class func getMediaDataFromCachedUrl(url: String) -> Data? {
        return cache[url]
    }
    
    class func clearMediaDataCacheFor(url: String) {
        return cache.removeValue(forKey: url)
    }
        
    class func deleteItemAt(url: URL) {
        do {
            try FileManager().removeItem(at: url)
        } catch {
            
        }
    }
}

extension MediaLoader {
    class func loadPaymentTemplateImage(
        url: URL,
        message: TransactionMessage,
        completion: @escaping (Int, NSImage) -> (), errorCompletion: @escaping (Int) -> ()
    ) {
        if let cachedImage = getImageFromCachedUrl(url: url.absoluteString) {
            completion(message.id, cachedImage)
        } else {
            loadDataFrom(URL: url, includeToken: true, completion: { (data, _) in
                if let image = NSImage(data: data) {
                    self.storeImageInCache(
                        img: image,
                        url: url.absoluteString
                    )
                    
                    DispatchQueue.main.async {
                        completion(message.id, image)
                    }
                    return
                }
            }, errorCompletion: {})
        }
    }
    
    class func loadImage(
        url: URL,
        message: TransactionMessage,
        mediaKey: String?,
        completion: @escaping (Int, NSImage?, Data?) -> (),
        errorCompletion: @escaping (Int) -> ()
    ) {
        let messageId = message.id
        let isGif = message.isGif()
        
        if message.isMediaExpired() {
            clearImageCacheFor(url: url.absoluteString)
            errorCompletion(messageId)
            return
        } else if let cachedImage = getImageFromCachedUrl(url: url.absoluteString), !isGif {
            DispatchQueue.main.async {
                completion(messageId, cachedImage, nil)
            }
            return
        } else if let cachedData = getMediaDataFromCachedUrl(url: url.absoluteString), isGif {
            DispatchQueue.main.async {
                completion(messageId, nil, cachedData)
            }
            return
        }
        
        loadDataFrom(URL: url, completion: { (data, fileName) in
            message.saveFileName(fileName)
            
            DispatchQueue.main.async {
                loadImageFromData(
                    data: data,
                    url: url,
                    message: message,
                    mediaKey: mediaKey,
                    completion: completion,
                    errorCompletion: errorCompletion
                )
            }
        }, errorCompletion: {
            DispatchQueue.main.async {
                errorCompletion(messageId)
            }
        })
    }
    
    class func loadImageFromData(
        data: Data,
        url: URL,
        message: TransactionMessage,
        mediaKey: String?,
        completion: @escaping (Int, NSImage?, Data?) -> (),
        errorCompletion: @escaping (Int) -> ()
    ) {
        let messageId = message.id
        let isGif = message.isGif()
        let isPDF = message.isPDF()
        var decryptedImage:NSImage? = nil
        
        if let image = NSImage(data: data) {
            decryptedImage = image
        } else if let mediaKey = mediaKey, mediaKey != "" {
            if let decryptedData = SymmetricEncryptionManager.sharedInstance.decryptData(data: data, key: mediaKey) {
                message.saveFileSize(decryptedData.count)
                
                if isGif || isPDF {
                    storeMediaDataInCache(data: decryptedData, url: url.absoluteString)
                }
                decryptedImage = getImageFromData(decryptedData, isPdf: isPDF)
            }
        }
        
        if let decryptedImage = decryptedImage {
            storeImageInCache(
                img: decryptedImage,
                url: url.absoluteString
            )
            
            DispatchQueue.main.async {
                completion(messageId, decryptedImage, nil)
            }
        } else {
            DispatchQueue.main.async {
                errorCompletion(messageId)
            }
        }
    }
    
    class func loadFileData(
        url: URL,
        message: TransactionMessage,
        mediaKey: String?,
        completion: @escaping (Int, Data) -> (),
        errorCompletion: @escaping (Int) -> ()
    ) {
        let messageId = message.id
        
        if message.isMediaExpired() {
            clearMediaDataCacheFor(url: url.absoluteString)
            errorCompletion(messageId)
        } else if let data = getMediaDataFromCachedUrl(url: url.absoluteString) {
            DispatchQueue.main.async {
                completion(messageId, data)
            }
        } else {
            loadDataFrom(URL: url, completion: { (data, fileName) in
                message.saveFileName(fileName)
                
                self.loadMediaFromData(
                    data: data,
                    url: url,
                    message: message,
                    mediaKey: mediaKey,
                    completion: { data in
                        DispatchQueue.main.async {
                            completion(messageId, data)
                        }
                    },
                    errorCompletion: errorCompletion
                )
            }, errorCompletion: {
                DispatchQueue.main.async {
                    errorCompletion(messageId)
                }
            })
        }
    }
    
    class func loadFileData(
        url: URL,
        isPdf: Bool,
        message: TransactionMessage,
        mediaKey: String?,
        completion: @escaping (Int, Data, MessageTableCellState.FileInfo) -> (),
        errorCompletion: @escaping (Int) -> ()
    ) {
        let messageId = message.id
        
        if message.isMediaExpired() {
            clearMediaDataCacheFor(url: url.absoluteString)
            errorCompletion(messageId)
        } else if let data = getMediaDataFromCachedUrl(url: url.absoluteString) {
            
            let fileInfo = MessageTableCellState.FileInfo(
                fileSize: message.mediaFileSize,
                fileName: message.mediaFileName ?? "",
                pagesCount: isPdf ? data.getPDFPagesCount() : nil,
                previewImage: isPdf ? data.getPDFThumbnail() : nil
            )
            
            DispatchQueue.main.async {
                completion(
                    messageId,
                    data,
                    fileInfo
                )
            }
        } else {
            loadDataFrom(URL: url, completion: { (data, fileName) in
                message.saveFileName(fileName)
                
                self.loadMediaFromData(
                    data: data,
                    url: url,
                    message: message,
                    mediaKey: mediaKey,
                    completion: { data in
                        let fileInfo = MessageTableCellState.FileInfo(
                            fileSize: message.mediaFileSize,
                            fileName: message.mediaFileName ?? "",
                            pagesCount: isPdf ? data.getPDFPagesCount() : nil,
                            previewImage: isPdf ? data.getPDFThumbnail() : nil
                        )
                        
                        DispatchQueue.main.async {
                            completion(messageId, data, fileInfo)
                        }
                    },
                    errorCompletion: errorCompletion
                )
            }, errorCompletion: {
                DispatchQueue.main.async {
                    errorCompletion(messageId)
                }
            })
        }
    }
    
    class func loadMediaFromData(
        data: Data,
        url: URL, message: TransactionMessage,
        mediaKey: String? = nil,
        isVideo: Bool = false,
        completion: @escaping (Data) -> (),
        errorCompletion: @escaping (Int) -> ()
    ) {
        if let mediaKey = mediaKey, mediaKey != "" {
            
            if let decryptedData = SymmetricEncryptionManager.sharedInstance.decryptData(
                data: data,
                key: mediaKey
            ) {
                message.saveFileSize(decryptedData.count)

                storeMediaDataInCache(
                    data: decryptedData,
                    url: url.absoluteString
                )

                DispatchQueue.main.async {
                    completion(decryptedData)
                }
                return
            }
        } else {
            storeMediaDataInCache(
                data: data,
                url: url.absoluteString
            )
            
            DispatchQueue.main.async {
                completion(data)
            }
        }
    }
    
    class func loadVideo(
        url: URL,
        message: TransactionMessage,
        mediaKey: String?,
        completion: @escaping (Int, Data, NSImage?) -> (),
        errorCompletion: @escaping (Int) -> ()
    ) {
        let messageId = message.id
        
        if message.isMediaExpired() {
            clearImageCacheFor(url: url.absoluteString)
            clearMediaDataCacheFor(url: url.absoluteString)
            errorCompletion(messageId)
        } else if let data = getMediaDataFromCachedUrl(url: url.absoluteString) {
            let image = self.getImageFromCachedUrl(url: url.absoluteString) ?? nil
            if image == nil {
                self.getThumbnailImageFromVideoData(data: data, videoUrl: url.absoluteString, completion: { image in
                    DispatchQueue.main.async {
                        completion(messageId, data, image)
                    }
                })
            } else {
                DispatchQueue.main.async {
                    completion(messageId, data, image)
                }
            }
        } else {
            loadDataFrom(URL: url, completion: { (data, fileName) in
                message.saveFileName(fileName)
                
                self.loadMediaFromData(
                    data: data,
                    url: url,
                    message: message,
                    mediaKey: mediaKey,
                    isVideo: true,
                    completion: { data in
                        self.getThumbnailImageFromVideoData(data: data, videoUrl: url.absoluteString, completion: { image in
                            DispatchQueue.main.async {
                                completion(messageId, data, image)
                            }
                        })
                    },
                    errorCompletion: errorCompletion
                )
            }, errorCompletion: {
                DispatchQueue.main.async {
                    errorCompletion(messageId)
                }
            })
        }
    }
    
    class func loadMessageData(
        url: URL,
        message: TransactionMessage,
        mediaKey: String?,
        completion: @escaping (Int, String) -> (),
        errorCompletion: @escaping (Int) -> ()
    ) {
        loadDataFrom(URL: url, completion: { (data, _) in
            if let mediaKey = mediaKey, mediaKey.isNotEmpty {
                if let data = SymmetricEncryptionManager.sharedInstance.decryptData(data: data, key: mediaKey) {
                    let str = String(decoding: data, as: UTF8.self)
                    if str != "" {
                        DispatchQueue.main.async {
                            message.messageContent = str
                            
                            completion(
                                message.id,
                                str
                            )
                        }
                        return
                    }
                }
            }
            DispatchQueue.main.async {
                errorCompletion(message.id)
            }
        }, errorCompletion: {
            DispatchQueue.main.async {
                errorCompletion(message.id)
            }
        })
    }
}
