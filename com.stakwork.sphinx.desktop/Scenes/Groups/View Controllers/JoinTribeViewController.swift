//
//  JoinTribeViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 11/12/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import SwiftyJSON


// Used to prevent moving view content during resize
// unless the scollview becomes larger than the content
// during which this code will keep the scrollview
// content vertically centered.
final class VerticallyCenteringClipView: NSClipView {
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var constrainedClipViewBounds = super.constrainBoundsRect(proposedBounds)

        guard let documentView else {
            return constrainedClipViewBounds
        }

        let documentViewSize = documentView.fittingSize
        
        let correctedY = floor((proposedBounds.height - documentViewSize.height) / 2.0)
        if documentViewSize.height < proposedBounds.height {
            constrainedClipViewBounds.origin.y = correctedY
        } else {
            constrainedClipViewBounds.origin.y = bounds.origin.y
        }

        return constrainedClipViewBounds
    }
}

class JoinTribeViewController: NSViewController {
    
    weak var delegate: NewContactChatDelegate?
    
    @IBOutlet weak var tribeImageView: AspectFillNSImageView!
    @IBOutlet weak var tribeNameLabel: NSTextField!
    @IBOutlet weak var tribeDescriptionLabel: NSTextField!
    @IBOutlet weak var priceToJoin: NSTextField!
    @IBOutlet weak var pricePerMessage: NSTextField!
    @IBOutlet weak var amountToStake: NSTextField!
    @IBOutlet weak var timeToStake: NSTextField!
    @IBOutlet weak var tribeMemberInfoView: TribeMemberInfoView!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    @IBOutlet weak var uploadedLabel: NSTextField!
    @IBOutlet weak var joinTribeButton: NSButton!
    @IBOutlet weak var joinTribeBox: NSBox!
    @IBOutlet weak var joinTribeView: NSView!
    
    @IBOutlet weak var loadingTribeContainer: NSBox!
    @IBOutlet weak var loadingTribeLabel: NSTextField!
    @IBOutlet weak var loadingTribeLoadingWheel: NSProgressIndicator!
    
    var groupsManager = GroupsManager.sharedInstance
    var tribeInfo: GroupsManager.TribeInfo! = nil
    let owner = UserContact.getOwner()
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.white, controls: [joinTribeButton])
        }
    }
    
    var loadingGroup = false {
        didSet {
            loadingTribeContainer.isHidden = !loadingGroup
            LoadingWheelHelper.toggleLoadingWheel(loading: loadingGroup, loadingWheel: loadingTribeLoadingWheel, color: NSColor.Sphinx.Text, controls: [])
        }
    }
    
    var uploading = false {
        didSet {
            uploadedLabel.isHidden = !uploading
        }
    }
    
    static func instantiate(tribeInfo: GroupsManager.TribeInfo, delegate: NewContactChatDelegate) -> JoinTribeViewController {
        let viewController = StoryboardScene.Groups.joinTribeViewController.instantiate()
        viewController.tribeInfo = tribeInfo
        viewController.delegate = delegate
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tribeImageView.wantsLayer = true
        tribeImageView.rounded = true
        tribeImageView.layer?.cornerRadius = tribeImageView.frame.height / 2
        
        loadGroupDetails()
    }
        
    func loadGroupDetails() {
        loadingGroup = true
        
        if let tribeInfo = tribeInfo {
            API.sharedInstance.getTribeInfo(host: tribeInfo.host, uuid: tribeInfo.uuid, callback: { groupInfo in
                self.completeDataAndShow(groupInfo: groupInfo)
            }, errorCallback: {
                self.showErrorAndDismiss()
            })
        } else {
            showErrorAndDismiss()
        }
    }
    
    func completeDataAndShow(groupInfo: JSON) {
        groupsManager.update(tribeInfo: &tribeInfo!, from: groupInfo)
        
        tribeNameLabel.stringValue = tribeInfo?.name ?? ""
        tribeDescriptionLabel.stringValue = tribeInfo?.description ?? ""
        
        priceToJoin.stringValue = "\(tribeInfo?.priceToJoin ?? 0)"
        pricePerMessage.stringValue = "\(tribeInfo?.pricePerMessage ?? 0)"
        amountToStake.stringValue = "\(tribeInfo?.amountToStake ?? 0)"
        timeToStake.stringValue = "\(tribeInfo?.timeToStake ?? 0)"
        
        tribeImageView.borderColor = NSColor.Sphinx.SecondaryText.cgColor
        tribeImageView.bordered = true
        tribeImageView.gravity = .resizeAspectFill
        
        if let imageUrl = tribeInfo?.img?.trim(), let nsUrl = URL(string: imageUrl), imageUrl != "" {
            MediaLoader.asyncLoadImage(imageView: tribeImageView, nsUrl: nsUrl, placeHolderImage: NSImage(named: "tribePlaceHolder"), completion: {
                self.tribeImageView.bordered = false
                self.tribeImageView.gravity = .resizeAspectFill
                self.tribeImageView.customizeLayer()
            })
        } else {
            tribeImageView.image = NSImage(named: "tribePlaceHolder")?.image(withTintColor: NSColor.Sphinx.SecondaryText)
        }
        
        tribeMemberInfoView.configureWith(
            vc: self,
            alias: owner?.nickname,
            picture: owner?.getPhotoUrl(),
            shouldFixAlias: true
        )
        
        loadingGroup = false
    }
    
    func showErrorAndDismiss() {
        AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
        WindowsManager.sharedInstance.dismissViewFromCurrentWindow()
    }
    
    @IBAction func joinTribeButtonTouched(_ sender: Any) {
        loading = true
        
        tribeMemberInfoView.uploadImage(completion: { (name, image) in
            self.joinTribe(name: name, imageUrl: image)
        })
    }
    
    func joinTribe(name: String?, imageUrl: String?) {
        guard let name = name, !name.isEmpty else {
            loading = false
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "alias.cannot.empty".localized)
            return
        }
        
        if let tribeInfo = tribeInfo {
            var params = groupsManager.getParamsFrom(tribe: tribeInfo)
            params["my_alias"] = name as AnyObject
            params["my_photo_url"] = (imageUrl ?? "") as AnyObject
            
            API.sharedInstance.joinTribe(params: params, callback: { chatJson in
                if let chat = Chat.insertChat(chat: chatJson) {
                    chat.pricePerMessage = NSDecimalNumber(floatLiteral: Double(tribeInfo.pricePerMessage ?? 0))
                    chat.saveChat()
                    
                    self.delegate?.shouldReloadContacts()
                    WindowsManager.sharedInstance.dismissViewFromCurrentWindow()
                } else {
                    self.showErrorAndDismiss()
                }
            }, errorCallback: {
                self.showErrorAndDismiss()
            })
        } else {
            showErrorAndDismiss()
        }
    }
}

extension JoinTribeViewController : TribeMemberInfoDelegate {
    func didUpdateUploadProgress(uploadString: String) {
        uploading = true
        uploadedLabel.stringValue = uploadString
    }
}
