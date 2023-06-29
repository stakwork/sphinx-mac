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
    @IBOutlet weak var iconLabel: NSTextField!
    
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
    
    func configureWith(mentionOrMacro: MentionOrMacroItem,delegate:ChatMentionAutocompleteDelegate){
        self.alias = mentionOrMacro.displayText
        self.type = mentionOrMacro.type
        self.action = mentionOrMacro.action
        
        mentionTextField.stringValue = mentionOrMacro.displayText
        
        avatarImage?.sd_cancelCurrentImageLoad()
        
        if (mentionOrMacro.type == .macro) {
            
            if let icon = mentionOrMacro.icon {
                iconLabel.stringValue = icon
                
                avatarImage.isHidden = true
                iconLabel.isHidden = false
            } else {
                avatarImage.image = mentionOrMacro.image ?? NSImage(named: "appPinIcon")
                //avatarImage.contentMode = mentionOrMacro.imageContentMode ?? .center
                
                avatarImage.isHidden = false
                iconLabel.isHidden = true
            }
            
        } else {
            avatarImage.isHidden = false
            iconLabel.isHidden = true
            
            avatarImage.makeCircular()
            makeImagesCircular(images: [avatarImage])
            avatarImage.imageScaling = .scaleAxesIndependently
            avatarImage.imageAlignment = .alignCenter
            
            if let imageLink = mentionOrMacro.imageLink, let url = URL(string: imageLink) {
                avatarImage.sd_setImage(
                    with: url,
                    placeholderImage: NSImage(named: "profile_avatar"),
                    context: nil
                )
            } else {
                avatarImage.image = NSImage(named: "profile_avatar")
            }
            
            //avatarImage.contentMode = .scaleAspectFill
        }
        avatarImage.contentTintColor = NSColor.Sphinx.SecondaryText
    }
    
    func makeImagesCircular(images: [NSView]) {
        for image in images {
            image.wantsLayer = true
            image.layer?.cornerRadius = image.frame.size.height / 2
            image.layer?.masksToBounds = true
        }
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
