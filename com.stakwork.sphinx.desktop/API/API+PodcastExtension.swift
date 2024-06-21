//
//  APIPodcastExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import ObjectMapper

extension API {
    typealias PodcastFeedCallback = ((JSON) -> ())
    typealias PodcastInfoCallback = ((JSON) -> ())
    
    func getPodcastFeed(url: String, callback: @escaping PodcastFeedCallback, errorCallback: @escaping EmptyCallback){
        guard let request = createRequest(url, params: nil, method: "GET") else {
            errorCallback()
            return
        }
        
        AF.request(request).responseJSON { (response) in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    callback(JSON(json))
                    return
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func getContentFeed(
        url: String,
        callback: @escaping ContentFeedCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        guard let request = createRequest(url, params: nil, method: "GET") else {
            errorCallback()
            return
        }
        
        AF.request(request).responseJSON { response in
            if let data = response.data {
                callback(JSON(data))
            } else {
                errorCallback()
            }
        }
    }
    
    func getPodcastInfo(podcastId: Int, callback: @escaping PodcastInfoCallback, errorCallback: @escaping EmptyCallback) {
        let url = API.getUrl(route: "https://tribes.sphinx.chat/podcast?id=\(podcastId)")
        let tribeRequest : URLRequest? = createRequest(url, params: nil, method: "GET")
        
        guard let request = tribeRequest else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    callback(JSON(json))
                } else {
                    errorCallback()
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func streamSats(params: [String: AnyObject], callback: @escaping EmptyCallback, errorCallback:@escaping EmptyCallback) {
        guard let request = getURLRequest(route: "/stream", params: params as NSDictionary?, method: "POST") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success {
                        callback()
                        return
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func updateMetaData(chatId: Int, params: [String: AnyObject], callback: @escaping EmptyCallback, errorCallback:@escaping EmptyCallback) {
        guard let request = getURLRequest(route: "/chats/\(chatId)", params: params as NSDictionary?, method: "PUT") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success {
                        callback()
                        return
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func getAllContentFeedStatuses(
        callback: @escaping AllContentFeedStatusCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        guard let request = getURLRequest(route: "/content_feed_status", params: nil, method: "GET") else {
            errorCallback()
            return
        }

        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success,
                       let mapped_content_status = Mapper<ContentFeedStatus>().mapArray(JSONObject: json["response"]) {
                        
                        callback(mapped_content_status)
                        return
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func getContentFeedStatusFor(
        feedId: String,
        callback: @escaping ContentFeedStatusCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        guard let request = getURLRequest(route: "/content_feed_status/\(feedId)", params: nil, method: "GET") else {
            errorCallback()
            return
        }

        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success,
                       let mapped_content_status = Mapper<ContentFeedStatus>().map(JSONObject: json["response"]) {
                        
                        callback(mapped_content_status)
                        return
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func saveContentFeedStatusesToRemote(
        params: [[String: Any]],
        callback: @escaping EmptyCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        var requestParams : [String:Any] = [String:Any]()
        requestParams["contents"] = params
        
        guard let request = getURLRequest(route: "/content_feed_status", params: requestParams as NSDictionary?, method: "POST") else {
            errorCallback()
            return
        }
        
        let json = JSON(requestParams)
        print(json)
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success {
                        callback()
                        return
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func saveContentFeedStatusToRemote(
        params: [String: Any],
        feedId: String,
        callback: @escaping EmptyCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        var requestParams: [String: Any] = [String: Any]()
        requestParams["content"] = params
        
        guard let request = getURLRequest(route: "/content_feed_status/\(feedId)", params: requestParams as NSDictionary?, method: "PUT") else {
            errorCallback()
            return
        }
        
        let json = JSON(requestParams)
        print(json)
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success {
                        callback()
                        return
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
}
