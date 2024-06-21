//
//  NotificationLevelView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/09/2022.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Cocoa

class NotificationLevelView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!

    @IBOutlet weak var seeAllBox: NSBox!
    @IBOutlet weak var onlyMentionsBox: NSBox!
    @IBOutlet weak var muteChatBox: NSBox!
    
    @IBOutlet weak var seeAllDivider: NSBox!
    @IBOutlet weak var onlyMentionsDivider: NSBox!
    @IBOutlet weak var muteChatDivider: NSBox!
    
    @IBOutlet weak var seeAllLabel: NSTextField!
    @IBOutlet weak var onlyMentionsLabel: NSTextField!
    @IBOutlet weak var muteChatLabel: NSTextField!
    
    @IBOutlet weak var closeButton: CustomButton!
    
    var boxes: [NSBox] = []
    var dividers: [NSBox] = []
    var labels: [NSTextField] = []
    
    var notificationLevelOptions: [NotificationLevel] = [
        NotificationLevel(title: "see-all".localized, selected: true),
        NotificationLevel(title: "only-mentions".localized, selected: false),
        NotificationLevel(title: "mute-chat".localized, selected: false)
    ]
    
    struct NotificationLevel {
        var title = ""
        var selected = false
        
        init(title: String, selected: Bool) {
            self.title = title
            self.selected = selected
        }
    }
    
    var chat: Chat!
    
    var dismissBlock: (() -> ())? = nil
    
    func configureWith(chat: Chat, dismissBlock: @escaping () -> ()) {
        self.chat = chat
        self.dismissBlock = dismissBlock
        
        reloadViews(selectedLevel: chat.notify)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        
        closeButton.cursor = .pointingHand
        
        boxes = [seeAllBox, onlyMentionsBox, muteChatBox]
        dividers = [seeAllDivider, onlyMentionsDivider, muteChatDivider]
        labels = [seeAllLabel, onlyMentionsLabel, muteChatLabel]
    }
    
    @IBAction func closeButtonClicked(_ sender: CustomButton) {
        dismissBlock?()
    }
    
    @IBAction func buttonClicked(_ sender: NSButton) {
        setChatNotificationLevel(sender.tag)
        
        for (index, value) in notificationLevelOptions.enumerated() {
            let currentLevel = value
            notificationLevelOptions[index] = NotificationLevel(title: currentLevel.title, selected: sender.tag == index)
        }
        
        reloadViews(selectedLevel: sender.tag)
    }
    
    func setChatNotificationLevel(_ level: Int) {
        API.sharedInstance.setNotificationLevel(chatId: chat.id, level: level, callback: { chatJson in
            if let updatedChat = Chat.insertChat(chat: chatJson) {
                self.chat = updatedChat
            }
            self.configureViewFromChat()
        }, errorCallback: {
            self.configureViewFromChat()
        })
    }
    
    func configureViewFromChat() {
        for (index, value) in notificationLevelOptions.enumerated() {
            let currentLevel = value
            notificationLevelOptions[index] = NotificationLevel(title: currentLevel.title, selected: chat.notify == index)
        }
        reloadViews(selectedLevel: chat.notify)
    }
    
    func reloadViews(selectedLevel: Int) {
        for (index, divider) in dividers.enumerated() {
            let selected = index == selectedLevel
            divider.fillColor = selected ? NSColor.Sphinx.PrimaryBlue : NSColor.Sphinx.LightDivider
        }
        
        for (index, label) in labels.enumerated() {
            let selected = index == selectedLevel
            label.textColor = selected ? NSColor.Sphinx.Text : NSColor.Sphinx.SecondaryText
        }
    }
}
