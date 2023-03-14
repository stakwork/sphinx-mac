//
//  GroupsPinManager.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 11/01/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Foundation

class GroupsPinManager {

    class var sharedInstance : GroupsPinManager {
        struct Static {
            static let instance = GroupsPinManager()
        }
        return Static.instance
    }
    
    var userData = UserData.sharedInstance
    
    var currentPin : String {
        get {
            return userData.getCurrentSessionPin()
        }
        set {
            userData.save(currentSessionPin: newValue)
        }
    }
    
    var isStandardPIN : Bool {
        get {
            return currentPin == userData.getAppPin() || currentPin.isEmpty
        }
    }
    
    func shouldAskForPin() -> Bool {
        if !UserData.sharedInstance.isUserLogged() || UserData.sharedInstance.getPINNeverOverride() {
            return false
        }
        if let date: Date = UserDefaults.Keys.lastPinDate.get() {
            let timeSeconds = Double(UserData.sharedInstance.getPINHours() * 3600)
            if Date().timeIntervalSince(date) > timeSeconds {
                return true
            }
        }
        return currentPin.isEmpty
    }
    
    var shouldAvoidFaceID : Bool {
        get {
            return currentPin.isEmpty || currentPin == userData.getPrivacyPin()
        }
    }
    
    func setCurrentPin(_ pin: String) {
        self.currentPin = pin
    }
    
    func setCurrentPinOnUpdate(changingStandard: Bool, isOnStandard: Bool, pin: String) {
        if changingStandard && isOnStandard {
            setCurrentPin(pin)
        } else if !changingStandard && !isOnStandard {
            setCurrentPin(pin)
        }
    }
    
    func isPrivacyPinSet() -> Bool {
        if let privacyPin = userData.getPrivacyPin(), !privacyPin.isEmpty {
            return true
        }
        return false
    }
    
    func didUpdatePrivacyPin(newPin: String) {
        let isOnStandardMode = GroupsPinManager.sharedInstance.isStandardPIN
        UserData.sharedInstance.save(privacyPin: newPin)
        setCurrentPinOnUpdate(changingStandard: false, isOnStandard: isOnStandardMode, pin: newPin)
        
        if let privacyPin = userData.getPrivacyPin(), !privacyPin.isEmpty {
            for contact in UserContact.getPrivateContacts() {
                contact.pin = privacyPin
            }
            for chat in Chat.getPrivateChats() {
                chat.pin = privacyPin
            }
            CoreDataManager.sharedManager.saveContext()
        }
    }
    
    func didUpdateStandardPin(newPin: String) {
        let isOnStandardMode = GroupsPinManager.sharedInstance.isStandardPIN
        UserData.sharedInstance.save(pin: newPin)
        GroupsPinManager.sharedInstance.setCurrentPinOnUpdate(changingStandard: true, isOnStandard: isOnStandardMode, pin: newPin)
    }
    
    func isValidPin(_ pin: String) -> Bool {
        if let savedPin = userData.getAppPin(), !savedPin.isEmpty, savedPin == pin {
            setCurrentPin(pin)
            return true
        }
        
        if let savedPrivacyPin = userData.getPrivacyPin(), !savedPrivacyPin.isEmpty, savedPrivacyPin == pin {
            setCurrentPin(pin)
            return true
        }
        
        return false
    }
    
    func loginPin() {
        if let savedPin = userData.getAppPin(), !savedPin.isEmpty {
            setCurrentPin(savedPin)
        }
    }
    
    func logout() {
        setCurrentPin("")
    }
}

