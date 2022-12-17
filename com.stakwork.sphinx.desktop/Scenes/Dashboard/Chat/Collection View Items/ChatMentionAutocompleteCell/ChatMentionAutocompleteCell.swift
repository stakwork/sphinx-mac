//
//  ChatMentionAutocompleteCell.swift
//  Sphinx
//
//  Created by James Carucci on 12/14/22.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Cocoa

class ChatMentionAutocompleteCell: NSCollectionViewItem {

    @IBOutlet weak var mentionTextField: NSTextField!
    var delegate : ChatMentionAutocompleteDelegate? = nil
    var alias : String? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.wantsLayer = true
    }
    
    func configureWith(alias:String,delegate:ChatMentionAutocompleteDelegate){
        self.delegate = delegate
        self.mentionTextField.stringValue = alias
        self.alias = alias
        self.view.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(handleClick)))
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        view.layer?.backgroundColor = .clear
    }
    
    @objc func handleClick(){
        if let valid_alias = alias{
            self.delegate?.processAutocomplete(text: valid_alias + " ")
        }
    }
}
