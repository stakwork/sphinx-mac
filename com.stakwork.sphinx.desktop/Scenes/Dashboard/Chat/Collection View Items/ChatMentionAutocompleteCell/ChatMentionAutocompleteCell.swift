//
//  ChatMentionAutocompleteCell.swift
//  Sphinx
//
//  Created by James Carucci on 12/14/22.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Cocoa
import SDWebImage

class ChatMentionAutocompleteCell: NSCollectionViewItem {

    @IBOutlet weak var mentionTextField: NSTextField!
    @IBOutlet weak var dividerLine: NSBox!
    @IBOutlet weak var avatarImage: NSImageView!
    
    var delegate : ChatMentionAutocompleteDelegate? = nil
    var alias : String? = nil
    var type : MentionOrMacroType = .mention
    var action: (()->())? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.wantsLayer = true
        dividerLine.layer?.borderColor = NSColor.Sphinx.LightDivider.cgColor
    }
    
    func configureWith(mentionOrMacro:MentionOrMacroItem,delegate:ChatMentionAutocompleteDelegate){
        self.delegate = delegate
        self.mentionTextField.stringValue = mentionOrMacro.displayText
        self.alias = mentionOrMacro.displayText
        self.type = mentionOrMacro.type
        self.action = mentionOrMacro.action
        self.view.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(handleClick)))
        
        
        if(mentionOrMacro.type == .macro){
            avatarImage.image = mentionOrMacro.image ?? #imageLiteral(resourceName: "appPinIcon")
        }
        else{
            avatarImage.layer?.contentsGravity = .resizeAspectFill
            avatarImage.sd_setImage(with: mentionOrMacro.imageLink, placeholderImage: #imageLiteral(resourceName: "appPinIcon"), context: nil)
            avatarImage.makeCircular()
        }
        avatarImage.contentTintColor = NSColor.Sphinx.BodyInverted
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImage?.image = nil
        view.layer?.backgroundColor = .clear
    }
    
    @objc func handleClick(){
        if let valid_alias = alias, type == .mention{
            self.delegate?.processAutocomplete(text: valid_alias + " ")
        }
        else if type == .macro,
        let action = action{
            print("MACRO")
            self.delegate?.processGeneralPurposeMacro(action: action)
        }
    }
}
