//
//  NotificationsHelper.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 20/07/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation

class NotificationsHelper : NSObject {
    
    public enum NotificationType: Int {
        case BannerAndSound = 0
        case Banner = 1
        case Sound = 2
        case Off = 3
    }
    
    public struct Sound {
        var name : String
        var file : String
        var selected : Bool = false
        
        init(name: String, file: String, selected: Bool) {
            self.name = name
            self.file = file
            self.selected = selected
        }
    }
    
    var sounds = [Sound]()
    
    override init() {
        super.init()
        
        sounds.append(Sound(name: "TriTone (default)", file: "tri-tone.caf", selected: true))
        sounds.append(Sound(name: "Aurora", file: "aurora.caf", selected: false))
        sounds.append(Sound(name: "Bamboo", file: "bamboo.caf", selected: false))
        sounds.append(Sound(name: "Bell", file: "bell.caf", selected: false))
        sounds.append(Sound(name: "Bells", file: "bells.caf", selected: false))
        sounds.append(Sound(name: "Glass", file: "glass.caf", selected: false))
        sounds.append(Sound(name: "Horn", file: "horn.caf", selected: false))
        sounds.append(Sound(name: "Note", file: "note.caf", selected: false))
        sounds.append(Sound(name: "Popcorn", file: "popcorn.caf", selected: false))
        sounds.append(Sound(name: "Synth", file: "synth.caf", selected: false))
        sounds.append(Sound(name: "Tweet", file: "tweet.caf", selected: false))
    }
    
    func getFileFor(name: String?) -> String {
        let soundsName = name ?? "TriTone (default)"
        
        for sound in sounds {
            if sound.name == soundsName {
                return sound.file
            }
        }
        
        return sounds[0].file
    }
    
    func getNotificationType() -> Int {
        if let type = UserDefaults.Keys.notificationType.get(defaultValue: 0) {
            return type
        }
        return NotificationType.Banner.rawValue
    }
    
    func getNotificationSoundFile() -> String {
        if let sound = UserDefaults.Keys.notificationSound.get(defaultValue: "tri-tone.caf") {
            return sound
        }
        return sounds[0].file
    }
    
    func getNotificationSoundTag() -> Int {
        let file = getNotificationSoundFile()
        
        for i in 0..<sounds.count {
            let sound = sounds[i]
            if sound.file == file {
                return i
            }
        }
        
        return 0
    }
    
    func sendNotification(
        title: String,
        subtitle: String? = nil,
        text: String
    ) -> Void {
        if let notification = createNotificationFrom(
            title: title,
            subtitle: subtitle,
            text: text
        ) {
            sendNotification(notification)
            
            if shouldPlaySound() {
                SoundsPlayer.playSound(name: getNotificationSoundFile())
            }
        }
    }
    
    func sendNotification(message: TransactionMessage) -> Void {
        if isOff() {
            return
        }
        
        if TransactionMessage.typesToExcludeFromChat.contains(message.type) {
            return
        }
        
        if !message.shouldSendNotification() {
            return
        }
        
        if let notification = createNotificationFrom(message) {
            sendNotification(notification)
        }
        
        if shouldPlaySound() {
            SoundsPlayer.playSound(name: getNotificationSoundFile())
        }
    }
    
    func setNotificationType(tag: Int) {
        UserDefaults.Keys.notificationType.set(tag)
    }
    
    func setNotificationSound(tag: Int) {
        let sound = sounds[tag]
        UserDefaults.Keys.notificationSound.set(sound.file)
    }
    
    func isOff() -> Bool {
        return UserDefaults.Keys.notificationType.get(defaultValue: 0) == NotificationType.Off.rawValue
    }
    
    func shouldPlaySound() -> Bool {
        return UserDefaults.Keys.notificationType.get(defaultValue: 0) == NotificationType.Sound.rawValue ||
               UserDefaults.Keys.notificationType.get(defaultValue: 0) == NotificationType.BannerAndSound.rawValue
    }
    
    func shouldShowBanner() -> Bool {
        return UserDefaults.Keys.notificationType.get(defaultValue: 0) == NotificationType.Banner.rawValue ||
               UserDefaults.Keys.notificationType.get(defaultValue: 0) == NotificationType.BannerAndSound.rawValue
    }
    
    func createNotificationFrom(
        title: String,
        subtitle: String? = nil,
        text: String
    ) -> NSUserNotification? {
        let notification = NSUserNotification()
        
        notification.title = title
        
        if let subtitle = subtitle {
            notification.subtitle = subtitle
        }
        
        notification.informativeText = text
        
        return notification
    }
    
    func createNotificationFrom(_ message: TransactionMessage) -> NSUserNotification? {
        guard let owner = UserContact.getOwner() else {
            return nil
        }
        
        if shouldShowBanner() {
            let notification = NSUserNotification()
            
            let chatName = message.chat?.name ?? ""
            let chatId = message.chat?.id ?? -1
            
            let sender = message.getMessageSender()
            
            let senderNickName = message.getMessageSenderNickname(
                owner: owner,
                contact: sender
            )
            
            let messageDescription = message.getMessageContentPreview(
                owner: owner,
                contact: sender,
                includeSender: false
            )
            
            if message.chat?.isPublicGroup() ?? false {
                notification.title = message.chat?.getName() ?? ""
                notification.subtitle = senderNickName
            } else {
                notification.title = senderNickName
            }
            
            notification.informativeText = messageDescription
            notification.userInfo = ["chat-id" : chatId]
            notification.hasReplyButton = true
            notification.responsePlaceholder = "message.placeholder".localized

            if let sender = sender, let cachedImage = sender.getCachedImage() {
                notification.contentImage = cachedImage
            } else if let chat = message.chat, let cachedImage = chat.getCachedImage() {
                notification.contentImage = cachedImage
            }
            
            return notification
        }
        return nil
    }
    
    func sendNotification(_ notification: NSUserNotification) {
        NSUserNotificationCenter.default.delegate = self
        NSUserNotificationCenter.default.deliver(notification)
    }
}

extension NotificationsHelper : NSUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        if let chatId = notification.userInfo?["chat-id"] as? Int, chatId >= 0 {
            switch (notification.activationType) {
            case .contentsClicked:
                NotificationCenter.default.post(name: .chatNotificationClicked, object: nil, userInfo: notification.userInfo)
                break
            case .replied:
                guard let message = notification.response?.string, message.length > 0 else { return }
                let userInfo: [String: Any] = ["chat-id" : chatId, "message" : message.trunc(length: 500)]
                NotificationCenter.default.post(name: .chatNotificationClicked, object: nil, userInfo: userInfo)
                break
            default:
                break
            }
        }
    }
}
