//
//  GroupPinView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 12/01/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol GroupPinViewDelegate: AnyObject {
    func pinDidChange()
}

class GroupPinView: NSView, LoadableNib {
    
    weak var delegate: GroupPinViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var toggle: NSSegmentedControl!
    
    enum Segments: Int {
        case Standard
        case Private
    }
    
    var view: NSView? = nil
    var contact: UserContact? = nil
    var chat: Chat? = nil
    var didChangePin = false
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        
        let privacyPinSet = GroupsPinManager.sharedInstance.isPrivacyPinSet()
        toggle.isEnabled = privacyPinSet
        contentView.alphaValue = privacyPinSet ? 1.0 : 0.7
    }
    
    func configureWith(view: NSView, contact: UserContact? = nil, chat: Chat? = nil, delegate: GroupPinViewDelegate? = nil) {
        self.view = view
        self.delegate = delegate
        self.contact = contact
        self.chat = chat
        
        if let contact = contact {
            toggle.selectedSegment = (contact.pin ?? "").isEmpty ? 0 : 1
        } else if let chat = chat {
            toggle.selectedSegment = (chat.pin ?? "").isEmpty ? 0 : 1
        }
    }
    
    @IBAction func helpButtonClicked(_ sender: Any) {
        NewMessageBubbleHelper().showGenericMessageView(text: "privacy.pin.tooltip".localized, in: view, delay: 5, backAlpha: 1.0)
    }
    
    @IBAction func toggleValueChanged(_ sender: NSSegmentedControl) {
        didChangePin = true
        
        if let privacyPin = UserData.sharedInstance.getPrivacyPin(), !privacyPin.isEmpty {
            let privateObject = isPrivateEnabled()
            setObjectPrivate(pin: privateObject ? privacyPin : nil)
        }
        
        delegate?.pinDidChange()
    }
    
    func setObjectPrivate(pin: String? = nil) {
        self.contact?.pin = pin
        self.contact?.getConversation()?.pin = pin
        
        self.chat?.pin = pin
    
        CoreDataManager.sharedManager.saveContext()
        
        NotificationCenter.default.post(name: .shouldResetChat, object: nil)
    }
    
    func getPin() -> String? {
        if let privacyPin = UserData.sharedInstance.getPrivacyPin(), !privacyPin.isEmpty, isPrivateEnabled() {
            return privacyPin
        }
        return nil
    }
    
    func isPrivateEnabled() -> Bool {
        return toggle.selectedSegment == 1
    }
}
