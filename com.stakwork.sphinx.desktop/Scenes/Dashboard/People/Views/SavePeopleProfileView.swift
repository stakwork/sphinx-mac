//
//  SavePeopleProfileView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 05/01/2022.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Cocoa
import SwiftyJSON

class SavePeopleProfileView: CommonModalView, LoadableNib {
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var viewTitleLabel: NSTextField!
    @IBOutlet weak var hostLabel: NSTextField!
    @IBOutlet weak var loadingWheelContainer: NSBox!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    
    let kSaveRequestMethod = "POST"
    let kDeleteRequestMethod = "DELETE"
    
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
        
        API.sharedInstance.getProfileByKey(host: host, key: key, callback: { (success, json) in
            guard let json = json, success else {
                self.showErrorAlertAndDismiss("people.save-failed".localized)
                return
            }
            
            let path = json["path"].string
            let method = json["method"].string
            let profile = JSON.init(parseJSON: json["body"].stringValue)
            
            guard path == "profile" else {
                self.showErrorAlertAndDismiss("people.save-failed".localized)
                return
            }
            
            self.authInfo?.personInfo = profile
            self.authInfo?.updateMethod = method
            
            switch (method) {
            case self.kSaveRequestMethod:
                self.presentSaveModal()
            case self.kDeleteRequestMethod:
                self.presentDeleteModal()
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
    
    private func saveProfile() {
        var parameters = [String : AnyObject]()
        parameters["id"] = authInfo?.personInfo["id"].intValue as AnyObject
        parameters["host"] = authInfo?.personInfo["host"].stringValue as AnyObject
        parameters["owner_alias"] = authInfo?.personInfo["owner_alias"].stringValue as AnyObject
        parameters["description"] = authInfo?.personInfo["description"].stringValue as AnyObject
        parameters["img"] = authInfo?.personInfo["img"].stringValue as AnyObject
        parameters["price_to_meet"] = authInfo?.personInfo["price_to_meet"].intValue as AnyObject
        parameters["tags"] = (authInfo?.personInfo["tags"].arrayValue as NSArray?) as AnyObject
        
        if let tags = authInfo?.personInfo["tags"].arrayValue as NSArray? {
            parameters["tags"] = tags as AnyObject
        }
        
        if let extras = authInfo?.personInfo["extras"].dictionaryObject as NSDictionary? {
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
        parameters["id"] = authInfo?.personInfo["id"].intValue as AnyObject
        parameters["host"] = authInfo?.personInfo["host"].stringValue as AnyObject
        
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
    
    override func didTapConfirmButton() {
        super.didTapConfirmButton()
        
        if let method = authInfo?.updateMethod {
            switch (method) {
            case kSaveRequestMethod:
                self.saveProfile()
            case kDeleteRequestMethod:
                self.deleteProfile()
            default:
                break
            }
        }
    }
}
