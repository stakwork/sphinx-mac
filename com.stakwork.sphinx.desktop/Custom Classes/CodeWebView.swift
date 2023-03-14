//
//  CodeWebView.swift
//  Sphinx
//
//  Created by James Carucci on 3/13/23.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation
import WebKit
import Down

class CodeWebView : WKWebView {
    var contentString: String? = """
        ```
        const myVar = "woohoo!";
        func test(){
            return foo;
        }
        """
    var codeString : String = ""
    let codeViewTopBottomMargin = 100.0
    var height : CGFloat = 100.0
    
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
        self.codeString = code
        //self.contentString = html
        self.getCodeViewHeight(completion: { calculatedHeight in
            self.height = calculatedHeight
        })
        return super.loadHTMLString(html, baseURL: baseURL)
    }
    
    func addDownView(){
        if let string = contentString,
            let downView = try? DownView(frame: self.bounds,markdownString: string){
            self.addSubview(downView)
            self.bringSubviewToFront(downView)
        }
    }
    
    func getCodeViewHeight(completion:@escaping (CGFloat) -> ()){
        self.evaluateJavaScript("document.documentElement.scrollHeight", completionHandler: { (height, error) in
            if let valid_height = height as? CGFloat{
                completion(valid_height + self.codeViewTopBottomMargin)
            }
            else{
                completion(100.0 + self.codeViewTopBottomMargin)
            }
        })
    }
}
