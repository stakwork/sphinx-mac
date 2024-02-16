//
//  PeopleTorActionsView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 05/01/2022.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Cocoa
import SwiftyJSON

class PeopleTorActionsView: CommonModalView, LoadableNib {
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var viewTitleLabel: NSTextField!
    @IBOutlet weak var hostLabel: NSTextField!
    @IBOutlet weak var loadingWheelContainer: NSBox!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    
    let kSaveRequestMethod = "POST"
    let kDeleteRequestMethod = "DELETE"
    
    let kSaveProfilePath = "profile"
    let kClaimOnLiquidPath = "claim_on_liquid"
    
    var loading = false {
        didSet {
            loadingWheelContainer.isHidden = !loading
            
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.white, controls: [])
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        loadingWheelContainer.alphaValue = 0.0
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    override func modalWillShowWith(query: String, delegate: ModalViewDelegate) {
        super.modalWillShowWith(query: query, delegate: delegate)
        
        processQuery()
        
        hostLabel.stringValue = "\(authInfo?.host ?? "...")?"
    }
    
    private func showErrorAlertAndDismiss(_ error: String) {
        messageBubbleHelper.showGenericMessageView(text: error, textColor: NSColor.white, backColor: NSColor.Sphinx.BadgeRed, backAlpha: 1.0)
        
        DelayPerformedHelper.performAfterDelay(seconds: 2.0, completion: {
            self.delegate?.shouldDismissModals()
        })
    }
    
    private func showAlertAndDismiss(_ message: String) {
        messageBubbleHelper.showGenericMessageView(text: message)
        
        DelayPerformedHelper.performAfterDelay(seconds: 2.0, completion: {
            self.delegate?.shouldDismissModals()
        })
    }
    
    override func modalDidShow() {
        super.modalDidShow()
        
        loading = true
        
        guard let host = authInfo?.host, let key = authInfo?.key, !host.isEmpty && !key.isEmpty else {
            showErrorAlertAndDismiss("people.save-failed".localized)
            return
        }
        
        API.sharedInstance.getExternalRequestByKey(host: host, key: key, callback: { (success, json) in
            guard let json = json, success else {
                self.showErrorAlertAndDismiss("people.save-failed".localized)
                return
            }
            
            let path = json["path"].string
            let method = json["method"].string
            let jsonBody = JSON.init(parseJSON: json["body"].stringValue)
            
            guard path == "profile" else {
                self.showErrorAlertAndDismiss("people.save-failed".localized)
                return
            }
            
            self.authInfo?.jsonBody = jsonBody
            self.authInfo?.updateMethod = method
            self.authInfo?.path = path
            
            switch(path) {
            case self.kSaveProfilePath:
                switch (method) {
                case self.kSaveRequestMethod:
                    self.presentSaveModal()
                case self.kDeleteRequestMethod:
                    self.presentDeleteModal()
                default:
                    break
                }
            case self.kClaimOnLiquidPath:
                self.presentClaimOnLiquidModal()
            default:
                break
            }
        })
    }
    
    private func setDefaultModalInfo() {
        loading = false
        hostLabel.stringValue = authInfo?.host ?? ""
    }
    
    private func presentSaveModal() {
        setDefaultModalInfo()
        
        viewTitleLabel.stringValue = "people.save-profile".localized
    }
    
    private func presentDeleteModal() {
        setDefaultModalInfo()
        
        viewTitleLabel.stringValue = "people.delete-profile".localized
    }
    
    private func presentClaimOnLiquidModal() {
        setDefaultModalInfo()
        
        viewTitleLabel.stringValue = "people.claim-on-liquid".localized
    }

    
    private func saveProfile() {
        var parameters = [String : AnyObject]()
        parameters["id"] = authInfo?.jsonBody["id"].intValue as AnyObject
        parameters["host"] = authInfo?.jsonBody["host"].stringValue as AnyObject
        parameters["owner_alias"] = authInfo?.jsonBody["owner_alias"].stringValue as AnyObject
        parameters["description"] = authInfo?.jsonBody["description"].stringValue as AnyObject
        parameters["img"] = authInfo?.jsonBody["img"].stringValue as AnyObject
        parameters["price_to_meet"] = authInfo?.jsonBody["price_to_meet"].intValue as AnyObject
        parameters["tags"] = (authInfo?.jsonBody["tags"].arrayValue as NSArray?) as AnyObject
        
        if let tags = authInfo?.jsonBody["tags"].arrayValue as NSArray? {
            parameters["tags"] = tags as AnyObject
        }
        
        if let extras = authInfo?.jsonBody["extras"].dictionaryObject as NSDictionary? {
            parameters["extras"] = extras as AnyObject
        }
        
        API.sharedInstance.savePeopleProfile(
            params: parameters,
            callback: { success in
                
            if success {
                self.showAlertAndDismiss("people.save-succeed".localized)
            } else {
                self.showErrorAlertAndDismiss("people.save-failed".localized)
            }
        })
    }
    
    private func deleteProfile() {
        var parameters = [String : AnyObject]()
        parameters["id"] = authInfo?.jsonBody["id"].intValue as AnyObject
        parameters["host"] = authInfo?.jsonBody["host"].stringValue as AnyObject
        
        API.sharedInstance.deletePeopleProfile(
            params: parameters,
            callback: { success in
                
            if success {
                self.showAlertAndDismiss("people.delete-succeed".localized)
            } else {
                self.showErrorAlertAndDismiss("people.delete-failed".localized)
            }
        })
    }
    
    private func redeemBadgeTokens() {
        var parameters = [String : AnyObject]()
        parameters["host"] = authInfo?.jsonBody["host"].stringValue as AnyObject
        parameters["amount"] = authInfo?.jsonBody["amount"].intValue as AnyObject
        parameters["to"] = authInfo?.jsonBody["to"].stringValue as AnyObject
        parameters["asset"] = authInfo?.jsonBody["asset"].intValue as AnyObject
        parameters["memo"] = authInfo?.jsonBody["memo"].stringValue as AnyObject
        
        API.sharedInstance.redeemBadgeTokens(
            params: parameters,
            callback: { success in
                
            if success {
                self.showAlertAndDismiss("people.claim-on-liquid-succeed".localized)
            } else {
                self.showErrorAlertAndDismiss("people.claim-on-liquid-failed".localized)
            }
        })
    }

    
    override func didTapConfirmButton() {
        super.didTapConfirmButton()
        
        if let path = authInfo?.path {
            if let method = authInfo?.updateMethod {
                switch(path) {
                case self.kSaveProfilePath:
                    switch (method) {
                    case self.kSaveRequestMethod:
                        self.saveProfile()
                    case self.kDeleteRequestMethod:
                        self.deleteProfile()
                    default:
                        break
                    }
                case self.kClaimOnLiquidPath:
                    self.redeemBadgeTokens()
                default:
                    break
                }
            }
        }
    }
}
