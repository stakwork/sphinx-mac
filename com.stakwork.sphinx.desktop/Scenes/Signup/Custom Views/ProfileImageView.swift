//
//  ProfileImageView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 11/02/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Cocoa

class ProfileImageView: NSView, LoadableNib {
    
    weak var delegate: WelcomeEmptyViewDelegate?

    @IBOutlet var contentView: NSView!
    @IBOutlet weak var backButton: CustomButton!
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var profileImageView: AspectFillNSImageView!
    @IBOutlet weak var draggingView: DraggingDestinationView!
    @IBOutlet weak var uploadingLabel: NSTextField!
    @IBOutlet weak var continueButton: SignupButtonView!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    @IBOutlet weak var selectImageButtonView: SignupButtonView!
    
    enum Buttons: Int {
        case SelectImage
        case Skip
    }
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.white, controls: [continueButton.getButton()])
        }
    }
    
    var isSphinxV2 = false
    
    var imageSet = false
    let messageBubbleHelper = NewMessageBubbleHelper()
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setupViews()
    }
    
    func setupViews() {
        profileImageView.wantsLayer = true
        profileImageView.rounded = true
        profileImageView.layer?.cornerRadius = profileImageView.frame.height / 2
    }
    
    init(
        frame frameRect: NSRect,
        nickname: String,
        delegate: WelcomeEmptyViewDelegate,
        isSphinxV2: Bool = false
    ) {
        super.init(frame: frameRect)
        
        self.delegate = delegate
        self.isSphinxV2 = isSphinxV2
        
        loadViewFromNib()
        setupViews()
        
        configureView(nickname: nickname)
    }
    
    func configureView(nickname: String) {
        nameLabel.stringValue = nickname
        backButton.cursor = .pointingHand
        
        continueButton.configureWith(title: "skip".localized.capitalized, icon: "", tag: Buttons.Skip.rawValue, delegate: self)
        
        selectImageButtonView.configureWith(title: "select.image".localized.capitalized, icon: "", iconImage: "cameraIcon", tag: Buttons.SelectImage.rawValue, delegate: self)
        selectImageButtonView.setColors(backgroundNormal: NSColor.clear, borderNormal: NSColor(hex: "#556171"), borderHover: NSColor.white, textNormal: NSColor.white)
        
        draggingView.wantsLayer = true
        let size = CGSize(width: draggingView.frame.width - 4, height: draggingView.frame.height - 4)
        let rect = CGRect(x: 2, y: 2, width: size.width, height: size.height)
        draggingView.addDashedBorder(color: NSColor(hex: "#556171"), size: size, rect: rect, lineWidth: 1.5, dashPattern: [6,3], radius: draggingView.frame.height / 2)
        draggingView.layer?.cornerRadius = draggingView.frame.height / 2 - 2

        draggingView.configureForSignup()
        draggingView.delegate = self
        draggingView.setup()
    }
    
    @IBAction func backButtonClicked(_ sender: NSButton) {
        delegate?.shouldContinueTo?(mode: WelcomeLightningViewController.FormViewMode.NamePin.rawValue)
    }
    
    func uploadImage(image: NSImage) {
        if let imgData = image.sd_imageData(as: .JPEG, compressionQuality: 0.5) {
            let uploadMessage = String(format: "uploaded.progress".localized, 0)
            
            self.uploadingLabel.isHidden = false
            self.uploadingLabel.stringValue = uploadMessage
            
            let attachmentsManager = AttachmentsManager.sharedInstance
            attachmentsManager.delegate = self
            
            let attachmentObject = AttachmentObject(data: imgData, type: AttachmentsManager.AttachmentType.Photo)
            attachmentsManager.uploadPublicImage(attachmentObject: attachmentObject)
        } else {
            loading = false
            messageBubbleHelper.showGenericMessageView(text: "generic.error.message".localized)
        }
    }
    
    func updateProfile(photoUrl: String) {
        if isSphinxV2,
           let selfContact = SphinxOnionManager.sharedInstance.pendingContact
        {
            selfContact.avatarUrl = photoUrl //TODO: we need to figure out where avatars actually get stored now!
            self.loading = false
            self.goToSphinxReady()
        } else if !isSphinxV2 {
            let id = UserData.sharedInstance.getUserId()
            let parameters = ["photo_url" : photoUrl as AnyObject]
            
            API.sharedInstance.updateUser(id: id, params: parameters, callback: { contact in
                self.loading = false
                let _ = UserContactsHelper.insertContact(contact: contact)
                self.goToSphinxReady()
            }, errorCallback: {
                self.loading = false
                self.messageBubbleHelper.showGenericMessageView(text: "generic.error.message".localized)
            })
        } else {
            self.loading = false
            self.messageBubbleHelper.showGenericMessageView(text: "generic.error.message".localized)
        }
    }
}

extension ProfileImageView : SignupButtonViewDelegate {
    func didClickButton(tag: Int) {
        switch(tag) {
        case Buttons.SelectImage.rawValue:
            imageButtonClicked()
        case Buttons.Skip.rawValue:
            skipButtonClicked()
        default:
            break
        }
    }
    
    func imageButtonClicked() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["jpg", "jpeg", "png"]
        let i = openPanel.runModal()
        
        if (i == NSApplication.ModalResponse.OK) {
            if let url = openPanel.url, let image = NSImage(contentsOf: url) {
                imageSelected(image: image)
            }
        }
    }
    
    func skipButtonClicked() {
        if let image = self.profileImageView.image, imageSet {
            loading = true
            uploadImage(image: image)
        } else {
            goToSphinxReady()
        }
    }
    
    func goToSphinxReady() {
        SignupHelper.step = SignupHelper.SignupStep.ImageSet.rawValue
        delegate?.shouldContinueTo?(mode: WelcomeLightningViewController.FormViewMode.Ready.rawValue)
    }
}

extension ProfileImageView : DraggingViewDelegate {
    func imageDragged(image: NSImage) {
        imageSelected(image: image)
    }
    
    func imageSelected(image: NSImage) {
        continueButton.setTitle("next".localized.capitalized)
        selectImageButtonView.setTitle("change.image".localized.capitalized)
        
        imageSet = true
        profileImageView.image = image
    }
}

extension ProfileImageView : AttachmentsManagerDelegate {
    func didUpdateUploadProgress(progress: Int) {
        let uploadMessage = String(format: "uploaded.progress".localized, progress)
        uploadingLabel.stringValue = uploadMessage
    }
    
    func didSuccessUploadingImage(url: String) {
        if let image = profileImageView.image {
            MediaLoader.storeImageInCache(img: image, url: url)
        }
        updateProfile(photoUrl: url)
    }
}
