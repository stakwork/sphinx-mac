//
//  AppDelegate.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 10/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import CoreData
import SDWebImage

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let notificationsHelper = NotificationsHelper()
    var newMessageBubbleHelper = NewMessageBubbleHelper()
    
    let onionConnector = SphinxOnionConnector.sharedInstance
    
    var unlockTimer : Timer? = nil
    
    var statusBarItem: NSStatusItem!
    
    @IBOutlet weak var appearanceMenu: NSMenu!
    @IBOutlet weak var notificationTypeMenu: NSMenu!
    @IBOutlet weak var notificationSoundMenu: NSMenu!
    @IBOutlet weak var messagesSizeMenu: NSMenu!
    
    @IBOutlet weak var profileMenuItem: NSMenuItem!
    @IBOutlet weak var newContactMenuItem: NSMenuItem!
    @IBOutlet weak var createTribeMenuItem: NSMenuItem!
    @IBOutlet weak var logoutMenuItem: NSMenuItem!
    @IBOutlet weak var removeAccountMenuItem: NSMenuItem!
    
    
    public enum SphinxMenuButton: Int {
        case Profile = 0
        case NewContact = 1
        case Logout = 2
        case RemoveAccount = 3
        case CreateTribe = 4
    }
    
    var lastClearSDMemoryDate: Date? {
        get {
            return UserDefaults.Keys.clearSDMemoryDate.get(defaultValue: nil)
        }
        set {
            UserDefaults.Keys.clearSDMemoryDate.set(newValue)
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setAppSettings()
        
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.config.maxMemoryCount = 50
        
        addStatusBarItem()
        listenToSleepEvents()
        connectTor()
        getRelayKeys()
        
        setInitialVC()
    }
    
    func getRelayKeys() {
        if UserData.sharedInstance.isUserLogged() {
            UserData.sharedInstance.getAndSaveTransportKey()
            UserData.sharedInstance.getOrCreateHMACKey()
        }
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        if urls.count > 0 {
            for url in urls {
                DeepLinksHandlerHelper.handleLinkQueryFrom(url: url)
            }
        }
    }
    
    func connectTor() {
        if !SignupHelper.isLogged() { return }
        
        if !onionConnector.usingTor() {
            return
        }
        onionConnector.startIfNeeded()
    }

    
    func addStatusBarItem() {
        let statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem.button?.image = NSImage(named: "extraIconBadge")
        statusBarItem.button?.imageScaling = .scaleProportionallyDown
        statusBarItem.button?.action = #selector(activateApp)
    }
    
    @objc func activateApp() {
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func setAppSettings() {
        let savedAppearance = UserDefaults.Keys.appAppearance.get(defaultValue: 0)
        setAppearanceFrom(value: savedAppearance, shouldUpdate: false)
        
        let notificationType = UserDefaults.Keys.notificationType.get(defaultValue: 0)
        selectItemWith(tag: notificationType, in: notificationTypeMenu)
        
        let notificationSoundTag = notificationsHelper.getNotificationSoundTag()
        selectItemWith(tag: notificationSoundTag, in: notificationSoundMenu)
        
        let messagesSize = UserDefaults.Keys.messagesSize.get(defaultValue: 0)
        setMessagesSizeFrom(value: messagesSize)
    }
    
    
    func setAppMenuVisibility(shouldEnableItems: Bool) {
        [
            profileMenuItem,
            newContactMenuItem,
            logoutMenuItem,
            removeAccountMenuItem,
            createTribeMenuItem
        ]
        .forEach { $0?.isHidden = shouldEnableItems == false }
    }
    
    
    func setInitialVC() {
        if let mainWindow = getDashboardWindow() {
            mainWindow.replaceContentBy(vc: DashboardViewController.instantiate())
        } else {
            if UserData.sharedInstance.isUserLogged() {
                presentPIN()
            } else {
                let splashVC = SplashViewController.instantiate()
                let windowState = WindowsManager.sharedInstance.getWindowState()
                createKeyWindowWith(vc: splashVC, windowState: windowState, closeOther: false, hideBar: true)
            }
        }
    }
    
    func createKeyWindowWith(vc: NSViewController, windowState: WindowState, closeOther: Bool = false, hideBar: Bool = false) {
        if closeOther {
            for window in NSApplication.shared.windows {
                window.close()
            }
        }
        
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: Bundle.main)
        let window = storyboard.instantiateController(withIdentifier: "MainWindow") as! NSWindowController
        window.contentViewController = vc
        window.window?.title = "Sphinx"
        window.window?.styleMask = hideBar ? [.titled, .resizable, .miniaturizable, .fullSizeContentView] : [.titled, .resizable, .miniaturizable]
        window.window?.minSize = windowState.minSize
        window.window?.titlebarAppearsTransparent = hideBar
        window.window?.titleVisibility = hideBar ? .hidden : .visible
        window.window?.setFrame(windowState.frame, display: true)
        window.window?.makeKey()
        window.showWindow(self)
    }
    
    func getDashboardWindow() -> NSWindow? {
        for w in NSApplication.shared.windows {
            if let _ = w.contentViewController as? DashboardViewController {
                return w
            }
        }
        return nil
    }
    
    func listenToSleepEvents() {
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepListener(aNotification:)), name: NSWorkspace.didWakeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepListener(aNotification:)), name: .screenIsUnlocked, object: nil)
    }
    
    @objc func sleepListener(aNotification: NSNotification) {
        if (aNotification.name == NSWorkspace.didWakeNotification || aNotification.name == .screenIsUnlocked) && UserData.sharedInstance.isUserLogged() {
            SDImageCache.shared.clearMemory()
            
            unlockTimer?.invalidate()
            unlockTimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(reloadDataAndConnectSocket), userInfo: nil, repeats: false)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        SphinxSocketManager.sharedInstance.disconnectWebsocket()
        WindowsManager.sharedInstance.saveWindowState()
        CoreDataManager.sharedManager.saveContext()
    }
    
    func applicationWillBecomeActive(_ notification: Notification) {
        unlockTimer?.invalidate()
        unlockTimer = nil
        
        if GroupsPinManager.sharedInstance.shouldAskForPin() {
            presentPIN()
            return
        }
        
        if UserData.sharedInstance.isUserLogged() && !ChatListViewModel.isRestoreRunning() {
            reloadDataAndConnectSocket()
            FeedsManager.sharedInstance.restoreContentFeedStatusInBackground()
        }
    }
    
    func presentPIN() {
        setAppMenuVisibility(shouldEnableItems: false)
        CoreDataManager.sharedManager.resetContext()
        SDImageCache.shared.clearMemory()
        
        let pinVC = EnterPinViewController.instantiate(mode: .Launch)
        pinVC.doneCompletion = { pin in
            UserDefaults.Keys.lastPinDate.set(Date())
            self.setAppMenuVisibility(shouldEnableItems: true)
            self.loadDashboard()
        }
        createKeyWindowWith(vc: pinVC, windowState: WindowsManager.sharedInstance.getWindowState(), closeOther: true, hideBar: true)
    }
    
    func loadDashboard() {
        SplashViewController.runBackgroundProcesses()
        SphinxSocketManager.sharedInstance.connectWebsocket()
        createKeyWindowWith(vc: DashboardViewController.instantiate(), windowState: WindowsManager.sharedInstance.getWindowState(), closeOther: true)
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        if UserData.sharedInstance.isUserLogged() {
            NotificationCenter.default.post(name: .shouldReadChat, object: nil)
            
            setBadge(count: TransactionMessage.getReceivedUnseenMessagesCount())
            ActionsManager.sharedInstance.syncActionsInBackground()
            CoreDataManager.sharedManager.saveContext()
        }
    }
    
    @objc func reloadDataAndConnectSocket() {
        connectTor()
        SphinxSocketManager.sharedInstance.connectWebsocket()
        NotificationCenter.default.post(name: .shouldUpdateDashboard, object: nil)
    }
    
    func setBadge(count: Int) {
        statusBarItem.button?.image = NSImage(named: count > 0 ? "extraIconBadge" : "extraIcon")
        let title = count > 0 ? "\(count)" : ""
        NSApp.dockTile.badgeLabel = title
    }
    
    func sendNotification(message: TransactionMessage) -> Void {
        notificationsHelper.sendNotification(message: message)
    }
    
    @IBAction func appearenceButtonClicked(_ sender: NSMenuItem) {
        setAppearanceFrom(value: sender.tag, shouldUpdate: true)
        UserDefaults.Keys.appAppearance.set(sender.tag)
    }
    
    @IBAction func notificationTypeButtonClicked(_ sender: NSMenuItem) {
        notificationsHelper.setNotificationType(tag: sender.tag)
        selectItemWith(tag: sender.tag, in: notificationTypeMenu)
    }
    
    @IBAction func notificationSoundButtonClicked(_ sender: NSMenuItem) {
        notificationsHelper.setNotificationSound(tag: sender.tag)
        selectItemWith(tag: sender.tag, in: notificationSoundMenu)
        SoundsPlayer.playSound(name: notificationsHelper.getNotificationSoundFile())
    }
    
    @IBAction func messagesSizeButtonClicked(_ sender: NSMenuItem) {
        UserDefaults.Keys.messagesSize.set(sender.tag)
        setMessagesSizeFrom(value: sender.tag, reloadViews: true)
    }
    
    @IBAction func sphinxMenuButtonClicked(_ sender: NSMenuItem) {
        switch(sender.tag) {
        case SphinxMenuButton.Profile.rawValue:
            profileButtonClicked()
        case SphinxMenuButton.NewContact.rawValue:
            newContactButtonClicked()
        case SphinxMenuButton.CreateTribe.rawValue:
            createTribeButtonClicked()
        case SphinxMenuButton.Logout.rawValue:
            logoutButtonClicked()
        case SphinxMenuButton.RemoveAccount.rawValue:
            removeAccountButtonClicked()
        default:
            break
        }
    }
    
    func newContactButtonClicked() {
        if let dashboard = NSApplication.shared.keyWindow?.contentViewController as? DashboardViewController {
            dashboard.listViewController?.addContactButtonClicked(dashboard.view)
        }
    }
    
    func removeAccountButtonClicked() {
        setBadge(count: 0)
        
        AlertHelper.showTwoOptionsAlert(title: "logout".localized, message: "logout.text".localized, confirm: {
            UserData.sharedInstance.clearData()
            SphinxSocketManager.sharedInstance.clearSocket()
            
            let frame = WindowsManager.sharedInstance.getCenteredFrameFor(size: CGSize(width: 800, height: 500))
            let keyWindow = NSApplication.shared.keyWindow
            keyWindow?.styleMask = [.titled, .miniaturizable, .fullSizeContentView]
            keyWindow?.titleVisibility = .hidden
            keyWindow?.titlebarAppearsTransparent = true
            keyWindow?.replaceContentBy(vc: SplashViewController.instantiate())
            keyWindow?.setFrame(frame, display: true, animate: true)
        })
    }
    
    func logoutButtonClicked() {
        GroupsPinManager.sharedInstance.logout()
        presentPIN()
    }
    
    func profileButtonClicked() {
        if let profile = UserContact.getOwner(), profile.id > 0 {
            WindowsManager.sharedInstance.showProfileWindow(vc: ProfileViewController.instantiate(), window: NSApplication.shared.keyWindow)
        }
    }
    
    func createTribeButtonClicked() {
        let createTribeVC = CreateTribeViewController.instantiate()
        WindowsManager.sharedInstance.showCreateTribeWindow(title: "Create Tribe", vc: createTribeVC, window: NSApplication.shared.keyWindow)
    }
    
    func selectItemWith(tag: Int, in menu: NSMenu) {
        for item in menu.items {
            if item.tag == tag {
                item.state = .on
            } else {
                item.state = .off
            }
        }
    }
    
    func setAppearanceFrom(value: Int, shouldUpdate: Bool) {
        selectItemWith(tag: value, in: appearanceMenu)
        
        if #available(OSX 10.14, *) {
            if value <= 0 {
                NSApp.appearance = nil
            } else if value == 1 {
                NSApp.appearance = NSAppearance(named: .aqua)
            } else if value == 2 {
                NSApp.appearance = NSAppearance(named: .darkAqua)
            }
        }
        
        if shouldUpdate {
            DistributedNotificationCenter.default().post(name: .onInterfaceThemeChanged, object: nil)
        }
    }
    
    func setMessagesSizeFrom(value: Int, reloadViews: Bool = false) {
        selectItemWith(tag: value, in: messagesSizeMenu)
        Constants.setSize()
        
        if reloadViews {
            NotificationCenter.default.post(name: .shouldReloadViews, object: nil)
        }
    }
}

extension AppDelegate : SphinxOnionConnectorDelegate {
    func onionConnecting() {
        newMessageBubbleHelper.showGenericMessageView(text: "establishing.tor.circuit".localized)
    }
    
    func onionConnectionFinished() {
        newMessageBubbleHelper.hideLoadingWheel()
        
        SphinxSocketManager.sharedInstance.reconnectSocketOnTor()
        NotificationCenter.default.post(name: .shouldUpdateDashboard, object: nil)
    }
    
    func onionConnectionFailed() {
        newMessageBubbleHelper.hideLoadingWheel()
        newMessageBubbleHelper.showGenericMessageView(text: "tor.connection.failed".localized)
    }
}


