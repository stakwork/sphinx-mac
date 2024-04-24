//
//  NewMenuItemDataSource.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 24/04/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Foundation
import AppKit

fileprivate enum CellIdentifiers {
    static let NewMenuItemCell = "NewMenuItemCellID"
  }

protocol NewMenuItemDataSourceDelegate: AnyObject {
    func itemSelected(at index: Int)
}


class NewMenuItemDataSource : NSObject {
    var suggestions : [NewMenuItem] = [NewMenuItem]()
    var tableView : NSCollectionView!
    var scrollView: NSScrollView!
    var viewWidth: CGFloat = 0.0
    weak var delegate: NewMenuItemDataSourceDelegate!
    var mentionCellHeight :CGFloat = 50.0
    var selectedRow : Int = 0
    
    init(
        tableView: NSCollectionView,
        scrollView: NSScrollView,
        viewWidth: CGFloat,
        delegate: NewMenuItemDataSourceDelegate
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
    
    func updateMentionSuggestions(suggestions: [NewMenuItem]) {
        if suggestions.isEmpty == true {
            self.suggestions = []
            self.scrollView.isHidden = true
            return
        }
        
        self.scrollView.isHidden = false
        self.suggestions = suggestions
        
        selectedRow = suggestions.count - 1
//        updateMentionTableHeight()
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
    
//    func updateMentionTableHeight() {
//        let height = min(4 * mentionCellHeight, mentionCellHeight * CGFloat(suggestions.count))
//        delegate.shouldUpdateTableHeightTo(value: height)
//    }
    
    func configureCollectionView() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.sectionInset = NSEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.minimumLineSpacing = 0.0
        flowLayout.sectionHeadersPinToVisibleBounds = true
        flowLayout.itemSize = NSSize(width: self.viewWidth, height: mentionCellHeight)
        flowLayout.headerReferenceSize = NSSize(width: self.viewWidth, height: 0)
        tableView.collectionViewLayout = flowLayout
    }
    
//    func getSelectedValue() -> String? {
//        if (!suggestions.isEmpty && selectedRow < suggestions.count) {
//            let suggestion = suggestions[selectedRow]
//            return (suggestion.type == .macro) ? (nil) : (suggestion.displayText)
//        }
//        return nil
//    }
//
//    func getSelectedAction()-> (()->())?{
//        if (!suggestions.isEmpty && selectedRow < suggestions.count) {
//            let suggestion = suggestions[selectedRow]
//            return (suggestion.type == .macro) ? (suggestion.action) : (nil)
//        }
//        return nil
//    }
    
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

extension NewMenuItemDataSource : NSCollectionViewDelegate, NSCollectionViewDataSource{
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
        if let collectionViewItem = item as? ChatMentionAutocompleteCell {
//            collectionViewItem.configureWith(
//                mentionOrMacro: suggestions[indexPath.item],
//                delegate: delegate
//            )
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        if let index = indexPaths.first?.item {
            
            let suggestion = suggestions[index]
            delegate.itemSelected(at: index)
//            if suggestion.type == .mention {
//                let valid_alias = suggestion.displayText
//                self.delegate?.processAutocomplete(text: valid_alias + " ")
//            } else if suggestion.type == .macro, let action = suggestion.action {
//                self.delegate?.processGeneralPurposeMacro(action: action)
//            }
            
        }
    }
}
