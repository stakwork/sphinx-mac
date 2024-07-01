//
//  NewShareInviteCodeViewController.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 30/06/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa

class NewShareInviteCodeViewController: NSViewController {
    
    var qrCodeString = ""
    var viewTitleString = ""
    
    @IBOutlet weak var qrCodeImageView: NSImageView!
    @IBOutlet weak var inviteCodeLabel: NSTextField!
    @IBOutlet weak var viewTitle: NSTextField!
    @IBOutlet weak var copyButton: CustomButton!
    @IBOutlet weak var profileImageView: AspectFillNSImageView!
    
    public enum ViewMode: Int {
        case Invite = 0
        case PubKey = 1
        case TribeQR = 2
        case RouteHint = 3
        case Invoice = 4
    }
    
    var viewMode = ViewMode.Invite
    var copiedStrind = "code.copied.clipboard".localized
    var profile: UserContact? = nil
    weak var delegate: NewContactDismissDelegate?
    
    static func instantiate(profile: UserContact, delegate: NewContactDismissDelegate?) -> NewShareInviteCodeViewController {
//        print("here is the viewmode: \(title)")
        let viewController = StoryboardScene.Invite.newShareInviteCodeViewController.instantiate()
//        viewController.qrCodeString = qrCodeString
//        viewController.viewTitleString = title
        viewController.profile = profile
        viewController.delegate = delegate
        viewController.qrCodeString = profile.getAddress() ?? ""
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        copyButton.cursor = .pointingHand
        qrCodeImageView.image = NSImage.qrCode(from: qrCodeString, size: qrCodeImageView.frame.size)
        inviteCodeLabel.stringValue = qrCodeString
//        setViewTitle()
        configureProfile()
        view.wantsLayer = true
        view.layer?.backgroundColor = .clear
    }
    
    func setViewTitle() {
//        viewTitle.stringValue = viewTitleString
//        switch (viewMode) {
//        case .Invite:
//            viewTitle.stringValue = "share.invite.code.upper".localized
//            copiedStrind = "code.copied.clipboard".localized
//        case .PubKey:
//            viewTitle.stringValue = "pubkey.upper".localized
//            copiedStrind = "pubkey.copied.clipboard".localized
//        case .TribeQR:
//            viewTitle.stringValue = "group.link.upper".localized
//            copiedStrind = "link.copied.clipboard".localized
//        case .RouteHint:
//            viewTitle.stringValue = "route.hint".localized.uppercased()
//            copiedStrind = "route.hint.copied.clipboard".localized
//        case .Invoice:
//            viewTitle.stringValue = "invoice".localized.uppercased()
//            copiedStrind = "invoice.copied.clipboard".localized
//        }
    }
    
    func configureProfile() {
        setupViews()
        
        if let profile = profile {
            if let imageUrl = profile.avatarUrl?.trim(), imageUrl != "" {
                MediaLoader.loadAvatarImage(url: imageUrl, objectId: profile.id, completion: { (image, id) in
                    guard let image = image else {
                        return
                    }
                    self.profileImageView.bordered = false
//                    self.profileImageView.borderWidth = 4
//                    self.profileImageView.borderColor = NSColor.Sphinx.DashboardSearch.cgColor
                    self.profileImageView.image = image
                })
            } else {
                profileImageView.image = NSImage(named: "profileAvatar")
            }
            
            let nickname = profile.nickname ?? ""
            viewTitle.stringValue = nickname.getNameStyleString(lineBreak: false)
        }
    }
    
    func setupViews() {
        profileImageView.wantsLayer = true
        profileImageView.rounded = true
        profileImageView.layer?.cornerRadius = profileImageView.frame.height / 2
    }
    
    @IBAction func copyButtonClicked(_ sender: Any) {
        ClipboardHelper.copyToClipboard(text: inviteCodeLabel.stringValue, message: copiedStrind)
    }
    
    @IBAction func dismissButtonTapped(_ sender: NSButton) {
        delegate?.shouldDismissView()
    }
}
