//
//  ChatViewControllerPodcastExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 06/11/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

extension ChatViewController {
    func addPodcastVC(deeplinkData:DeeplinkData?=nil) {
        if let chat = chat, let contentFeed = chat.contentFeed, contentFeed.isPodcast {
            podcastContainerWidth.constant = DashboardViewController.kPodcastPlayerWidth
            podcastVCContainer.superview?.layoutSubtreeIfNeeded()
            
            podcastPlayerVC = NewPodcastPlayerViewController.instantiate(chat: chat, delegate: self)
            addChildVC(vc: podcastPlayerVC!)
        }
    }
    
    func addChildVC(vc: NSViewController) {
        self.addChild(vc)
        vc.view.frame = CGRect(x: 0, y: 0, width: podcastVCContainer.frame.width, height: podcastVCContainer.frame.height)
        podcastVCContainer.addSubview(vc.view)
        addConstraintTo(podcastVCView: vc.view)
        
        podcastVCContainer.isHidden = false
        delegate?.shouldToggleLeftView(show: nil)
        
        let _ = updateBottomBarHeight()
        chatMentionAutocompleteDataSource?.configureCollectionView()
    }
    
    func addConstraintTo(podcastVCView: NSView) {
        podcastVCContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: podcastVCContainer!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: podcastVCView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: podcastVCContainer!, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: podcastVCView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: podcastVCContainer!, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: podcastVCView, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: podcastVCContainer!, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: podcastVCView, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1.0, constant: 0.0).isActive = true
    }

    func removePodcastVC() {
        if let podcastPlayerVC = podcastPlayerVC {
            PodcastPlayerController.sharedInstance.finishAndSaveContentConsumed()
            
            podcastPlayerVC.view.removeFromSuperview()
            podcastPlayerVC.removeFromParent()
            self.podcastPlayerVC = nil
        }
        podcastContainerWidth.constant = 0
        podcastVCContainer.superview?.layoutSubtreeIfNeeded()
        delegate?.shouldToggleLeftView(show: nil)
    }
    
    func updateSatsEarned() {
        if let contentFeed = chat?.contentFeed, !contentFeed.feedID.isEmpty {
            let isMyTribe = (chat?.isMyPublicGroup() ?? false)
            let label = isMyTribe ? "earned.sats".localized : "contributed.sats".localized
            let sats = PodcastPaymentsHelper.getSatsEarnedFor(contentFeed.feedID)
            contributedSatsIcon.isHidden = false
            contributedSatsLabel.isHidden = false
        
            contributedSatsLabel.stringValue = String(format: label, sats)
        }
    }
}

extension ChatViewController : PodcastPlayerViewDelegate {
    func shouldShareClip(comment: PodcastComment) {
        messageReplyView.configureForKeyboard(with: comment, and: self)
        willReplay()
    }
    
    func shouldSendBoost(message: String, amount: Int, animation: Bool) -> TransactionMessage? {
        let boostType = TransactionMessage.TransactionMessageType.boost.rawValue
        return createProvisionalAndSend(messageText: message, type: boostType, botAmount: 0)
    }
    func shouldReloadEpisodesTable() {}
    func shouldSyncPodcast() {}
}
