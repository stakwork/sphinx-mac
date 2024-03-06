//
//  URL.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation

extension URL {
    
    var isPDF: Bool {
        get {
            return self.absoluteString.contains(".pdf")
        }
    }
    
    var isVideo: Bool {
        get {
            return self.absoluteString.contains(".mov") || self.absoluteString.contains(".mp4") || self.absoluteString.contains(".m4v") || self.absoluteString.contains(".3gp")
        }
    }
    
    func getLinkAction() -> String? {
        if let query = self.query {
            let components = query.components(separatedBy: "&")
            
            for component in components {
                if component.contains("action") {
                    let elements = component.components(separatedBy: "=")
                    if elements.count > 1 {
                        return elements[1]
                    }
                }
            }
        }
        return nil
    }
    
    func getCallLink() -> String? {
        let link = self.absoluteString
        let components = link.components(separatedBy: "link=")
        
        if components.count > 1 {
            return components[1]
        }
        
        return link
    }
    
    var domain: String? {
        get {
            if let hostName = self.host  {
                let host = hostName.replacingOccurrences(of: "http://", with: "")
                                   .replacingOccurrences(of: "https://", with: "")
                                   .replacingOccurrences(of: "www.", with: "")
                
                let components = host.components(separatedBy: ".")
                if components.count > 0 {
                    return String(components[0])
                }
            }
            return self.host
        }
    }
    
    var pathWithParams: String {
        let path = self.path
        if let query = self.query {
            return "\(path)?\(query)"
        }
        return path
    }
}
