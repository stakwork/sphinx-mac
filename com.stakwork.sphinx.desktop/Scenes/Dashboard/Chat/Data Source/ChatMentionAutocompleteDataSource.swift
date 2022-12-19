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
    func getTableHeightConstraint() -> NSLayoutConstraint?
}

fileprivate enum CellIdentifiers {
    static let MentionCell = "MentionCellID"
  }

class ChatMentionAutocompleteDataSource : NSObject {
    var mentionSuggestions : [String] = [String]()
    var tableView : NSCollectionView!
    var scrollView: NSScrollView!
    var delegate: ChatMentionAutocompleteDelegate!
    var mentionCellHeight :CGFloat = 50.0
    var selectedRow : Int = 0
    var vc : ChatViewController? = nil
    
    init(tableView:NSCollectionView,scrollView:NSScrollView,delegate:ChatMentionAutocompleteDelegate,vc:ChatViewController){
        super.init()
        self.vc = vc
        
        self.tableView = tableView
        self.delegate = delegate
        self.scrollView = scrollView
        self.tableView.backgroundColors = [NSColor.Sphinx.HeaderBG]
        
        updateMentionSuggestions(suggestions: [])
        configureCollectionView()
    }
    
    func updateMentionSuggestions(suggestions:[String]){
        self.scrollView.isHidden = (suggestions.isEmpty == true)
        self.mentionSuggestions = suggestions.reversed()
        selectedRow = mentionSuggestions.count - 1
        updateMentionTableHeight()
        tableView.reloadData()
    }
    
    func updateMentionTableHeight(){
        if let heightConstraint = self.delegate.getTableHeightConstraint(){
            let height = min(4 * mentionCellHeight,mentionCellHeight * CGFloat(mentionSuggestions.count))
            heightConstraint.isActive = false
            heightConstraint.constant = height
            heightConstraint.isActive = true
            scrollView.layoutSubtreeIfNeeded()
        }
    }
    
    fileprivate func configureCollectionView() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 160.0, height: 140.0)
        flowLayout.sectionInset = NSEdgeInsets(top: 0.0, left: 20.0, bottom: 0.0, right: 20.0)
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.minimumLineSpacing = 0.0
        flowLayout.sectionHeadersPinToVisibleBounds = true
        tableView.collectionViewLayout = flowLayout
    }
    
    func getSelectedValue()->String?{
        if(!mentionSuggestions.isEmpty && selectedRow < mentionSuggestions.count){
            return mentionSuggestions[selectedRow]
        }
        return nil
    }
    
    func moveSelectionDown(){
        if(selectedRow < mentionSuggestions.count - 1){
            selectedRow+=1
            tableView.reloadData()
            tableView.animator().scrollToItems(at: [IndexPath(item: selectedRow, section: 0)], scrollPosition: .bottom)
        }
    }
    
    func moveSelectionUp(){
        if(selectedRow > 0){
            selectedRow-=1
            tableView.reloadData()
            tableView.animator().scrollToItems(at: [IndexPath(item: selectedRow, section: 0)], scrollPosition: .top)
        }
    }
    
}

extension ChatMentionAutocompleteDataSource : NSCollectionViewDelegate,NSCollectionViewDataSource{
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        //
        return mentionSuggestions.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ChatMentionAutocompleteCell"), for: indexPath)
        
        guard let mentionItem = item as? ChatMentionAutocompleteCell else {return item}
        
        if(indexPath.item == selectedRow){
            mentionItem.view.layer?.backgroundColor = NSColor.Sphinx.ChatListSelected.cgColor
        }
        else{
            mentionItem.view.layer?.backgroundColor = NSColor.Sphinx.HeaderBG.cgColor
        }
        
        return mentionItem
    }
    
    func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
        if let collectionViewItem = item as? ChatMentionAutocompleteCell,
        let valid_vc = vc{
            collectionViewItem.configureWith(alias: mentionSuggestions[indexPath.item], delegate: valid_vc)
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return NSSize(width: collectionView.frame.width, height: mentionCellHeight)
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        if let path = indexPaths.first{
            selectedRow = path.item
            tableView.reloadData()
        }
    }
    
    
}

extension ChatMentionAutocompleteDataSource : NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout:NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
        return NSSize(width: 1000, height: 0)
    }
}

