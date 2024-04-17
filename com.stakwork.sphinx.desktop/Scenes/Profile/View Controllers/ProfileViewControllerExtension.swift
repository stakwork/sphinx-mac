//
//  ProfileViewControllerExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 24/08/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

extension ProfileViewController {
    func shouldChangePIN() {
        let changePinCodeVC = ChangePinViewController.instantiate(mode: .ChangeStandard)
        changePinCodeVC.doneCompletion = { pin in
            if pin == UserData.sharedInstance.getPrivacyPin() {
                AlertHelper.showAlert(title: "generic.error.title".localized, message: "pins.must.be.different".localized)
                return
            }
            AlertHelper.showTwoOptionsAlert(title: "pin.change".localized, message: "confirm.pin.change".localized, confirm: {
                GroupsPinManager.sharedInstance.didUpdateStandardPin(newPin: pin)
                self.newMessageBubbleHelper.showGenericMessageView(text: "pin.changed".localized, in: self.view, delay: 6, backAlpha: 1.0)
                WindowsManager.sharedInstance.backToProfile()
            }, cancel: {
                WindowsManager.sharedInstance.backToProfile()
            })
        }
        advanceTo(vc: changePinCodeVC, title: "pin.change".localized, height: 500)
    }
    
    func shouldChangePrivacyPIN() {
        let isPrivacyPinSet = GroupsPinManager.sharedInstance.isPrivacyPinSet()
        let mode: ChangePinViewController.ChangePinMode = isPrivacyPinSet ? .ChangePrivacy : .SetPrivacy
        let changePivacyPinVC = ChangePinViewController.instantiate(mode: mode)
        changePivacyPinVC.doneCompletion = { pin in
            if pin == UserData.sharedInstance.getAppPin() {
                AlertHelper.showAlert(title: "generic.error.title".localized, message: "pins.must.be.different".localized)
                return
            }
            AlertHelper.showTwoOptionsAlert(title: "pin.change".localized, message: "confirm.privacy.pin.change".localized, confirm: {
                GroupsPinManager.sharedInstance.didUpdatePrivacyPin(newPin: pin)
                self.privacyPinButton.stringValue = "change.privacy.pin".localized
                let alertLabel = (isPrivacyPinSet ? "privacy.pin.changed" : "privacy.pin.set").localized
                self.newMessageBubbleHelper.showGenericMessageView(text: alertLabel, in: self.view, delay: 6, backAlpha: 1.0)
                WindowsManager.sharedInstance.backToProfile()
            }, cancel: {
                WindowsManager.sharedInstance.backToProfile()
            })
        }
        advanceTo(vc: changePivacyPinVC, title: "pin.change".localized, height: 500)
    }
    
    func updateRelayURL() -> Bool {
        let relayURL = serverURLField.stringValue
        
        if relayURL != UserData.sharedInstance.getNodeIP() {
            urlUpdateHelper.updateRelayURL(newValue: relayURL, view: self.view, completion: relayUpdateFinished)
            return true
        }
        return false
    }
    
    func relayUpdateFinished() {
        serverURLField.stringValue = UserData.sharedInstance.getNodeIP()
        updateProfile()
    }
    
    func uploadImage() {
        if let imgData = self.profileImage?.sd_imageData(as: .JPEG, compressionQuality: 0.5) {
            uploadingLabel.stringValue = String(format: "uploaded.progress".localized, 0)
            
            let attachmentsManager = AttachmentsManager.sharedInstance
            attachmentsManager.delegate = self
            
            let attachmentObject = AttachmentObject(data: imgData, type: AttachmentsManager.AttachmentType.Photo)
            attachmentsManager.uploadPublicImage(attachmentObject: attachmentObject)
        } else {
            updateProfile()
        }
    }
}

extension ProfileViewController : NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        saveEnabled = shouldEnableSaveButton()
    }
}

extension ProfileViewController : SettingsTabsDelegate {
    func didChangeSettingsTab(tag: Int) {
        let basicSelected = tag == SettingsTabsView.Tabs.Basic.rawValue
        basicSettingsView.isHidden = !basicSelected
        advancedSettingsView.isHidden = basicSelected
    }
}

extension ProfileViewController : DraggingViewDelegate {
    func imageDragged(image: NSImage) {
        profileImage = image
        profileImageView.image = image
        saveEnabled = shouldEnableSaveButton()
    }
}

extension ProfileViewController : AttachmentsManagerDelegate {
    func didUpdateUploadProgress(progress: Int) {
        let uploadedMessage = String(format: "uploaded.progress".localized, progress)
        uploadingLabel.stringValue = uploadedMessage
    }
    
    func didSuccessUploadingImage(url: String) {
        uploadingLabel.stringValue = ""
        
        if let image = profileImage {
            MediaLoader.storeImageInCache(img: image, url: url)
        }
        profileImageUrl = url
        updateProfile()
    }
}

extension ProfileViewController : PinTimeoutViewDelegate {
    func shouldEnableSave() {
        saveEnabled = true
    }
}
