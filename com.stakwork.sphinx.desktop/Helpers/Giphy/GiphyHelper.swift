//
//  GiphyHelper.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 12/08/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON

class GiphyObject: NSObject {
    
    var id: String! = nil
    var aspectRatio: Double! = nil
    var url: String! = nil
    var type: GiphyHelper.SearchType! = nil
    var adaptedWidth: CGFloat? = nil
    
    init(id: String, aspectRatio: Double, url: String, type: GiphyHelper.SearchType) {
        self.id = id
        self.aspectRatio = aspectRatio
        self.url = url
        self.type = type
    }
    
    func setAdaptedWidth(width: CGFloat) {
        self.adaptedWidth = width
    }
    
    func isGif() -> Bool {
        return type == GiphyHelper.SearchType.Gifs || type == GiphyHelper.SearchType.Recent
    }
}

class GiphyHelper {
    
    public static let kItemsPerPage: Int = 30
    public static let kGifItemHeight: CGFloat = 150
    public static let kStickerItemHeight: CGFloat = 100
    public static let kGiphyApiKey = Bundle.main.object(forInfoDictionaryKey: "GIPHY_API_KEY") as? String ?? ""
    public static let kPrefix = "giphy::"
    
    public enum SearchType: Int {
        case Recent = 0
        case Gifs = 1
        case Stickers = 2
    }
    
    public static var giphyUserId: String {
        get {
            if let giphyUI = UserDefaults.Keys.giphyUserId.get(defaultValue: ""), !giphyUI.isEmpty {
                return giphyUI
            }
            let giphyUI = EncryptionManager.randomString(length: 32)
            UserDefaults.Keys.giphyUserId.set(giphyUI)
            return giphyUI
        }
    }
    
    public static func get200WidthURL(url: String) -> String {
        return url.replacingOccurrences(of: "giphy.gif", with: "200.gif")
    }
    
    public static func getSearchURL(url: String) -> String {
        return url.replacingOccurrences(of: "giphy.gif", with: "200_d.gif")
    }
    
    public static func getJSONObjectFrom(message: String) -> JSON? {
        if message.starts(with: GiphyHelper.kPrefix) {
            if let stringWithoutPrefix = message.replacingOccurrences(of: GiphyHelper.kPrefix, with: "").base64Decoded {
                if let data = stringWithoutPrefix.data(using: .utf8) {
                    if let jsonObject = try? JSON(data: data) {
                        return jsonObject
                    }
                }
            }
        }
        return nil
    }
    
    public static func getAspectRatioFrom(message: String) -> Double {
        if let jsonObject = GiphyHelper.getJSONObjectFrom(message: message) {
            let aspectRatio = jsonObject["aspect_ratio"].doubleValue
            return (aspectRatio > 0) ? aspectRatio : 1.0
        }
        return 1.0
    }
    
    public static func getUrlFrom(message: String, small: Bool = true) -> String? {
        if let jsonObject = GiphyHelper.getJSONObjectFrom(message: message) {
            if let url = jsonObject["url"].string {
                return small ? get200WidthURL(url: url) : url
            }
        }
        return nil
    }
    
    public static func getMessageFrom(message: String) -> String? {
        if let jsonObject = GiphyHelper.getJSONObjectFrom(message: message) {
            if let message = jsonObject["text"].string, !message.isEmpty {
                return message
            } else {
                return ""
            }
        }
        return nil
    }
    
    public static func getGiphyAttributes(message: String) -> (String, String, Double)? {
        if let jsonObject = GiphyHelper.getJSONObjectFrom(message: message) {
            if let url = jsonObject["url"].string, let id = jsonObject["id"].string {
                let ar = jsonObject["aspect_ratio"].doubleValue
                let aspectRatio = (ar > 0) ? ar : 1.0
                return (id, url, aspectRatio)
            }
        }
        return nil
    }
    
    public static func getGiphyDataFrom(url: String, messageId: Int, cache: Bool = true, completion: @escaping (Data?, Int) -> ()) {
        if cache {
            if let data = MediaLoader.getMediaDataFromCachedUrl(url: url) {
                completion(data, messageId)
                return
            }
        }
        
        guard let url = URL(string: url) else {
            completion(nil, messageId)
            return
        }
        
        MediaLoader.loadDataFrom(URL: url, completion: { (data,_) in
            if cache { MediaLoader.storeMediaDataInCache(data: data, url: url.absoluteString) }
            DispatchQueue.main.async {
                completion(data, messageId)
            }
        }, errorCompletion: {
            completion(nil, messageId)
        })
    }
    
    public static func getMessageStringFrom(media: GiphyObject, text: String? = nil) -> String? {
        var json: [String: AnyObject] = [:]
        json["id"] = "\(media.id!)" as AnyObject
        json["aspect_ratio"] = "\(media.aspectRatio!)" as AnyObject
        json["text"] = text as AnyObject
        json["url"] = "\(media.url!)" as AnyObject
                
        if let strJson = JSON(json).rawString(), let base64 = strJson.base64Encoded {
            return "\(GiphyHelper.kPrefix)\(base64)"
        }
        return nil
    }
    
    func loadGiphyDataFrom(message: TransactionMessage, completion: @escaping (Data, Int) -> (), errorCompletion: @escaping (Int) -> ()) {
        let messageId = message.id
        let messageContent = message.messageContent ?? ""
        
        if let jsonObject = GiphyHelper.getJSONObjectFrom(message: messageContent) {
            if let url = jsonObject["url"].string {
                let mobileUrl = GiphyHelper.get200WidthURL(url: url)
                
                GiphyHelper.getGiphyDataFrom(url: mobileUrl, messageId: messageId, completion: { (data, messageId) in
                    DispatchQueue.main.async {
                        if let data = data {
                            completion(data, messageId)
                        } else {
                           errorCompletion(messageId)
                        }
                    }
                })
                return
            }
            errorCompletion(messageId)
        }
    }
    
    func searchGifs(q: String? = nil,
                    page: Int = 0,
                    offset: Int = 0,
                    viewWidth: CGFloat,
                    callback: @escaping GiphySearchCallback) {
        
        API.sharedInstance.searchGiphy(type: .Gifs, q: q, page: page, offset: offset, callback: { objects in
            let filtered = self.setObjectsWidth(objects: objects, viewWidth: viewWidth, itemHeight: GiphyHelper.kGifItemHeight)
            callback(filtered)
        }, errorCallback: {
            callback([])
        })
    }
    
    func searchStickers(q: String? = nil,
                        page: Int = 0,
                        offset: Int = 0,
                        viewWidth: CGFloat,
                        callback: @escaping GiphySearchCallback) {
        
        API.sharedInstance.searchGiphy(type: .Stickers, q: q, page: page, offset: offset, callback: { objects in
            let filtered = self.setObjectsWidth(objects: objects, viewWidth: viewWidth, itemHeight: GiphyHelper.kStickerItemHeight)
            callback(filtered)
        }, errorCallback: {
            callback([])
        })
    }
    
    func getObjectsFrom(messages: [TransactionMessage], viewWidth: CGFloat) -> [GiphyObject] {
        var giphyObjects = [GiphyObject]()
        var urls = [String]()
        
        for message in messages {
            if let messageContent = message.messageContent, let attributes = GiphyHelper.getGiphyAttributes(message: messageContent) {
                if !urls.contains(attributes.1) {
                    urls.append(attributes.1)
                    
                    let giphyObject = GiphyObject(id: attributes.0, aspectRatio: attributes.2, url: attributes.1, type: .Gifs)
                    giphyObjects.append(giphyObject)
                }
            }
        }
        
        let filtered = self.setObjectsWidth(objects: giphyObjects, viewWidth: viewWidth, itemHeight: GiphyHelper.kGifItemHeight)
        return filtered
    }
    
    func setObjectsWidth(objects: [GiphyObject], viewWidth: CGFloat, itemHeight: CGFloat) -> [GiphyObject] {
        var totalWidth: CGFloat = 0
        var firstIndex = 0
        
        for i in 0..<objects.count {
            let object = objects[i]
            let width = itemHeight * CGFloat(object.aspectRatio)
            totalWidth += width
            
            if totalWidth > viewWidth {
                for x in firstIndex...i {
                    let o = objects[x]
                    let width = itemHeight * CGFloat(o.aspectRatio)
                    let adaptedAspectRatio = width / totalWidth
                    
                    let adaptedWidth = floor(viewWidth * adaptedAspectRatio)
                    o.setAdaptedWidth(width: adaptedWidth)
                }
                
                firstIndex = i + 1
                totalWidth = 0
            }
        }
        if objects.count > 0 && firstIndex > 0 {
            return Array<GiphyObject>(objects[0...firstIndex-1])
        }
        return objects
    }
}
