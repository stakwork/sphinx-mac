//
//  ShareInviteCodeViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 09/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class ShareInviteCodeViewController: NSViewController {
    
    var qrCodeString = ""
    
    @IBOutlet weak var qrCodeImageView: NSImageView!
    @IBOutlet weak var inviteCodeLabel: NSTextField!
    @IBOutlet weak var viewTitle: NSTextField!
    @IBOutlet weak var copyButton: CustomButton!
    
    public enum ViewMode: Int {
        case Invite = 0
        case PubKey = 1
        case TribeQR = 2
        case RouteHint = 3
        case Invoice = 4
    }
    
    var viewMode = ViewMode.Invite
    var copiedStrind = "code.copied.clipboard".localized
    
    static func instantiate(qrCodeString: String, viewMode: ViewMode) -> ShareInviteCodeViewController {
        let viewController = StoryboardScene.Invite.shareInviteCodeViewController.instantiate()
        viewController.qrCodeString = qrCodeString
        viewController.viewMode = viewMode
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        copyButton.cursor = .pointingHand
        qrCodeImageView.image = NSImage.qrCode(from: qrCodeString, size: qrCodeImageView.frame.size)
        inviteCodeLabel.stringValue = qrCodeString
        setViewTitle()
    }
    
    func setViewTitle() {
        switch (viewMode) {
        case .Invite:
            viewTitle.stringValue = "share.invite.code.upper".localized
            copiedStrind = "code.copied.clipboard".localized
        case .PubKey:
            viewTitle.stringValue = "pubkey.upper".localized
            copiedStrind = "pubkey.copied.clipboard".localized
        case .TribeQR:
            viewTitle.stringValue = "group.link.upper".localized
            copiedStrind = "link.copied.clipboard".localized
        case .RouteHint:
            viewTitle.stringValue = "route.hint".localized.uppercased()
            copiedStrind = "route.hint.copied.clipboard".localized
        case .Invoice:
            viewTitle.stringValue = "invoice".localized.uppercased()
            copiedStrind = "invoice.copied.clipboard".localized
        }
    }
    
    @IBAction func copyButtonClicked(_ sender: Any) {
        ClipboardHelper.copyToClipboard(text: inviteCodeLabel.stringValue, message: copiedStrind)
    }
}
