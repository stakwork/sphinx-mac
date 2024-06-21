//
//  TribeMemberInfoView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/12/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

@objc protocol TribeMemberInfoDelegate : AnyObject {
    func didUpdateUploadProgress(uploadString: String)
    @objc optional func didChangeName(newValue: String)
    @objc optional func didChangeImage()
}

class TribeMemberInfoView: NSView, LoadableNib {
    
    weak var delegate: TribeMemberInfoDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var aliasTextField: NSTextField!
    @IBOutlet weak var pictureTextField: NSTextField!
    @IBOutlet weak var pictureImageView: AspectFillNSImageView!
    @IBOutlet weak var draggingDestinationView: DraggingDestinationView!
    
    var uploadCompletion: ((String?, String?) -> ())? = nil
    var imageSelected = false
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        
        draggingDestinationView.configureForTribeImage()
        draggingDestinationView.delegate = self
        draggingDestinationView.setup()
        
        setupViews()
    }
    
    func setupViews() {
        pictureImageView.wantsLayer = true
        pictureImageView.rounded = true
        pictureImageView.layer?.cornerRadius = pictureImageView.frame.height / 2
        
        pictureTextField.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(handleCopy)))
    }
    
    @objc func handleCopy() {
        ClipboardHelper.copyToClipboard(text: pictureTextField.stringValue, message: "text.copied.clipboard".localized)
    }
    
    func configureWith(
        vc: NSViewController,
        alias: String?,
        picture: String? = nil,
        shouldFixAlias: Bool = false
    ) {
        if let vc = vc as? TribeMemberInfoDelegate {
            self.delegate = vc
        }
        
        aliasTextField.stringValue = (shouldFixAlias ? alias?.fixedAlias : alias) ?? ""
        pictureTextField.stringValue = picture ?? ""
        
        aliasTextField.delegate = self
        pictureTextField.delegate = self
        
        self.window?.makeFirstResponder(nil)

        loadImage(pictureUrl: picture)
    }
    
    func loadImage(pictureUrl: String?) {
        if let pictureUrl = pictureUrl, let url = URL(string: pictureUrl), !pictureUrl.isEmpty && pictureUrl.isValidURL {
            MediaLoader.asyncLoadImage(imageView: pictureImageView, nsUrl: url, placeHolderImage: NSImage(named: "profileAvatar"))
        } else {
            pictureTextField.stringValue = ""
            pictureImageView.image = NSImage(named: "profileAvatar")
        }
    }
    
    func uploadImage(completion: @escaping (String?, String?) -> ()) {
        uploadCompletion = completion
        
        if aliasTextField.stringValue.isEmpty {
            completion(nil, nil)
        }
        
        if let image = pictureImageView.image, imageSelected {
            uploadImage(image: image)
            return
        }
        let pictureUrl = pictureTextField.stringValue.isValidURL ? pictureTextField.stringValue : ""
        completion(aliasTextField.stringValue, pictureUrl)
    }
    
    func uploadImage(image: NSImage) {
        if let imgData = image.sd_imageData(as: .JPEG, compressionQuality: 0.5) {
            didUpdateUploadProgress(progress: 0)
            
            let attachmentsManager = AttachmentsManager.sharedInstance
            attachmentsManager.delegate = self
            
            let attachmentObject = AttachmentObject(data: imgData, type: AttachmentsManager.AttachmentType.Photo)
            attachmentsManager.uploadPublicImage(attachmentObject: attachmentObject)
        }
    }
}

extension TribeMemberInfoView : NSTextFieldDelegate {
    func controlTextDidChange(_ notification: Notification) {
        if let textField = notification.object as? NSTextField, textField == aliasTextField {
            
            let fixedAlias = textField.stringValue.fixedAlias
            allowedCharactersToast(fixedAlias != textField.stringValue)
            
            aliasTextField.stringValue = textField.stringValue.fixedAlias
            delegate?.didChangeName?(newValue: fixedAlias)
        }
    }
    
    func controlTextDidBeginEditing(_ notification: Notification) {
        if let textField = notification.object as? NSTextField, textField == aliasTextField {
            aliasTextField.stringValue = textField.stringValue.fixedAlias
        }
    }
    
    func allowedCharactersToast(_ show: Bool) {
        guard show else {
            return
        }
        NewMessageBubbleHelper().showGenericMessageView(text: "alias.allowed-characters".localized)
    }
}

extension TribeMemberInfoView : DraggingViewDelegate {
    func imageDragged(image: NSImage) {
        pictureImageView.image = image
        pictureTextField.stringValue = "image".localized.capitalized
        imageSelected = true
        
        delegate?.didChangeImage?()
    }
}

extension TribeMemberInfoView : AttachmentsManagerDelegate {
    func didUpdateUploadProgress(progress: Int) {
        let uploadedMessage = String(format: "uploaded.progress".localized, progress)
        delegate?.didUpdateUploadProgress(uploadString: uploadedMessage)
    }
    
    func didSuccessUploadingImage(url: String) {
        if let image = pictureImageView.image {
            MediaLoader.storeImageInCache(img: image, url: url)
        }
        pictureTextField.stringValue = url
        
        if let uploadCompletion = uploadCompletion {
            uploadCompletion(aliasTextField.stringValue, url)
        }
    }
}
