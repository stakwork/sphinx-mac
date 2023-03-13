//
//  CodeWebView.swift
//  Sphinx
//
//  Created by James Carucci on 3/13/23.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation
import WebKit

class CodeWebView : WKWebView {
    var contentString: String? = ""
    
    override func scrollWheel(with event: NSEvent) {
        self.nextResponder?.scrollWheel(with: event)
    }
    
    override func loadHTMLString(_ code: String, baseURL: URL?) -> WKNavigation? {
        let html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <meta http-equiv="X-UA-Compatible" content="ie=edge">
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.15.10/styles/monokai.min.css">
            <link href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/8.9.1/styles/default.min.css" rel="stylesheet" />
              <link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" rel="stylesheet" />
            <title>Document</title>
        </head>
        <body>
            <div class="container">
              <pre><code>
              \(code)
              </code></pre>
              </div>
              <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/8.9.1/highlight.min.js"></script>
              <script>hljs.initHighlightingOnLoad();</script>
        </body>
        </html>
        """
        self.contentString = html
        return super.loadHTMLString(html, baseURL: baseURL)
    }
}
