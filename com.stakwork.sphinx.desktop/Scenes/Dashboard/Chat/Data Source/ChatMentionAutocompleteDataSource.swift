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

class ChatMentionAutocompleteDataSource : NSObject {
    var mentionSuggestions : [String] = [String]()
    var tableView : NSTableView!
    var delegate: ChatMentionAutocompleteDelegate!
    let mentionCellHeight :CGFloat = 50.0
    
    init(tableView:NSTableView,delegate:ChatMentionAutocompleteDelegate){
        super.init()
        self.tableView = tableView
        self.delegate = delegate
        tableView.backgroundColor = .clear
        //tableView.separatorColor = UIColor.Sphinx.Divider
        //tableView.estimatedRowHeight = mentionCellHeight
        //tableView.rowHeight = UITableView.automaticDimension
        //tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
    }
    
    func updateMentionSuggestions(suggestions:[String]){
        /*
        self.tableView.isHidden = (suggestions.isEmpty == true)
        self.mentionSuggestions = suggestions
        tableView.reloadData()
        if(suggestions.isEmpty == false){
            let bottom = IndexPath(
                row: 0,
                section: 0)
            tableView.scrollToRow(at: bottom, at: .bottom, animated: true)
        }
        */
    }
    
}


extension ChatMentionAutocompleteDataSource : NSTableViewDelegate,NSTableViewDataSource{
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let view = NSTableRowView()
        view.backgroundColor = .green
        return view
    }
}
