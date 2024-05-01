//
//  GroupContactListItem.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 01/05/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa
import SDWebImage

class GroupContactListItem: NSCollectionViewItem {

    @IBOutlet weak var profileImage: AspectFillNSImageView!
    @IBOutlet weak var contactName: NSTextField!
    @IBOutlet weak var initialName: NSTextField!
    
    var imageUrl: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        setup()
    }
    
    func setup() {
        self.view.wantsLayer = true
        self.view.layer?.masksToBounds = false
        
        profileImage.rounded = true
        profileImage.layer?.cornerRadius = profileImage.frame.height / 2
    }
    
    func render(with item: GroupContact) {
        let url = URL(string: item.contact.avatarUrl ?? "")
        if let nickName = item.contact.nickname, let char = nickName.first {
            self.initialName.stringValue = item.firstOnLetter ? "\(char)".uppercased() : ""
            self.contactName.stringValue = nickName.capitalized
            
            
            let transformer = SDImageResizingTransformer(
                size: CGSize(
                    width: profileImage.bounds.size.width * 2,
                    height: profileImage.bounds.size.height * 2
                ),
                scaleMode: .aspectFill
            )
            
            self.imageUrl = url?.absoluteString
            
            profileImage.sd_setImage(
                with: url,
                placeholderImage: NSImage(named: "profileAvatar"),
                options: [.scaleDownLargeImages, .decodeFirstFrameOnly, .progressiveLoad],
                context: [.imageTransformer: transformer],
                progress: nil,
                completed: { (image, error, _, _) in
                    if let image = image, error == nil {
                        self.profileImage.image = image
                        self.profileImage.isHidden = false
                    }
                }

            )

        }
    }
    
}
