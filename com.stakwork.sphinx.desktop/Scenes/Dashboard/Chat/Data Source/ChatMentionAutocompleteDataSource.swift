//
//  ChatMentionAutocompleteDataSource.swift
//  Sphinx
//
//  Created by James Carucci on 12/8/22.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Foundation
import AppKit

protocol ChatMentionAutocompleteDelegate{
    func processAutocomplete(text:String)
    func processGeneralPurposeMacro(action: @escaping ()->())
    func getTableHeightConstraint() -> NSLayoutConstraint?
}

fileprivate enum CellIdentifiers {
    static let MentionCell = "MentionCellID"
  }

class ChatMentionAutocompleteDataSource : NSObject {
    var suggestions : [MentionOrMacroItem] = [MentionOrMacroItem]()
    var tableView : NSCollectionView!
    var scrollView: NSScrollView!
    var delegate: ChatMentionAutocompleteDelegate!
    var mentionCellHeight :CGFloat = 50.0
    var selectedRow : Int = 0
    var vc : ChatViewController? = nil
    
    init(
        tableView: NSCollectionView,
        scrollView: NSScrollView,
        delegate: ChatMentionAutocompleteDelegate,
        vc: ChatViewController
    ){
        super.init()
        self.vc = vc
        
        self.tableView = tableView
        self.delegate = delegate
        self.scrollView = scrollView
        self.tableView.backgroundColors = [NSColor.Sphinx.HeaderBG]
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
       
        configureCollectionView()
        updateMentionSuggestions(suggestions: [])
    }
    
    func updateMentionSuggestions(suggestions: [MentionOrMacroItem]) {
        self.scrollView.isHidden = (suggestions.isEmpty == true)
        self.suggestions = suggestions
        selectedRow = suggestions.count - 1
        updateMentionTableHeight()
        tableView.reloadData()
        
        if suggestions.isEmpty || self.selectedRow == -1 { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
            if self.selectedRow == -1 { return }
            
            print("self.selectedRow \(self.selectedRow)")
            
            self.tableView.animator().scrollToItems(at: [IndexPath(item: self.selectedRow, section: 0)], scrollPosition: .bottom)
        })
    }
    
    func isTableVisible() -> Bool {
        return suggestions.count > 0
    }
    
    func updateMentionTableHeight() {
        if let heightConstraint = self.delegate.getTableHeightConstraint() {
            let height = min(4 * mentionCellHeight, mentionCellHeight * CGFloat(suggestions.count))
            heightConstraint.isActive = false
            heightConstraint.constant = height
            heightConstraint.isActive = true
            scrollView.layoutSubtreeIfNeeded()
        }
    }
    
    func configureCollectionView() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.sectionInset = NSEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.minimumLineSpacing = 0.0
        flowLayout.sectionHeadersPinToVisibleBounds = true
        flowLayout.itemSize = NSSize(width: tableView.frame.width, height: mentionCellHeight)
        flowLayout.headerReferenceSize = NSSize(width: tableView.frame.width, height: 0)
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
        if(selectedRow < suggestions.count - 1){
            selectedRow+=1
            tableView.reloadData()
            tableView.animator().scrollToItems(at: [IndexPath(item: selectedRow, section: 0)], scrollPosition: .bottom)
        }
    }
    
    func moveSelectionUp() {
        if(selectedRow > 0){
            selectedRow-=1
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
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ChatMentionAutocompleteCell"), for: indexPath)
        
        guard let mentionItem = item as? ChatMentionAutocompleteCell else {return item}
        
        if (indexPath.item == selectedRow) {
            mentionItem.view.layer?.backgroundColor = NSColor.Sphinx.ChatListSelected.cgColor
        } else{
            mentionItem.view.layer?.backgroundColor = NSColor.Sphinx.HeaderBG.cgColor
        }
        
        return mentionItem
    }
    
    func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
        if let collectionViewItem = item as? ChatMentionAutocompleteCell,
           let valid_vc = vc {
            collectionViewItem.configureWith(mentionOrMacro: suggestions[indexPath.item], delegate: valid_vc)
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
