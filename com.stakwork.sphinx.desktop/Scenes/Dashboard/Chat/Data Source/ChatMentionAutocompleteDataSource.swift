//
//  ChatMentionAutocompleteDataSource.swift
//  Sphinx
//
//  Created by James Carucci on 12/8/22.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Foundation
import AppKit

protocol ChatMentionAutocompleteDelegate: AnyObject {
    func processAutocomplete(text:String)
    func processGeneralPurposeMacro(action: @escaping ()->())
    func shouldUpdateTableHeightTo(value: CGFloat)
}

fileprivate enum CellIdentifiers {
    static let MentionCell = "MentionCellID"
  }

class ChatMentionAutocompleteDataSource : NSObject {
    var suggestions : [MentionOrMacroItem] = [MentionOrMacroItem]()
    var tableView : NSCollectionView!
    var scrollView: NSScrollView!
    var viewWidth: CGFloat = 0.0
    weak var delegate: ChatMentionAutocompleteDelegate!
    var mentionCellHeight :CGFloat = 44.0
    var selectedRow : Int = 0
    
    init(
        tableView: NSCollectionView,
        scrollView: NSScrollView,
        viewWidth: CGFloat,
        delegate: ChatMentionAutocompleteDelegate
    ){
        super.init()
        
        self.tableView = tableView
        self.delegate = delegate
        self.scrollView = scrollView
        self.viewWidth = viewWidth
        self.tableView.backgroundColors = [NSColor.Sphinx.HeaderBG]
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
       
        configureCollectionView()
        updateMentionSuggestions(suggestions: [])
    }
    
    func setViewWidth(viewWidth: CGFloat) {
        self.viewWidth = viewWidth
        
        if let collectionViewFlowLayout = self.tableView.collectionViewLayout as? NSCollectionViewFlowLayout {
            collectionViewFlowLayout.itemSize = NSSize(width: self.viewWidth, height: mentionCellHeight)
            collectionViewFlowLayout.headerReferenceSize = NSSize(width: self.viewWidth, height: 0)
        }
    }
    
    func updateMentionSuggestions(suggestions: [MentionOrMacroItem]) {
        if suggestions.isEmpty == true {
            self.suggestions = []
            self.scrollView.isHidden = true
            return
        }
        
        self.scrollView.isHidden = false
        self.suggestions = suggestions
        
        selectedRow = suggestions.count - 1
        updateMentionTableHeight()
        tableView.reloadData()
        
        if suggestions.isEmpty {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
            if self.tableView.numberOfItems(inSection: 0) > self.selectedRow {
                self.tableView.animator().scrollToItems(
                    at: [IndexPath(item: self.selectedRow, section: 0)],
                    scrollPosition: .bottom
                )
            }
        })
    }
    
    func isTableVisible() -> Bool {
        return suggestions.count > 0 && !self.scrollView.isHidden
    }
    
    func updateMentionTableHeight() {
        let height = min(3 * mentionCellHeight, mentionCellHeight * CGFloat(suggestions.count))
        delegate.shouldUpdateTableHeightTo(value: height + 4)
    }
    
    func configureCollectionView() {
        scrollView.scrollerInsets.right = -999999
        
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.sectionInset = NSEdgeInsets(top: 2.0, left: 0.0, bottom: 2.0, right: 0.0)
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.minimumLineSpacing = 0.0
        flowLayout.sectionHeadersPinToVisibleBounds = true
        flowLayout.itemSize = NSSize(width: self.viewWidth, height: mentionCellHeight)
        flowLayout.headerReferenceSize = NSSize(width: self.viewWidth, height: 0)
        tableView.collectionViewLayout = flowLayout
    }
    
    func getSelectedValue() -> String? {
        if (!suggestions.isEmpty && selectedRow < suggestions.count) {
            let suggestion = suggestions[selectedRow]
            return (suggestion.type == .macro) ? (nil) : (suggestion.displayText)
        }
        return nil
    }
    
    func getSelectedAction()-> (()->())?{
        if (!suggestions.isEmpty && selectedRow < suggestions.count) {
            let suggestion = suggestions[selectedRow]
            return (suggestion.type == .macro) ? (suggestion.action) : (nil)
        }
        return nil
    }
    
    func moveSelectionDown() {
        if (selectedRow < suggestions.count - 1) {
            selectedRow += 1
            tableView.reloadData()
            tableView.animator().scrollToItems(at: [IndexPath(item: selectedRow, section: 0)], scrollPosition: .bottom)
        }
    }
    
    func moveSelectionUp() {
        if (selectedRow > 0) {
            selectedRow -= 1
            tableView.reloadData()
            tableView.animator().scrollToItems(at: [IndexPath(item: selectedRow, section: 0)], scrollPosition: .top)
        }
    }
    
}

extension ChatMentionAutocompleteDataSource : NSCollectionViewDelegate, NSCollectionViewDataSource{
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return suggestions.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        let item = collectionView.makeItem(
            withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ChatMentionAutocompleteCell"),
            for: indexPath
        )
        
        guard let mentionItem = item as? ChatMentionAutocompleteCell else {return item}
        
        if (indexPath.item == selectedRow) {
            mentionItem.view.layer?.backgroundColor = NSColor.Sphinx.PriceTagBG.cgColor
            mentionItem.containerBox.fillColor = NSColor.Sphinx.SelectedMention
        } else{
            mentionItem.view.layer?.backgroundColor = NSColor.Sphinx.PriceTagBG.cgColor
            mentionItem.containerBox.fillColor = NSColor.Sphinx.PriceTagBG
        }
        
        return mentionItem
    }
    
    func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
        if let collectionViewItem = item as? ChatMentionAutocompleteCell {
            collectionViewItem.configureWith(
                mentionOrMacro: suggestions[indexPath.item],
                delegate: delegate
            )
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        if let index = indexPaths.first?.item {
            
            let suggestion = suggestions[index]
            
            if suggestion.type == .mention {
                let valid_alias = suggestion.displayText
                self.delegate?.processAutocomplete(text: valid_alias + " ")
            } else if suggestion.type == .macro, let action = suggestion.action {
                self.delegate?.processGeneralPurposeMacro(action: action)
            }
            
        }
    }
}


extension NSScrollView {
    var documentSize: NSSize {
        set { documentView?.setFrameSize(newValue) }
        get { documentView?.frame.size ?? NSSize.zero }
    }
    
    var documentYOffset: CGFloat {
        set {
            self.contentView.bounds.origin.y = newValue
        }
        get {
            self.contentView.bounds.origin.y
        }
    }
}
