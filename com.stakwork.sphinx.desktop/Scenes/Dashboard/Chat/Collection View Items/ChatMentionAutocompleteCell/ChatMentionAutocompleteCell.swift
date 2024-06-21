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
    @IBOutlet weak var avatarImage: NSImageView!
    @IBOutlet weak var iconLabel: NSTextField!
    @IBOutlet weak var initialsBox: NSBox!
    @IBOutlet weak var initialsLabel: NSTextField!
    @IBOutlet weak var containerBox: NSBox!
    
    var delegate : ChatMentionAutocompleteDelegate? = nil
    var alias : String? = nil
    var type : MentionOrMacroType = .mention
    var action: (()->())? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.wantsLayer = true
        avatarImage.imageAlignment = .alignCenter
    }
    
    func configureWith(
        mentionOrMacro: MentionOrMacroItem,
        delegate: ChatMentionAutocompleteDelegate
    ){
        self.alias = mentionOrMacro.displayText
        self.type = mentionOrMacro.type
        self.action = mentionOrMacro.action
        
        avatarImage.isHidden = true
        iconLabel.isHidden = true
        initialsBox.isHidden = true
        
        mentionTextField.stringValue = mentionOrMacro.displayText
        
        avatarImage.wantsLayer = true
        avatarImage?.sd_cancelCurrentImageLoad()
        
        if (mentionOrMacro.type == .macro) {
            
            if let icon = mentionOrMacro.icon {
                iconLabel.stringValue = icon
                iconLabel.isHidden = false
            } else {
                avatarImage.layer?.cornerRadius = 0
                avatarImage.imageScaling = .scaleNone
                avatarImage.image = mentionOrMacro.image ?? NSImage(named: "appPinIcon")
                avatarImage.isHidden = false
            }
        } else {
            initialsBox.isHidden = false
            iconLabel.isHidden = true
            
            initialsBox.fillColor = NSColor.getColorFor(key: "\(mentionOrMacro.displayText)-color")
            initialsLabel.stringValue = mentionOrMacro.displayText.getInitialsFromName()
            
            if let imageLink = mentionOrMacro.imageLink, let url = URL(string: imageLink) {
                
                let transformer = SDImageResizingTransformer(
                    size: CGSize(
                        width: avatarImage.bounds.size.width * 2,
                        height: avatarImage.bounds.size.height * 2
                    ),
                    scaleMode: .aspectFill
                )
                
                avatarImage.layer?.cornerRadius = avatarImage.frame.size.height / 2
                avatarImage.imageScaling = .scaleAxesIndependently
                
                avatarImage.sd_setImage(
                    with: url,
                    placeholderImage: NSImage(named: "profileAvatar"),
                    options: [SDWebImageOptions.progressiveLoad],
                    context: [.imageTransformer: transformer],
                    progress: nil,
                    completed: { (image, error, _, _) in
                        if let image = image, error == nil {
                            self.avatarImage.image = image
                            self.avatarImage.isHidden = false
                        }
                    }
                )
            }
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
        containerBox.fillColor = .clear
        view.layer?.backgroundColor = .clear
    }
    
    @objc func handleClick(){
        if let valid_alias = alias, type == .mention {
            self.delegate?.processAutocomplete(text: valid_alias + " ")
        } else if type == .macro, let action = action {
            self.delegate?.processGeneralPurposeMacro(action: action)
        }
    }
}
