//
//  API.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 11/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

typealias ContactsResultsCallback = (([JSON], [JSON], [JSON], [JSON]) -> ())
typealias SphinxMessagesResultsCallback = ((JSON) -> ())
typealias SphinxHistoryResultsCallback = (([JSON]) -> ())
typealias DirectPaymentResultsCallback = ((JSON?) -> ())
typealias EmptyCallback = (() -> ())
typealias BalanceCallback = ((Int) -> ())
typealias BalancesCallback = ((Int, Int) -> ())
typealias CreateInvoiceCallback = ((JSON?, String?) -> ())
typealias PayInvoiceCallback = ((JSON) -> ())
typealias MessageObjectCallback = ((JSON) -> ())
typealias GetMessagesCallback = (([JSON], [JSON], [JSON]) -> ())
typealias GetMessagesPaginatedCallback = ((Int, [JSON]) -> ())
typealias GetAllMessagesCallback = (([JSON]) -> ())
typealias DeleteMessageCallback = ((Bool, JSON) -> ())
typealias CreateInviteCallback = ((JSON) -> ())
typealias UpdateUserCallback = ((JSON) -> ())
typealias UploadProgressCallback = ((Int) -> ())
typealias UploadCallback = ((Bool, String?) -> ())
typealias SuccessCallback = ((Bool) -> ())
typealias CreateSubscriptionCallback = ((JSON) -> ())
typealias GetSubscriptionsCallback = (([JSON]) -> ())
typealias MuteChatCallback = ((JSON) -> ())
typealias NotificationLevelCallback = ((JSON) -> ())
typealias CreateGroupCallback = ((JSON) -> ())
typealias LogsCallback = ((String) -> ())
typealias TemplatesCallback = (([ImageTemplate]) -> ())
typealias GetTransactionsCallback = (([PaymentTransaction]) -> ())
typealias TransportKeyCallback = ((String) -> ())
typealias HMACKeyCallback = ((String) -> ())
typealias GetPersonDataCallback = ((JSON) -> ())
typealias PinMessageCallback = ((String) -> ())
typealias ErrorCallback = ((String) -> ())

//HUB calls
typealias SignupWithCodeCallback = ((JSON, String, String) -> ())
typealias LowestPriceCallback = ((Double) -> ())
typealias PayInviteCallback = ((JSON) -> ())

//Attachments
typealias askAuthenticationCallback = ((String?, String?) -> ())
typealias signChallengeCallback = ((String?) -> ())
typealias verifyAuthenticationCallback = ((String?) -> ())
typealias UploadAttachmentCallback = ((Bool, NSDictionary?) -> ())
typealias GiphySearchCallback = (([GiphyObject]) -> ())
typealias GiphySearchErrorCallback = (() -> ())
typealias MediaInfoCallback = ((Int, String?, Int?) -> ())

//Feed
typealias SyncActionsCallback = ((Bool) -> ())
typealias ContentFeedCallback = ((JSON) -> ())
typealias AllContentFeedStatusCallback = (([ContentFeedStatus]) -> ())
typealias ContentFeedStatusCallback = ((ContentFeedStatus) -> ())

//Crypter
typealias HardwarePublicKeyCallback = ((String) -> ())
typealias HardwareSeedCallback = ((Bool) -> ())

//TribeMembers
typealias ChatContactsCallback = (([JSON]) -> ())

class API {
    
    class var sharedInstance : API {
        struct Static {
            static let instance = API()
        }
        return Static.instance
    }
    
    let interceptor = SphinxInterceptor()
    
    var onionConnector = SphinxOnionConnector.sharedInstance
    
    var uploadRequest: UploadRequest?
    
    var giphyRequest: DataRequest?
    var giphyRequestType: GiphyHelper.SearchType = GiphyHelper.SearchType.Gifs
    
    let messageBubbleHelper = NewMessageBubbleHelper()
    
    enum CancellableRequestType {
        case contacts
        case messages
    }
    
    var lastSeenMessagesDate: Date? {
        get {
            return UserDefaults.Keys.lastSeenMessagesDate.get(defaultValue: nil)
        }
        set {
            UserDefaults.Keys.lastSeenMessagesDate.set(newValue)
        }
    }
    
    public static let kTribesServerBaseURL = "https://tribes.sphinx.chat"
    
    public static let kTestV2TribesServer = "http://34.229.52.200:8801"
    
    public static var kAttachmentsServerUrl : String {
        get {
            if let fileServerURL = UserDefaults.Keys.fileServerURL.get(defaultValue: ""), fileServerURL != "" {
                return fileServerURL
            }
            return "https://memes.sphinx.chat"
        }
        set {
            UserDefaults.Keys.fileServerURL.set(newValue)
        }
    }
    
    public static var kHUBServerUrl : String {
        get {
            if let inviteServerURL = UserDefaults.Keys.inviteServerURL.get(defaultValue: ""), inviteServerURL != "" {
                return inviteServerURL
            }
            return "https://hub.sphinx.chat"
        }
        set {
            UserDefaults.Keys.inviteServerURL.set(newValue)
        }
    }
    
    public static var kVideoCallServer : String {
        get {
            if let meetingServerURL = UserDefaults.Keys.meetingServerURL.get(defaultValue: ""), meetingServerURL != "" {
                return meetingServerURL
            }
            return "https://jitsi.sphinx.chat"
        }
        set {
            UserDefaults.Keys.meetingServerURL.set(newValue)
        }
    }
    
    class func getUrl(route: String) -> String {
        if let url = URL(string: route), let _ = url.scheme {
            return url.absoluteString
        }
        return "https://\(route)"
        
    }
    
    class func getWebsocketUrl(route: String) -> String {
        if route.contains("://") {
            return getUrl(route: route)
                .replacingOccurrences(of: "https://", with: "wss://")
                .replacingOccurrences(of: "http://", with: "ws://")
        }
        return "wss://\(route)"
    }
    
    func session() -> Alamofire.Session? {
        if !onionConnector.usingTor() {
            return Alamofire.Session.default
        }
        
        switch (onionConnector.onionManager.state) {
        case .connected:
            guard let torSession = onionConnector.torSession else {
                let appDelegate = NSApplication.shared.delegate as! AppDelegate
                onionConnector.startTor(delegate: appDelegate)
                return nil
            }
            return torSession
        default:
            return nil
        }
    }
    
    func getURLRequest(
        route: String,
        params: NSDictionary? = nil,
        method: String,
        additionalHeaders: [String: String] = [:]
    ) -> URLRequest? {
        let ip = UserData.sharedInstance.getNodeIP()
        
        if ip.isEmpty {
            messageBubbleHelper.showGenericMessageView(text: "contact.support".localized, delay: 7)
            return nil
        }
        
        let url = API.getUrl(route: "\(ip)\(route)")
        return createAuthenticatedRequest(
            url,
            params: params,
            method: method,
            additionalHeaders: additionalHeaders
        )
    }
    
    func getUnauthenticatedURLRequest(
        route: String,
        params: NSDictionary? = nil,
        method: String
    ) -> URLRequest? {
        let ip = UserData.sharedInstance.getNodeIP()
        
        if ip.isEmpty {
            messageBubbleHelper.showGenericMessageView(text: "contact.support".localized, delay: 7)
            return nil
        }
        
        let url = API.getUrl(route: "\(ip)\(route)")
        
        return createRequest(
            url,
            params: params,
            method: method
        )
    }
    
    var errorCounter = 0
    
    let successStatusCode = 200
    let unauthorizedStatusCode = 401
    let notFoundStatusCode = 404
    let badGatewayStatusCode = 502
    let connectionLostError = "The network connection was lost"
    
    public enum ConnectionStatus: Int {
        case Connecting
        case Connected
        case NotConnected
        case Unauthorize
        case NoNetwork
    }
    
    var connectionStatus = ConnectionStatus.Connecting
    
    func sphinxRequest(
        _ urlRequest: URLRequest,
        completionHandler: @escaping (AFDataResponse<Any>) -> Void
    ) {
        unauthorizedHandledRequest(urlRequest, completionHandler: completionHandler)
    }
    
    func cancellableRequest(
        _ urlRequest: URLRequest,
        type: CancellableRequestType,
        completionHandler: @escaping (AFDataResponse<Any>) -> Void
    ) {
        unauthorizedHandledRequest(urlRequest) { (response) in
            self.postConnectionStatusChange()
            
            completionHandler(response)
        }
    }
    
    func unauthorizedHandledRequest(
        _ urlRequest: URLRequest,
        completionHandler: @escaping (AFDataResponse<Any>) -> Void
    ) {
        
        if onionConnector.usingTor() && !onionConnector.isReady() {
            onionConnector.startIfNeeded()
            return
        }
        
        var mutableUrlRequest = urlRequest
        
        for (key, value) in UserData.sharedInstance.getAuthenticationHeader() {
            mutableUrlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        session()?.request(
            mutableUrlRequest,
            interceptor: interceptor
        ).responseJSON { (response) in
            
            let statusCode = (response.response?.statusCode ?? -1)
            
            switch statusCode {
            case self.successStatusCode:
                self.connectionStatus = .Connected
            case self.unauthorizedStatusCode:
//                self.getRelaykeys()
                
                self.connectionStatus = .Unauthorize
            default:
                if response.response == nil ||
                    statusCode == self.notFoundStatusCode  ||
                    statusCode == self.badGatewayStatusCode {
                    
                    self.connectionStatus = response.response == nil ?
                        self.connectionStatus :
                        .NotConnected

                    if self.errorCounter < 5 {
                        self.errorCounter = self.errorCounter + 1
                    } else if response.response != nil {
//                        self.getIPFromHUB()
                        return
                    }
                    completionHandler(response)
                    return
                } else {
                    self.connectionStatus = .NotConnected
                }
            }

            self.errorCounter = 0

            if let _ = response.response {
                completionHandler(response)
            }
        }
    }
    
    func getRelaykeys() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.getRelayKeys()
        }
    }
    
//    func getHMACKeyAndRetry(
//        _ urlRequest: URLRequestConvertible,
//        completionHandler: @escaping (AFDataResponse<Any>) -> Void
//    ) -> Bool {
//        if UserData.sharedInstance.getHmacKey() == nil {
//            UserData.sharedInstance.getAndSaveHMACKey(completion: {
//                let _ = self.unauthorizedHandledRequest(
//                    urlRequest,
//                    completionHandler: completionHandler
//                )
//            })
//            return true
//        }
//        return false
//    }
    
    func getIPFromHUB() {
        self.errorCounter = 0
        
        guard let ownerPubKey = UserData.sharedInstance.getUserPubKey() else {
            return
        }
        
        let url = "\(API.kHUBServerUrl)/api/v1/nodes/\(ownerPubKey)"
        guard let request = createRequest(url, params: nil, method: "GET") else {
            return
        }
        
        AF.request(request).responseJSON { (response) in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let status = json["status"] as? String, status == "ok" {
                        if let object = json["object"] as? NSDictionary {
                            if let ip = object["node_ip"] as? String, !ip.isEmpty {
                                UserData.sharedInstance.save(ip: ip)
                                SphinxSocketManager.sharedInstance.reconnectSocketToNewIP()
                                self.reloadDashboard()
                                return
                            }
                        }
                    }
                }
                self.retryGettingIPFromHUB()
            case .failure(_):
                self.retryGettingIPFromHUB()
            }
        }
    }
    
    func retryGettingIPFromHUB() {
//        DelayPerformedHelper.performAfterDelay(seconds: 5, completion: {
//            self.getIPFromHUB()
//        })
    }
    
    func networksConnectionLost() {
        DispatchQueue.main.async {
            self.connectionStatus = .NoNetwork
            self.messageBubbleHelper.showGenericMessageView(text: "network.connection.lost".localized, delay: 3)
            self.postConnectionStatusChange()
        }
    }
    
    func postConnectionStatusChange() {
        NotificationCenter.default.post(name: .onConnectionStatusChanged, object: nil)
    }
    
    func reloadDashboard() {
        NotificationCenter.default.post(name: .shouldUpdateDashboard, object: nil)
    }
    
    func createRequest(
        _ url:String,
        params:NSDictionary?,
        method:String,
        contentType: String = "application/json",
        token: String? = nil
    ) -> URLRequest? {
        
        if !ConnectivityHelper.isConnectedToInternet {
            networksConnectionLost()
            return nil
        }
        
        if onionConnector.usingTor() && !onionConnector.isReady() {
            return nil
        }
        
        if let nsURL = URL(string: url) {
            var request = URLRequest(url: nsURL)
            request.httpMethod = method
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            
            if let token = token {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            if let p = params {
                do {
                    try request.httpBody = JSONSerialization.data(withJSONObject: p, options: [])
                } catch let error as NSError {
                    print("Error: " + error.localizedDescription)
                }
            }
            
            return request
        } else {
            return nil
        }
    }
    
    func createAuthenticatedRequest(
        _ url:String,
        params:NSDictionary?,
        method:String,
        additionalHeaders: [String: String] = [:]
    ) -> URLRequest? {
        
        if !ConnectivityHelper.isConnectedToInternet {
            networksConnectionLost()
            return nil
        }
        
        if onionConnector.usingTor() && !onionConnector.isReady() {
            return nil
        }
        
        if let nsURL = NSURL(string: url) {
            var request = URLRequest(url: nsURL as URL)
            request.httpMethod = method
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

            for (key, value) in additionalHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            var bodyData: Data? = nil
            
            if let p = params {
                do {
                    try bodyData = JSONSerialization.data(withJSONObject: p, options: [])
                } catch let error as NSError {
                    print("Error: " + error.localizedDescription)
                }
            }
            
            if let bodyData = bodyData {
                request.httpBody = bodyData
            }

            for (key, value) in UserData.sharedInstance.getHMACHeader(
                url: nsURL as URL,
                method: method,
                bodyData: bodyData
            ) {
                request.setValue(value, forHTTPHeaderField: key)
            }
            return request
        } else {
            return nil
        }
    }
}

class SphinxInterceptor : RequestInterceptor {
    public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        completion(.success(urlRequest))
    }

    public func retry(_ request: Request,
                      for session: Session,
                      dueTo error: Error,
                      completion: @escaping (RetryResult) -> Void) {
        completion(.doNotRetry)
    }
}
