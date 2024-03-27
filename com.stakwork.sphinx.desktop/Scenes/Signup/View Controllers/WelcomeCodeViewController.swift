//
//  WelcomeCodeViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 10/02/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Cocoa

class WelcomeCodeViewController: NSViewController {
    
    @IBOutlet weak var leftContainer: NSView!
    @IBOutlet weak var leftContainerLabel: NSTextField!
    @IBOutlet weak var leftImageView: AspectFillNSImageView!
    @IBOutlet weak var rightContainer: NSView!
    @IBOutlet weak var rightContainerWidth: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var backButton: CustomButton!
    @IBOutlet weak var pinBackButtonContainer: NSView!
    @IBOutlet weak var pinBackButton: CustomButton!
    @IBOutlet weak var codeField: SignupFieldView!
    @IBOutlet weak var submitButton: SignupButtonView!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    @IBOutlet weak var pinView: PinView!
    @IBOutlet weak var importSeedView: ImportSeedView!
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.white, controls: [submitButton.getButton()])
        }
    }
    
    var mode = SignupHelper.SignupMode.NewUser
    
    let messageBubbleHelper = NewMessageBubbleHelper()
    let userData = UserData.sharedInstance
    
    var isSphinxV2 = false
    var server : Server? = nil
    var balance : String? = nil
    
    static func instantiate(
        mode: SignupHelper.SignupMode,
        isSphinxV2: Bool = false
    ) -> WelcomeCodeViewController {
        let viewController = StoryboardScene.Signup.welcomeCodeViewController.instantiate()
        viewController.mode = mode
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        pinView.alphaValue = 0.0
        pinView.configureForSignup()
        pinView.bringSubviewToFront(pinBackButtonContainer)
        
        backButton.cursor = .pointingHand
        pinBackButton.cursor = .pointingHand
        
        leftContainer.alphaValue = 0.0
        rightContainer.alphaValue = 0.0
        
        titleLabel.stringValue = (isNewUser ? "new.user" : "connect").localized.uppercased()
        
        submitButton.configureWith(title: "submit".localized, icon: "", tag: -1, delegate: self)
        submitButton.setSignupColors()
        submitButton.buttonDisabled = true
        
        let placeholder = isNewUser ? "paste.invitation.code" : "paste.keys"
        codeField.configureWith(placeHolder: placeholder.localized, label: "", backgroundColor: NSColor.white, field: .Code, delegate: self)
        
        let label = (isNewUser ? "signup.label" : "restore.label").localized
        let boldLabels = isNewUser ? ["signup.label.bold.1".localized, "signup.label.bold.2".localized] : ["restore.label.bold".localized]
        leftContainerLabel.attributedStringValue = String.getAttributedText(string: label, boldStrings: boldLabels, font: NSFont(name: "Roboto-Light", size: 15.0)!, boldFont: NSFont(name: "Roboto-Bold", size: 15.0)!)
        
        leftImageView.image = NSImage(named: isNewUser ? "newUserImage" : "existingUserImage")
    }
    
    var isNewUser: Bool {
        get {
            return mode == .NewUser
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        AnimationHelper.animateViewWith(duration: 0.3, animationsBlock: {
            self.leftContainer.alphaValue = 1.0
            self.rightContainer.alphaValue = 1.0
        })
    }
    
    @IBAction func backButtonClicked(_ sender: NSButton) {
        self.view.window?.replaceContentBy(vc: WelcomeInitialViewController.instantiate())
    }
    
    @IBAction func pinBackButtonClicked(_ sender: NSButton) {
        loading = false
        animatePinContainer(expanded: false, completion: {
            self.pinView.isHidden = true
        })
    }
}

extension WelcomeCodeViewController : SignupButtonViewDelegate {
    func didClickButton(tag: Int) {
        let code = codeField.getFieldValue()
        
        if validateCode(code: code) {
            loading = true
            
            if code.isRelayQRCode ||
                code.isInviteCode ||
                code.isSwarmConnectCode ||
                code.isSwarmClaimCode
            {
                startSignup(code: code)
            } else {
                showPINView(encryptedKeys: code)
            }
        }
    }
    
    func startSignup(code: String) {
        if code.isRelayQRCode {
            let (ip, password) = code.getIPAndPassword()
            if let ip = ip, let password = password {
                connectToNode(ip: ip, password: password)
            }
        } else if code.isInviteCode {
            signupWith(code: code)
        } else if code.isV2InviteCode {
            signupWith(sphinxV2Code: code)
        } else if code.isSwarmConnectCode {
            signupWith(swarmConnectCode: code)
        } else if code.isSwarmClaimCode {
            signupWith(withSwarmClaimCode: code)
        }
    }
    
    func signupWith(swarmConnectCode:String) {
        let splitString = swarmConnectCode.components(separatedBy: "::")
        if splitString.count > 2 {
            let ip = splitString[1]
            let pubKey = splitString[2]
            self.connectToNode(ip: ip, pubKey: pubKey)
        }
    }
    
    func signupWith(withSwarmClaimCode connectionCode:String){
        let splitString = connectionCode.components(separatedBy: "::")
        
        if splitString.count > 2, let token = splitString[2].base64Decoded {
            
            let ip = splitString[1]
            userData.save(ip: ip)
            
            continueToConnectingView(mode: .SwarmClaimUser, token: token)
        }
        else{
            let errorMessage = ("invalid.code.claim").localized
            self.messageBubbleHelper.showGenericMessageView(text: errorMessage, position: .Bottom, delay: 7, textColor: NSColor.white, backColor: NSColor.Sphinx.BadgeRed, backAlpha: 1.0, withLink: "https://sphinx.chat")
        }
    }
    
    func signupWith(code: String) {
        API.sharedInstance.signupWithCode(inviteString: code, callback: { (invite, ip, pubkey) in
            self.save(ip: ip, pubkey: pubkey, and: "")
            SignupHelper.saveInviterInfo(invite: invite, code: code)
            self.continueToConnectingView(mode: .NewUser)
        }, errorCallback: {
            self.messageBubbleHelper.showGenericMessageView(text: "generic.error.message".localized)
            self.loading = false
        })
    }
    
    func signupWith(sphinxV2Code: String) {
        SphinxOnionManager.sharedInstance.vc = self
        SphinxOnionManager.sharedInstance.chooseImportOrGenerateSeed(completion: {success in
            if (success) {
                self.handleInviteCodeV2SignUp(code: sphinxV2Code)
            } else {
                AlertHelper.showAlert(title: "Error redeeming invite", message: "Please try again or ask for another invite.")
            }
            SphinxOnionManager.sharedInstance.vc = nil
        })
    }
    
    func handleInviteCodeV2SignUp(code: String){
        if let mnemonic = UserData.sharedInstance.getMnemonic(),
            SphinxOnionManager.sharedInstance.createMyAccount(mnemonic: mnemonic)
        {
            SphinxOnionManager.sharedInstance.redeemInvite(inviteCode: code)
            self.signup_v2_with_test_server()
        }
    }
    
    func signup_v2_with_test_server(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
            let som = SphinxOnionManager.sharedInstance
            if let contact = som.pendingContact, contact.isOwner == true {
                som.isV2InitialSetup = true
                self.continueToConnectingView(mode: .NewUser, isSphinxV2: true)
            } else {
//                self.navigationController?.popViewController(animated: true)
                AlertHelper.showAlert(title: "Error", message: "Unable to connect to Sphinx V2 Test Server")
            }
        })
        
    }
    
    func connectToNode(ip: String, password: String="", pubKey:String="") {
        save(ip: ip, pubkey: pubKey, and: password)

        let invite = SignupHelper.getSupportContact()
        SignupHelper.saveInviterInfo(invite: invite)
        continueToConnectingView(mode: .NewUser)
    }

    func save(ip: String, pubkey: String, and password: String) {
        UserDefaults.Keys.ownerPubKey.set(pubkey)
        
        userData.save(ip: ip)
        userData.save(password: password)
    }
    
    func showPINView(encryptedKeys: String) {
        UserDefaults.Keys.defaultPIN.removeValue()
        pinView.doneCompletion = { pin in
            if let keys = self.getRestoreKeys(code: encryptedKeys) {
                self.restore(encryptedKeys: keys, with: pin)
            }
        }
        pinView.isHidden = false
        animatePinContainer(expanded: true)
    }
    
    private func getRestoreKeys(code: String) -> String? {
        return code.getRestoreKeys() ?? code.fixedRestoreCode.getRestoreKeys()
    }
    
    func animatePinContainer(expanded: Bool, completion: (() -> ())? = nil) {
        let windowsWidth = (view.window ?? NSApplication.shared.keyWindow)?.frame.width
        let expectedWidth = expanded ? ((windowsWidth ?? 800) / 2) : 0
        
        if expectedWidth == rightContainerWidth.constant {
            return
        }
        pinView.reset()
        pinView.alphaValue = 0.0
        rightContainer.alphaValue = 0.0
        
        rightContainerWidth.constant = expectedWidth
        AnimationHelper.animateViewWith(duration: 0.5, animationsBlock: {
            self.view.layoutSubtreeIfNeeded()
        }, completion: {
            AnimationHelper.animateViewWith(duration: 0.2, animationsBlock: {
                self.rightContainer.alphaValue = expanded ? 0.0 : 1.0
                self.pinView.alphaValue = expanded ? 1.0 : 0.0
            }, completion: {
                self.pinView.makeFieldFirstResponder()
                completion?()
            })
        })
    }

    func restore(encryptedKeys: String, with pin: String) {
        if let keys = SymmetricEncryptionManager.sharedInstance.decryptRestoreKeys(encryptedKeys: encryptedKeys.fixedRestoreCode, pin: pin) {
            if EncryptionManager.sharedInstance.insertKeys(privateKey: keys[0], publicKey: keys[1]) {
                userData.save(ip: keys[2], token: keys[3], pin: pin)
                
                self.continueToConnectingView(mode: .ExistingUser)
                return
            }
        }
        self.pinView.reset()
        self.messageBubbleHelper.showGenericMessageView(text: "invalid.pin".localized, in: self.view)
        self.loading = false
    }
    
    func continueToConnectingView(
        mode: SignupHelper.SignupMode,
        token: String? = nil,
        isSphinxV2: Bool = false
    ) {
        UserDefaults.Keys.lastPinDate.set(Date())
        view.window?.replaceContentBy(
            vc: WelcomeEmptyViewController.instantiate(
                mode: mode,
                viewMode: .Connecting,
                token: token,
                isSphinxV2: isSphinxV2
            )
        )
    }
}

extension WelcomeCodeViewController : SignupFieldViewDelegate {
    func didChangeText(text: String) {
        if text == NSPasteboard.general.string(forType: .string) {
            let valid = validateCode(code: text)
            submitButton.buttonDisabled = !valid
            return
        }
        submitButton.buttonDisabled = text.isEmpty
    }
    
    func validateCode(code: String) -> Bool {
        if code.isRelayQRCode {
            return true
        } else if code.isRestoreKeysString || code.fixedRestoreCode.isRestoreKeysString {
            return true
        } else if code.isInviteCode {
            return true
        }
        else if code.isSwarmConnectCode{
            return true
        }
        else if code.isSwarmClaimCode{
            return true
        }
        
        if code.isPubKey {
            messageBubbleHelper.showGenericMessageView(text: "invalid.code.pubkey".localized, position: .Bottom, delay: 7, textColor: NSColor.white, backColor: NSColor.Sphinx.BadgeRed, backAlpha: 1.0, withLink: "https://sphinx.chat")
            return false
        } else if code.isLNDInvoice {
            messageBubbleHelper.showGenericMessageView(text: "invalid.code.invoice".localized, position: .Bottom, delay: 7, textColor: NSColor.white, backColor: NSColor.Sphinx.BadgeRed, backAlpha: 1.0, withLink: "https://sphinx.chat")
            return false
        }

        let errorMessage = (isNewUser ? "invalid.code" : "invalid.restore.code").localized
        messageBubbleHelper.showGenericMessageView(text: errorMessage, position: .Bottom, delay: 7, textColor: NSColor.white, backColor: NSColor.Sphinx.BadgeRed, backAlpha: 1.0, withLink: "https://sphinx.chat")
        return false
    }
}

extension WelcomeCodeViewController : ImportSeedViewDelegate {
    func showImportSeedView() {
        importSeedView.delegate = self
        importSeedView.isHidden = false
    }
    
    @objc func handleServerNotification(n: Notification) {
        if let server = n.userInfo?["server"] as? Server{
            self.server = server
            server.managedObjectContext?.saveContext()
        }
    }
    
    @objc func handleBalanceNotification(n:Notification){
        if let balance = n.userInfo?["balance"] as? String{
            self.balance = balance
        }
    }
    
    
    func showImportSeedView(
        network: String,
        host: String,
        relay: String
    ){
        importSeedView.showWith(
            delegate: self,
            network: network,
            host: host,
            relay: relay
        )
        importSeedView.isHidden = false
    }
    
    func didTapCancelImportSeed() {
        importSeedView.isHidden = true
    }
    
    func didTapConfirm() {
        importSeedView.isHidden = true
        UserData.sharedInstance.save(walletMnemonic: importSeedView.getMnemonicWords())
        
        let code = codeField.getFieldValue()
        
        if validateCode(code: code) {
            handleInviteCodeV2SignUp(code: code)
        }
    }
    
}
