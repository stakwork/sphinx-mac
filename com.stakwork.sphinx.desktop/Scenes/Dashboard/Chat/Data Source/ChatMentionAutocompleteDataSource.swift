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
    
    init(tableView:NSCollectionView,scrollView:NSScrollView,delegate:ChatMentionAutocompleteDelegate){
        super.init()
        mentionCellHeight = tableView.frame.height * 0.1
        self.tableView = tableView
        self.delegate = delegate
        self.scrollView = scrollView
        
        updateMentionSuggestions(suggestions: [])
        configureCollectionView()
    }
    
    func updateMentionSuggestions(suggestions:[String]){
        self.scrollView.isHidden = (suggestions.isEmpty == true)
        self.mentionSuggestions = suggestions
        tableView.reloadData()
        //tableView.selectItems(at: [IndexPath(item: 0, section: 0)], scrollPosition: NSCollectionView.ScrollPosition.top)

    }
    
    fileprivate func configureCollectionView() {
      let flowLayout = NSCollectionViewFlowLayout()
      flowLayout.itemSize = NSSize(width: 160.0, height: 140.0)
        flowLayout.sectionInset = NSEdgeInsets(top: 30.0, left: 20.0, bottom: 30.0, right: 20.0)
      flowLayout.minimumInteritemSpacing = 20.0
      flowLayout.minimumLineSpacing = 20.0
      flowLayout.sectionHeadersPinToVisibleBounds = true
        tableView.collectionViewLayout = flowLayout
    }
    
    func moveSelectionDown(){
        if(selectedRow < mentionSuggestions.count){
            selectedRow+=1
            tableView.reloadData()
        }
    }
    
    func moveSelectionUp(){
        if(selectedRow > 0){
            selectedRow-=1
            tableView.reloadData()
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
        
        //mentionItem.textField.value
        
        return mentionItem
    }
    
    func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
        if let collectionViewItem = item as? ChatMentionAutocompleteCell{
            collectionViewItem.configureWith(alias: mentionSuggestions[indexPath.item])
            if(indexPath.item == selectedRow){collectionViewItem.view.layer?.backgroundColor = NSColor.lightGray.cgColor}
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
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
      return NSSize(width: 1000, height: 0)
    }
  }