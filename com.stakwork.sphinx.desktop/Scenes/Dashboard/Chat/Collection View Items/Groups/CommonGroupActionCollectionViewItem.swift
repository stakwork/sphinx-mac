//
//  CommonGroupActionCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 07/07/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class CommonGroupActionCollectionViewItem: NSCollectionViewItem, GroupActionRowProtocol {
    
    weak var delegate: GroupRowDelegate?

    @IBOutlet weak var groupJoinLeaveLabelContainer: NSBox!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        groupJoinLeaveLabelContainer.wantsLayer = true
        groupJoinLeaveLabelContainer.layer?.cornerRadius = getCornerRadius()
        groupJoinLeaveLabelContainer.layer?.borderColor = NSColor.Sphinx.LightDivider.cgColor
        groupJoinLeaveLabelContainer.layer?.borderWidth = 1
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()

        delegate = nil
    }
    
    func configureMessage(message: TransactionMessage) {}
    
    func getCornerRadius() -> CGFloat {
        return groupJoinLeaveLabelContainer.frame.size.height / 2
    }
}
