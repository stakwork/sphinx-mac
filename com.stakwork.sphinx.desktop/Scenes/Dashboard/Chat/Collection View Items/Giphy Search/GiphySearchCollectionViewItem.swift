//
//  GiphySearchCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 09/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class GiphySearchCollectionViewItem: NSCollectionViewItem {
    
    @IBOutlet weak var gifView: NSView!
    
    var gifData: Data? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.Sphinx.GiphyBack.cgColor
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        self.gifData = nil
        self.gifView.layer?.removeAllAnimations()
    }
    
    func loadObject(_ object: GiphyObject) {
        gifView.wantsLayer = true
        gifView.layer?.removeAllAnimations()
        gifView.layer?.backgroundColor = NSColor.random().cgColor
        
        let mobileUrl = GiphyHelper.getSearchURL(url: object.url)
        GiphyHelper.getGiphyDataFrom(url: mobileUrl, messageId: 0, cache: false, completion: { (data, messageId) in
            if let data = data {
                self.gifData = data
                self.showGif(data: data)
            }
        })
    }
    
    func showGif(data: Data) {
        if let animation = data.createGIFAnimation() {
            gifView.layer?.backgroundColor = NSColor.Sphinx.HeaderBG.cgColor
            gifView.layer?.contents = nil
            gifView.layer?.contentsGravity = .resizeAspectFill
            gifView.layer?.add(animation, forKey: "contents")
        }
    }
    
}
