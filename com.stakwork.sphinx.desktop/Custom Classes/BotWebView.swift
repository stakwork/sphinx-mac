//
//  BotWebView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 17/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import WebKit

class BotWebView : WKWebView {
    var contentString: String? = ""
    var messageId : Int? = nil
    
    override func scrollWheel(with event: NSEvent) {
        self.nextResponder?.scrollWheel(with: event)
    }
    
    func loadHTMLString(
        _ string: String,
        messageId: Int,
        baseURL: URL?
    ) -> WKNavigation? {
        self.messageId = messageId
        self.contentString = string
        
        return super.loadHTMLString(string, baseURL: baseURL)
    }
    
    override func mouseDown(with event: NSEvent) {
        // Define a regular expression pattern to match the src attribute within an <img> tag
        let srcPattern = #"src="([^"]+)""#

        // Create a regular expression object
        if let regex = try? NSRegularExpression(pattern: srcPattern, options: .caseInsensitive), let contentString = contentString {
            // Find matches in the contentString
            let matches = regex.matches(in: contentString, options: [], range: NSRange(location: 0, length: contentString.utf16.count))

            // Loop through the matches and extract the src attribute
            for match in matches {
                if let srcRange = Range(match.range(at: 1), in: contentString) {
                    let srcAttribute = contentString[srcRange]

                    if let messageId = messageId, let url = URL(string: String(srcAttribute)){
                        NotificationCenter.default.post(
                            name: .webViewImageClicked,
                            object: nil,
                            userInfo: [
                                "image_url": url,
                                "message_id": messageId
                            ]
                        )
                    }
                }
            }
        }
        super.mouseDown(with: event)
    }
}
