//
//  ChatListViewController+TabsExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 06/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

extension ChatListViewController {
    enum DashboardTab: Int, Hashable {
        case friends
        case tribes
    }
}

extension ChatListViewController {
    
    func setActiveTab(
        _ tab: DashboardTab,
        loadData: Bool = true,
        shouldSwitchChat: Bool = true
    ) {
        let newViewController = mainContentViewController(forActiveTab: tab)

        addChildVC(
            child: newViewController,
            container: chatListVCContainer
        )
        
        if loadData {
            loadFriendAndReload()
        }
        
        if shouldSwitchChat {
            DispatchQueue.main.async {
                self.delegate?.didSwitchToTab()
            }
        }
    }
    
    var indicesOfTabsWithNewMessages: [Int] {
        var indices = [Int]()

        if contactsService.contactsHasNewMessages {
            indices.append(0)
        }
        
        if contactsService.chatsHasNewMessages {
            indices.append(1)
        }
        
        return indices
    }
    
    private func mainContentViewController(
        forActiveTab activeTab: DashboardTab
    ) -> NSViewController {
        switch activeTab {
        case .friends:
            return contactChatsContainerViewController
        case .tribes:
            return tribeChatsContainerViewController
        }
    }
    
    @objc func dataDidChange() {
        updateNewMessageBadges()
        
        contactChatsContainerViewController.updateWithNewChats(
            contactsService.contactListObjects
        )
        
        tribeChatsContainerViewController.updateWithNewChats(
            contactsService.chatListObjects
        )
    }
    
    internal func updateNewMessageBadges() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            
            self.dashboardNavigationTabs.indicesOfTitlesWithBadge = self.indicesOfTabsWithNewMessages
        }
    }
}
