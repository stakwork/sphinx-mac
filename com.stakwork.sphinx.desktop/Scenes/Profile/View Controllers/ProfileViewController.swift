//
//  ProfileViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 24/08/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class ProfileViewController: NSViewController {
    
    @IBOutlet weak var profileImageView: AspectFillNSImageView!
    @IBOutlet weak var profilePictureDraggingView: DraggingDestinationView!
    @IBOutlet weak var uploadingLabel: NSTextField!
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var balanceLabel: NSTextField!
    
    @IBOutlet weak var settingsTabsView: SettingsTabsView!
    @IBOutlet weak var basicSettingsView: NSView!
    @IBOutlet weak var advancedSettingsView: NSView!
    
    @IBOutlet weak var basicBox1: NSBox!
    @IBOutlet weak var basicBox2: NSBox!
    @IBOutlet weak var basicBox3: NSBox!
    @IBOutlet weak var settingsBox1: NSBox!
    @IBOutlet weak var pinTimeoutBox: NSBox!
    @IBOutlet weak var changePinBox: NSBox!
    @IBOutlet weak var changePrivacyPinBox: NSBox!
    @IBOutlet weak var setupSignerBox: NSBox!
    @IBOutlet weak var disconnectMQTTBox: NSBox!
    
    @IBOutlet weak var userNameField: NSTextField!
    @IBOutlet weak var addressField: NSTextField!
    @IBOutlet weak var routeHintField: NSTextField!
    @IBOutlet weak var qrButton: CustomButton!
    
    @IBOutlet weak var sharePhotoSwitchContainer: NSBox!
    @IBOutlet weak var sharePhotoSwitchCircle: NSBox!
    @IBOutlet weak var sharePhotoSwitchCircleLeading: NSLayoutConstraint!
    @IBOutlet weak var sharePhotoSwitchButton: CustomButton!
    
    @IBOutlet weak var trackActionsSwitchContainer: NSBox!
    @IBOutlet weak var trackActionsSwitchCircle: NSBox!
    @IBOutlet weak var trackActionsSwitchCircleLeading: NSLayoutConstraint!
    @IBOutlet weak var trackActionsSwitchButton: CustomButton!
    
    @IBOutlet weak var meetingServerField: NSTextField!
    @IBOutlet weak var meetingAmountField: NSTextField!
    @IBOutlet weak var serverURLField: NSTextField!
    @IBOutlet weak var exportKeysButton: CustomButton!
    @IBOutlet weak var privacyPinButton: CustomButton!
    @IBOutlet weak var pinTimeoutView: PinTimeoutView!
    
    @IBOutlet weak var saveButtonContainer: NSView!
    @IBOutlet weak var saveButton: CustomButton!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    
    let kSwitchOnLeading: CGFloat = 25
    let kSwitchOffLeading: CGFloat = 2
    
    var walletBalanceService = WalletBalanceService()
    let newMessageBubbleHelper = NewMessageBubbleHelper()
    let urlUpdateHelper = RelayURLUpdateHelper()
    
    let profile = UserContact.getOwner()
    var profileImage: NSImage? = nil
    var profileImageUrl: String? = nil
    
    var saveEnabled = false {
        didSet {
            saveButtonContainer.alphaValue = saveEnabled ? 1.0 : 0.7
            saveButton.isEnabled = saveEnabled
        }
    }
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.white, controls: [saveButton])
        }
    }
    
    static func instantiate() -> ProfileViewController {
        let viewController = StoryboardScene.Profile.profileViewController.instantiate()
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureProfile()
    }
    
    func configureView() {
        pinTimeoutView.delegate = self
        settingsTabsView.delegate = self
        
        qrButton.cursor = .pointingHand
        
        profileImageView.wantsLayer = true
        profileImageView.rounded = true
        profileImageView.layer?.cornerRadius = profileImageView.frame.height / 2
        
        profilePictureDraggingView.configureForProfilePicture()
        profilePictureDraggingView.delegate = self
        profilePictureDraggingView.setup()
        
        saveButtonContainer.addShadow(location: .bottom, opacity: 0.5, radius: 2.0)
        
        basicBox1.addShadow(location: VerticalLocation.center, color: NSColor.black, opacity: 0.2, radius: 2.0)
        basicBox2.addShadow(location: VerticalLocation.center, color: NSColor.black, opacity: 0.2, radius: 2.0)
        basicBox3.addShadow(location: VerticalLocation.center, color: NSColor.black, opacity: 0.2, radius: 2.0)
        settingsBox1.addShadow(location: VerticalLocation.center, color: NSColor.black, opacity: 0.2, radius: 2.0)
        pinTimeoutBox.addShadow(location: VerticalLocation.center, color: NSColor.black, opacity: 0.2, radius: 2.0)
        changePinBox.addShadow(location: VerticalLocation.center, color: NSColor.black, opacity: 0.2, radius: 2.0)
        changePrivacyPinBox.addShadow(location: VerticalLocation.center, color: NSColor.black, opacity: 0.2, radius: 2.0)
        
        sharePhotoSwitchContainer.wantsLayer = true
        sharePhotoSwitchCircle.wantsLayer = true
        sharePhotoSwitchContainer.layer?.cornerRadius = sharePhotoSwitchContainer.frame.size.height / 2
        sharePhotoSwitchCircle.layer?.cornerRadius = sharePhotoSwitchCircle.frame.size.height / 2
        
        trackActionsSwitchContainer.wantsLayer = true
        trackActionsSwitchCircle.wantsLayer = true
        trackActionsSwitchContainer.layer?.cornerRadius = trackActionsSwitchContainer.frame.size.height / 2
        trackActionsSwitchCircle.layer?.cornerRadius = trackActionsSwitchCircle.frame.size.height / 2
        
        sharePhotoSwitchButton.cursor = .pointingHand
        trackActionsSwitchButton.cursor = .pointingHand
        exportKeysButton.cursor = .pointingHand
        saveButton.cursor = .pointingHand
        privacyPinButton.cursor = .pointingHand
        
        userNameField.delegate = self
        meetingServerField.delegate = self
        meetingAmountField.delegate = self
        serverURLField.delegate = self
    }
    
    func configureProfile() {
        saveEnabled = false
        loading = false
        
        walletBalanceService.updateBalance(labels: [balanceLabel])
        
        if let profile = profile {
            if let imageUrl = profile.avatarUrl?.trim(), imageUrl != "" {
                MediaLoader.loadAvatarImage(url: imageUrl, objectId: profile.id, completion: { (image, id) in
                    guard let image = image else {
                        return
                    }
                    self.profileImageView.bordered = false
                    self.profileImageView.image = image
                })
            } else {
                profileImageView.image = NSImage(named: "profileAvatar")
            }
            
            toggleSharePhotoSwitch(on: !profile.privatePhoto)
            toggleActionsTrackingSwitch(on: UserDefaults.Keys.shouldTrackActions.get(defaultValue: false))
            
            let nickname = profile.nickname ?? ""
            nameLabel.stringValue = nickname.getNameStyleString()
            userNameField.stringValue = nickname.capitalized
            
            if let pubKey = profile.publicKey, !pubKey.isEmpty {
                addressField.stringValue = pubKey
                addressField.isEditable = false
            }
            
            if let routeHint = profile.routeHint, !routeHint.isEmpty {
                routeHintField.stringValue = routeHint
                routeHintField.isEditable = false
            }
            
            meetingServerField.stringValue = API.kVideoCallServer
            meetingAmountField.stringValue = "\(UserContact.kTipAmount)"
            privacyPinButton.stringValue = (GroupsPinManager.sharedInstance.isPrivacyPinSet() ? "change.privacy.pin" : "set.privacy.pin").localized
        }
        
        serverURLField.stringValue = UserData.sharedInstance.getNodeIP()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.makeFirstResponder(nil)
    }
    
    func shouldEnableSaveButton() -> Bool {
        return didUpdateProfile()
    }
    
    @IBAction func qrCodeButtonClicked(_ sender: Any) {
        if let profile = UserContact.getOwner(), let address = profile.getAddress(), !address.isEmpty {
            let shareInviteCodeVC = ShareInviteCodeViewController.instantiate(qrCodeString: address, viewMode: .PubKey)
            advanceTo(vc: shareInviteCodeVC, title: "pubkey.upper".localized.localizedCapitalized, height: 600)
        }
    }
    
    @IBAction func sharePhotoSwitchButtonClicked(_ sender: Any) {
        toggleSharePhotoSwitch(on: !isPhotoSwitchOn())
        saveEnabled = shouldEnableSaveButton()
    }
    
    func toggleSharePhotoSwitch(on: Bool) {
        sharePhotoSwitchCircleLeading.constant = on ? kSwitchOnLeading : kSwitchOffLeading
        sharePhotoSwitchContainer.fillColor = on ? NSColor.Sphinx.PrimaryBlue : NSColor.Sphinx.MainBottomIcons
    }
    
    func isPhotoSwitchOn() -> Bool {
        return sharePhotoSwitchCircleLeading.constant == kSwitchOnLeading
    }
    
    @IBAction func trackActionsSwitchButtonClicked(_ sender: Any) {
        toggleActionsTrackingSwitch(on: !isTrackActionsSwitchOn())
        saveEnabled = shouldEnableSaveButton()
    }
    
    func toggleActionsTrackingSwitch(on: Bool) {
        trackActionsSwitchCircleLeading.constant = on ? kSwitchOnLeading : kSwitchOffLeading
        trackActionsSwitchContainer.fillColor = on ? NSColor.Sphinx.PrimaryBlue : NSColor.Sphinx.MainBottomIcons
    }
    
    func isTrackActionsSwitchOn() -> Bool {
        return trackActionsSwitchCircleLeading.constant == kSwitchOnLeading
    }
    
    @IBAction func exportKeysButtonClicked(_ sender: Any) {
        let subtitle = "pin.keys.encryption".localized
        
        let pinCodeVC = EnterPinViewController.instantiate(mode: .Export, subtitle: subtitle)
        pinCodeVC.doneCompletion = { pin in
            if let keyJSONString = UserData.sharedInstance.exportKeysJSON(pin: pin) {
                WindowsManager.sharedInstance.backToProfile()
                
                if let mnemonic = UserData.sharedInstance.getMnemonic() {
                    SphinxOnionManager.sharedInstance.vc = self
                    SphinxOnionManager.sharedInstance.showMnemonicToUser(mnemonic: mnemonic, callback: {})
                    SphinxOnionManager.sharedInstance.vc = nil
                } else {
                    AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
                }
            } else {
                AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
            }
        }
        advanceTo(vc: pinCodeVC, title: "enter.restore.pin".localized, height: 440)
    }
    
    func advanceTo(
        vc: NSViewController,
        title: String,
        height: CGFloat? = nil
    ) {
        WindowsManager.sharedInstance.showOnCurrentWindow(
            with: title,
            identifier: "enter-restore-pin-window",
            contentVC: vc,
            hideDivider: true,
            hideBackButton: false,
            replacingVC: true,
            height: height,
            backHandler: WindowsManager.sharedInstance.backToProfile
        )
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        uploadImage()
    }
    
    @IBAction func addressButtonClicked(_ sender: Any) {
        copyAddress()
    }
    
    @IBAction func routeHintButtonClicked(_ sender: Any) {
        copyAddress()
    }
    
    func getAddress() -> String? {
        if addressField.stringValue.isEmpty {
            let routeHint = routeHintField.stringValue.isEmpty ? "" : ":\(routeHintField.stringValue)"
            return "\(addressField.stringValue)\(routeHint)"
        }
        return nil
    }
    
    func copyAddress() {
        if let address = getAddress() {
            ClipboardHelper.copyToClipboard(text: address, message: "address.copied.clipboard".localized)
        }
    }
    
    @IBAction func changePinButtonClicked(_ sender: Any) {
        shouldChangePIN()
    }
    
    @IBAction func privacyPinButtonClicked(_ sender: Any) {
        shouldChangePrivacyPIN()
    }
    
    func updateProfile() {
        loading = true
        
        if updateRelayURL() {
            return
        }
        
        guard let profile = profile else {
            return
        }
        
        if !didUpdateProfile() {
            configureProfile()
            return
        }
        
        updatePinSettings()
        UserDefaults.Keys.shouldTrackActions.set(isTrackActionsSwitchOn())
        
        var parameters = [String : AnyObject]()
        parameters["alias"] = userNameField.stringValue as AnyObject?
        parameters["private_photo"] = !isPhotoSwitchOn() as AnyObject?
        parameters["route_hint"] = routeHintField.stringValue as AnyObject?
        
        let tempTip = self.meetingAmountField.integerValue
        
        if let photoUrl = profileImageUrl, !photoUrl.isEmpty {
            parameters["photo_url"] = photoUrl as AnyObject?
        }
        
        API.sharedInstance.updateUser(id: profile.id, params: parameters, callback: { contact in
            API.kVideoCallServer = self.meetingServerField.stringValue
            let _ = UserContactsHelper.insertContact(contact: contact)
            UserContact.kTipAmount = tempTip
            self.saveFinished(success: true)
        }, errorCallback: {
            self.saveFinished(success: false)
        })
    }
    
    func updatePinSettings(){
        UserData.sharedInstance.setPINHours(hours: pinTimeoutView.getPinHours())
    }
    
    func didUpdateProfile() -> Bool {
        let didChangeName = userNameField.stringValue != (profile?.nickname ?? "")
        let didChangeRouteHint = routeHintField.stringValue != (profile?.routeHint ?? "")
        let didUpdatePrivatePhoto = !isPhotoSwitchOn() != profile?.privatePhoto
        let didUpdatePhoto = profileImageUrl != nil
        let didChangePinTimeout = UserData.sharedInstance.getPINHours() != pinTimeoutView.getPinHours()
        let actionsTrackingUpdated = isTrackActionsSwitchOn() != UserDefaults.Keys.shouldTrackActions.get(defaultValue: false)
        let didChangeTipAmount = meetingAmountField.integerValue != UserContact.kTipAmount
        
        return didChangeName || didChangeRouteHint || didUpdatePrivatePhoto || didUpdatePhoto || didChangePinTimeout || actionsTrackingUpdated || didChangeTipAmount
    }
    
    func saveFinished(success: Bool) {
        self.configureProfile()
        self.newMessageBubbleHelper.showGenericMessageView(text: success ? "profile.saved".localized : "generic.error.message".localized, in: self.view, position: .Top)
    }
    
    @IBAction func setupSignerButtonClicked(_ sender: Any) {
        CrypterManager.sharedInstance.startSetup()
    }
    
    @IBAction func disconnectMQTTButtonClicked(_ sender: Any) {
        CrypterManager.sharedInstance.resetMQTTConnection()
    }
}
