//
//  StoryboardScenes.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 11/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

internal enum StoryboardScene {
    
    internal enum Main: StoryboardType {
        internal static let storyboardName = "Main"
        
        internal static let splashViewController = SceneType<SplashViewController>(storyboard: Main.self, identifier: "SplashViewController")
    }
    
    internal enum Pin: StoryboardType {
        internal static let storyboardName = "Pin"
        
        internal static let enterPinViewController = SceneType<EnterPinViewController>(storyboard: Pin.self, identifier: "EnterPinViewController")
        
        internal static let changePinViewController = SceneType<ChangePinViewController>(storyboard: Pin.self, identifier: "ChangePinViewController")
    }
    
    internal enum Invite: StoryboardType {
        internal static let storyboardName = "Invite"
        
        internal static let keychainRestoreViewController = SceneType<KeychainRestoreViewController>(storyboard: Invite.self, identifier: "KeychainRestoreViewController")
        
        internal static let shareInviteCodeViewController = SceneType<ShareInviteCodeViewController>(storyboard: Invite.self, identifier: "ShareInviteCodeViewController")
    }
    
    internal enum Dashboard: StoryboardType {
        internal static let storyboardName = "Dashboard"
        
        internal static let dashboardViewController = SceneType<DashboardViewController>(storyboard: Dashboard.self, identifier: "DashboardViewController")
        
        internal static let chatListViewController = SceneType<ChatListViewController>(storyboard: Dashboard.self, identifier: "ChatListViewController")
        
        internal static let chatViewController = SceneType<ChatViewController>(storyboard: Dashboard.self, identifier: "ChatViewController")
        
        internal static let createInvoiceViewController = SceneType<CreateInvoiceViewController>(storyboard: Dashboard.self, identifier: "CreateInvoiceViewController")
        
        internal static let sendPaymentViewController = SceneType<SendPaymentViewController>(storyboard: Dashboard.self, identifier: "SendPaymentViewController")
        
        internal static let paymentTemplatesViewController = SceneType<PaymentTemplatesViewController>(storyboard: Dashboard.self, identifier: "PaymentTemplatesViewController")
        
        internal static let contactViewController = SceneType<ContactViewController>(storyboard: Dashboard.self, identifier: "ContactViewController")
        
        internal static let webAppViewController = SceneType<WebAppViewController>(storyboard: Dashboard.self, identifier: "WebAppViewController")
    }
    
    internal enum Groups: StoryboardType {
        internal static let storyboardName = "Groups"
        
        internal static let groupMembersViewController = SceneType<GroupMembersViewController>(storyboard: Groups.self, identifier: "GroupMembersViewController")
        
        internal static let joinTribeViewController = SceneType<JoinTribeViewController>(storyboard: Groups.self, identifier: "JoinTribeViewController")
        
        internal static let groupDetailsViewController = SceneType<GroupDetailsViewController>(storyboard: Groups.self, identifier: "GroupDetailsViewController")
    }
    
    internal enum Profile: StoryboardType {
        internal static let storyboardName = "Profile"
        
        internal static let profileViewController = SceneType<ProfileViewController>(storyboard: Profile.self, identifier: "ProfileViewController")
    }
    
    internal enum Contacts: StoryboardType {
        internal static let storyboardName = "Contacts"
        
        internal static let addFriendViewController = SceneType<AddFriendViewController>(storyboard: Contacts.self, identifier: "AddFriendViewController")
        
        internal static let newContactViewController = SceneType<NewContactViewController>(storyboard: Contacts.self, identifier: "NewContactViewController")
        
        internal static let newInviteViewController = SceneType<NewInviteViewController>(storyboard: Contacts.self, identifier: "NewInviteViewController")
    }
    
    internal enum Signup: StoryboardType {
        internal static let storyboardName = "Signup"
        
        internal static let welcomeInitialViewController = SceneType<WelcomeInitialViewController>(storyboard: Signup.self, identifier: "WelcomeInitialViewController")
        
        internal static let welcomeCodeViewController = SceneType<WelcomeCodeViewController>(storyboard: Signup.self, identifier: "WelcomeCodeViewController")
        
        internal static let welcomeEmptyViewController = SceneType<WelcomeEmptyViewController>(storyboard: Signup.self, identifier: "WelcomeEmptyViewController")
        
        internal static let welcomeLightningViewController = SceneType<WelcomeLightningViewController>(storyboard: Signup.self, identifier: "WelcomeLightningViewController")
        
        internal static let welcomeMobileViewController = SceneType<WelcomeMobileViewController>(storyboard: Signup.self, identifier: "WelcomeMobileViewController")
    }
    
    internal enum Podcast: StoryboardType {
        internal static let storyboardName = "Podcast"
        
        internal static let newPodcastPlayerViewController = SceneType<NewPodcastPlayerViewController>(storyboard: Podcast.self, identifier: "NewPodcastPlayerViewController")
    }
}

internal protocol StoryboardType {
    static var storyboardName: String { get }
}

internal extension StoryboardType {
    static var storyboard: NSStoryboard {
        let name = self.storyboardName
        return NSStoryboard(name: name, bundle: Bundle(for: BundleToken.self))
    }
}

internal struct SceneType<T: NSViewController> {
    internal let storyboard: StoryboardType.Type
    internal let identifier: String

    internal func instantiate() -> T {
        let identifier = self.identifier
        let storyB = (storyboard.storyboard as NSStoryboard)
        guard let controller = storyB.instantiateController(withIdentifier: identifier) as? T else {
            fatalError("ViewController '\(identifier)' is not of the expected class \(T.self).")
        }
        return controller
    }
}

private final class BundleToken {}
