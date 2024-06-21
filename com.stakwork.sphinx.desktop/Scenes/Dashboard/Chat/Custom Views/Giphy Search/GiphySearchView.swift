//
//  GiphySearch.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 08/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol GiphySearchViewDelegate: AnyObject {
    func didSelectGiphy(object: GiphyObject, data: Data)
}

class GiphySearchView: NSView, LoadableNib {
    
    weak var delegate: GiphySearchViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var searchFieldContainer: NSBox!
    @IBOutlet weak var searchField: NSTextField!
    @IBOutlet weak var clearFieldButton: CustomButton!
    @IBOutlet weak var closeViewButton: CustomButton!
    
    @IBOutlet weak var gifsButton: NSButton!
    @IBOutlet weak var stickersButton: NSButton!
    @IBOutlet weak var recentButton: NSButton!
    
    @IBOutlet weak var gifsScrollView: NSScrollView!
    @IBOutlet weak var stickersScrollView: NSScrollView!
    @IBOutlet weak var recentScrollView: NSScrollView!
    
    @IBOutlet weak var gifsCollectionView: NSCollectionView!
    @IBOutlet weak var stickersCollectionView: NSCollectionView!
    @IBOutlet weak var recentCollectionView: NSCollectionView!
    
    @IBOutlet weak var loadingWheelContainer: NSBox!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    
    let kGiphySearchHeight: CGFloat = 350
    let kGiphySearchScrollBarWidth: CGFloat = 10
    
    let giphyHelper = GiphyHelper()
    
    var gifsDataSource: GiphySearchDataSource!
    var stickersDataSource: GiphySearchDataSource!
    var recentDataSource: GiphySearchDataSource!
    
    var currentMode = GiphyHelper.SearchType.Gifs
    var searchTimer : Timer? = nil
    
    var loading = false {
        didSet {
            gifsScrollView.isHidden = loading
            stickersScrollView.isHidden = loading
            recentScrollView.isHidden = loading
            
            loadingWheelContainer.superview?.bringSubviewToFront(loadingWheelContainer)
            loadingWheelContainer.isHidden = !loading
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.Sphinx.Text, controls: [])
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
        setup()
    }
    
    func setup() {
        closeViewButton.cursor = .pointingHand
        clearFieldButton.cursor = .pointingHand
        
        stickersScrollView.alphaValue = 0.0
        recentScrollView.alphaValue = 0.0
        
        searchFieldContainer.wantsLayer = true
        searchFieldContainer.layer?.cornerRadius = searchFieldContainer.frame.size.height / 2
        searchFieldContainer.layer?.borderWidth = 1
        searchFieldContainer.layer?.borderColor = NSColor.Sphinx.LightDivider.cgColor
    }
    
    func getViewHeight() -> CGFloat {
        return isHidden ? 0 : kGiphySearchHeight
    }
    
    func loadGiphySearch(delegate: GiphySearchViewDelegate) {
        self.delegate = delegate
        
        self.isHidden = false

        setupSearchField()
        loadData()
    }
    
    @objc func loadData() {
        loading = true
        
        let recentGiphyMessages = TransactionMessage.getRecentGiphyMessages()
        let recentGiphyObjects = giphyHelper.getObjectsFrom(messages: recentGiphyMessages, viewWidth: frame.width - kGiphySearchScrollBarWidth)
        loadWithRecentGifs(objects: recentGiphyObjects)
        
        let q = (searchField?.stringValue ?? "")
        performSearchOf(type: .Gifs, q: q)
        performSearchOf(type: .Stickers, q: q)
    }
    
    func performSearchOf(type: GiphyHelper.SearchType,
                         q: String,
                         page: Int = 0,
                         loadingMore: Bool = false) {
        
        let viewWidth = frame.width - kGiphySearchScrollBarWidth
        
        if type == .Gifs {
            let offset = loadingMore ? gifsCollectionView.numberOfItems(inSection: 0) + 1 : 0
            giphyHelper.searchGifs(q: q, page: page, offset: offset, viewWidth: viewWidth, callback: { objects in
                self.loadWithGifs(objects: objects, loadingMore: loadingMore)
            })
        } else if type == .Stickers {
            let offset = loadingMore ? stickersCollectionView.numberOfItems(inSection: 0) + 1 : 0
            giphyHelper.searchStickers(q: q, page: page, offset: offset, viewWidth: viewWidth, callback: { objects in
                self.loadWithStickers(objects: objects, loadingMore: loadingMore)
            })
        }
    }
    
    func loadWithRecentGifs(objects: [GiphyObject]) {
        if recentDataSource == nil {
            recentDataSource = GiphySearchDataSource(collectionView: recentCollectionView, delegate: self, searchType: .Recent)
        }
        recentDataSource.setDataAndReload(objects: objects)
    }
    
    func loadWithGifs(objects: [GiphyObject], loadingMore: Bool = false) {
        loading = false
        
        if loadingMore {
            gifsDataSource.insertObjects(objects: objects)
            return
        }
        
        if gifsDataSource == nil {
            gifsDataSource = GiphySearchDataSource(collectionView: gifsCollectionView, delegate: self, searchType: .Gifs)
        }
        gifsDataSource.setDataAndReload(objects: objects)
    }
    
    func loadWithStickers(objects: [GiphyObject], loadingMore: Bool = false) {
        if loadingMore {
            stickersDataSource.insertObjects(objects: objects)
            return
        }
        
        if stickersDataSource == nil {
            stickersDataSource = GiphySearchDataSource(collectionView: stickersCollectionView, delegate: self, searchType: .Stickers)
        }
        stickersDataSource.setDataAndReload(objects: objects)
    }
    
    func setupSearchField() {
        clearFieldButton.isHidden = true
        searchField.stringValue = ""
        searchField.delegate = self
        window?.makeFirstResponder(searchField)
    }
    
    @IBAction func modeButtonClicked(_ sender: NSButton) {
        let isRecent = sender.tag == GiphyHelper.SearchType.Recent.rawValue
        let isGif = sender.tag == GiphyHelper.SearchType.Gifs.rawValue
        let isSticker = sender.tag == GiphyHelper.SearchType.Stickers.rawValue
        
        recentScrollView.alphaValue = isRecent ? 1.0 : 0.0
        gifsScrollView.alphaValue = isGif ? 1.0 : 0.0
        stickersScrollView.alphaValue = isSticker ? 1.0 : 0.0
        
        if #available(OSX 10.14, *) {
            recentButton.contentTintColor = isRecent ? NSColor.Sphinx.Text : NSColor.Sphinx.SecondaryText
            gifsButton.contentTintColor = isGif ? NSColor.Sphinx.Text : NSColor.Sphinx.SecondaryText
            stickersButton.contentTintColor = isSticker ? NSColor.Sphinx.Text : NSColor.Sphinx.SecondaryText
        }
        
        if isGif { gifsScrollView.superview?.bringSubviewToFront(gifsScrollView) }
        if isSticker { stickersScrollView.superview?.bringSubviewToFront(stickersScrollView) }
        if isRecent { recentScrollView.superview?.bringSubviewToFront(recentScrollView) }
    }
    
    @IBAction func clearFieldButtonClicked(_ sender: Any) {
        if searchField.stringValue != "" {
            searchTimer?.invalidate()
            searchField.stringValue = ""
            loadData()
        }
    }
    
    @IBAction func closeViewButtonClicked(_ sender: Any) {
        gifsDataSource?.setDataAndReload(objects: [])
        stickersDataSource?.setDataAndReload(objects: [])
        recentDataSource?.setDataAndReload(objects: [])
        
        isHidden = true
    }
}

extension GiphySearchView : NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        searchField?.resignFirstResponder()
    }
    
    func controlTextDidChange(_ obj: Notification) {
        let currentString = (searchField?.stringValue ?? "")
        clearFieldButton.isHidden = currentString.isEmpty
        loading = true
        
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(loadData), userInfo: nil, repeats: false)
        
        switchToGifsSearchIfInRecent()
    }
    
    func switchToGifsSearchIfInRecent() {
        let isRecent = recentScrollView.alphaValue == 1.0
        if isRecent {
            modeButtonClicked(gifsButton)
        }
    }
}

extension GiphySearchView : GiphySearchDataSourceDelegate {
    func didSelectGiphy(object: GiphyObject, data: Data) {
        delegate?.didSelectGiphy(object: object, data: data)
        closeViewButtonClicked(closeViewButton!)
    }
    
    func shouldAddObjects(type: GiphyHelper.SearchType, page: Int) {
        let q = (searchField?.stringValue ?? "")
        performSearchOf(type: type, q: q, page: page, loadingMore: true)
    }
}
