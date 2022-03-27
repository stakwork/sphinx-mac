//
//  APIGiphyExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 08/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

extension API {
    
    func giphyCancellableRequest(_ urlRequest: URLRequestConvertible, type: GiphyHelper.SearchType, completionHandler: @escaping (AFDataResponse<Any>) -> Void) {
        if let giphyRequest = giphyRequest, giphyRequestType == type {
            giphyRequest.cancel()
        }
        let request = session()?.request(urlRequest).responseJSON { (response) in
            if let _ = response.response {
                completionHandler(response)
            }
        }
        giphyRequestType = type
        giphyRequest = request
    }
    
    func searchGiphy(type: GiphyHelper.SearchType,
                     q: String? = nil,
                     page: Int = 0,
                     offset: Int = 0,
                     callback: @escaping GiphySearchCallback,
                     errorCallback: @escaping GiphySearchErrorCallback) {
        
        let params = getParams(q: q, page: page, offset: offset)
        let endpoint = getGiphyEndpoint(type: type, q: q)
        let url = "https://api.giphy.com/v1/\(endpoint)?\(params)"
        
        guard let request = createRequest(url.percentEscaped ?? url, params: nil, method: "GET") else {
            return
        }
        
        giphyCancellableRequest(request, type: type) { response in
            switch response.result {
            case .success(let data):
                if let data = data as? NSDictionary {
                    let jsonResponse = JSON(data)
                    
                    guard let meta = jsonResponse["meta"].dictionary, let status = meta["status"]?.intValue, status == 200 else {
                        errorCallback()
                        return
                    }
                    
                    let resultsData = jsonResponse["data"]
                    let resultsArray = JSON(resultsData).arrayValue
                    let objectsArray = self.processGiphyResponse(results: resultsArray, type: type)
                    callback(objectsArray)
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func getParams(q: String? = nil, page: Int = 0, offset: Int = 0) -> String {        
        var params = "api_key=\(GiphyHelper.kGiphyApiKey)&limit=\(GiphyHelper.kItemsPerPage)&offset=\(offset)&random_id=\(GiphyHelper.giphyUserId)"
        
        if let q = q, !q.isEmpty {
            params = "\(params)&q=\(q)"
        }
        
        return params
    }
    
    func getGiphyEndpoint(type: GiphyHelper.SearchType, q: String? = nil) -> String {
        var content = ""
        let isSearching = q != nil && !q!.isEmpty
        let endpoint = isSearching ? "search" : "trending"
        
        switch(type) {
        case GiphyHelper.SearchType.Gifs:
            content = "gifs"
        case GiphyHelper.SearchType.Stickers:
            content = "stickers"
        default:
            break
        }
        
        return "\(content)/\(endpoint)"
    }
    
    func processGiphyResponse(results: [JSON], type: GiphyHelper.SearchType) -> [GiphyObject] {
        var giphyObjects = [GiphyObject]()
        
        for r in results {
            let id = r["id"].stringValue
            
            if let images = r["images"].dictionary, let original = images["original"]?.dictionary {
                let width = original["width"]?.intValue ?? 200
                let height = original["height"]?.intValue ?? 200
                let aspectRatio = Double(width) / Double(height)
                
                if let url = original["url"]?.stringValue {
                    let giphyObject = GiphyObject(id: id, aspectRatio: aspectRatio, url: url, type: type)
                    giphyObjects.append(giphyObject)
                }
            }
        }
        
        return giphyObjects
    }
}
