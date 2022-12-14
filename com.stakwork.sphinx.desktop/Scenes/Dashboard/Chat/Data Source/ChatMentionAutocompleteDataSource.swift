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
    let mentionCellHeight :CGFloat = 50.0
    
    init(tableView:NSCollectionView,scrollView:NSScrollView,delegate:ChatMentionAutocompleteDelegate){
        super.init()
        self.tableView = tableView
        self.delegate = delegate
        
        let tableColumn = NSTableColumn()
        tableColumn.identifier = NSUserInterfaceItemIdentifier("mentionsTableColumn")
        
        
        self.scrollView = scrollView
        //tableView.separatorColor = UIColor.Sphinx.Divider
        //tableView.estimatedRowHeight = mentionCellHeight
        //tableView.rowHeight = UITableView.automaticDimension
        //tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
    }
    
    func updateMentionSuggestions(suggestions:[String]){
        self.scrollView.isHidden = (suggestions.isEmpty == true)
        self.mentionSuggestions = suggestions
        tableView.reloadData()
        /*
        if(suggestions.isEmpty == false){
            let bottom = IndexPath(
                row: 0,
                section: 0)
            tableView.scrollToRow(at: bottom, at: .bottom, animated: true)
        }
        */
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
        }
        
    }
    
    
}

/*
extension ChatMentionAutocompleteDataSource : NSTableViewDelegate,NSTableViewDataSource{
    func numberOfRows(in tableView: NSTableView) -> Int {
        return mentionSuggestions.count
    }
    
    func tableView(_ tableView: NSTableView,
        viewFor tableColumn: NSTableColumn?,
        row: Int) -> NSView? {
     
        let cellIdentifier = CellIdentifiers.MentionCell
        
        let cellID = NSUserInterfaceItemIdentifier(cellIdentifier)
        if let cell = tableView.makeView(withIdentifier: cellID, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = mentionSuggestions[row]
            return cell
        }

        return nil
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return mentionSuggestions[row]
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        print(notification)
    }
}
*/
