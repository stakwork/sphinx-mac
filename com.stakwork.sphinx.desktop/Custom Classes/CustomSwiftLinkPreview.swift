//
//  CustomSwiftLinkPreview.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 29/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import SwiftLinkPreview

class CustomSwiftLinkPreview {
    
    class var sharedInstance : SwiftLinkPreview {
        struct Static {
            static let instance = SwiftLinkPreview(session: CustomSwiftLinkPreview.getURLSession(), cache: InMemoryCache())
        }
        return Static.instance
    }
    
    static func getURLSession() -> URLSession {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 10
        sessionConfiguration.timeoutIntervalForResource = 3
        
        return URLSession(configuration: sessionConfiguration)
    }
}
