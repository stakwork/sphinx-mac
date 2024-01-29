//
//  PersonModalView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 05/01/2022.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Cocoa
import SwiftyJSON

class PersonModalView: CommonModalView, LoadableNib {
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var imageView: AspectFillNSImageView!
    @IBOutlet weak var nicknameLabel: NSTextField!
    @IBOutlet weak var messageLabel: NSTextField!
    @IBOutlet weak var priceLabel: NSTextField!
    @IBOutlet weak var initialMessageField: NSTextField!
    
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    @IBOutlet weak var loadingWheelContainer: NSBox!
    
    var contactResultsController: NSFetchedResultsController<UserContact>!
    var timeOutTimer : Timer? = nil

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        imageView.wantsLayer = true
        imageView.rounded = true
        imageView.gravity = .resizeAspectFill
        imageView.layer?.cornerRadius = imageView.frame.height / 2
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    var loading = false {
        didSet {
            loadingWheelContainer.isHidden = !loading
            
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.white, controls: [])
        }
    }
    
    override func modalWillShowWith(query: String, delegate: ModalViewDelegate) {
        super.modalWillShowWith(query: query, delegate: delegate)
        
        loading = true
        processQuery()
        getPersonInfo()
    }
    
    func getPersonInfo() {
        if let host = authInfo?.host, let pubkey = authInfo?.pubkey {
            API.sharedInstance.getPersonInfo(host: host, pubkey: pubkey, callback: { success, person in
                if let person = person {
                    self.showPersonInfo(person: person)
                } else {
                    self.delegate?.shouldDismissModals()
                }
            })
        }
    }
    
    func showPersonInfo(person: JSON) {
        authInfo?.jsonBody = person
        
        if let imageUrl = person["img"].string, let nsUrl = URL(string: imageUrl), imageUrl != "" {
            MediaLoader.asyncLoadImage(imageView: imageView, nsUrl: nsUrl, placeHolderImage: NSImage(named: "profileAvatar"))
        } else {
            imageView.image = NSImage(named: "profileAvatar")
        }
        
        nicknameLabel.stringValue = person["owner_alias"].string ?? "Unknown"
        messageLabel.stringValue = person["description"].string ?? "No description"
        priceLabel.stringValue = "\("price.to.meet".localized)\((person["price_to_meet"].int ?? 0)) sat"
        
        initialMessageField.placeholderString = "\("people.message.placeholder".localized) \(person["owner_alias"].string ?? "Unknown")"
        
        loading = false
    }
    
    override func modalDidShow() {
        super.modalDidShow()
    }
    
    @objc func handleKeyExchangeTimeout() {
        cleanupKeyExchange()
        showErrorMessage()
    }
    
    func cleanupKeyExchange() {
        timeOutTimer?.invalidate()
        resetFetchedResultsControllers()
    }
    
    override func didTapConfirmButton() {
        super.didTapConfirmButton()
        
        if let pubkey = authInfo?.pubkey {
            if let _ = UserContact.getContactWith(pubkey: pubkey) {
                showMessage(message: "already.connected".localized, color: NSColor.Sphinx.PrimaryGreen)
                return
            }
            
            let text = initialMessageField.stringValue
            guard !text.isEmpty else {
                showMessage(message: "message.required".localized, color: NSColor.Sphinx.BadgeRed)
                return
            }
            
            let nickname = authInfo?.jsonBody["owner_alias"].string ?? "Unknown"
            let pubkey = authInfo?.jsonBody["owner_pubkey"].string ?? ""
            let routeHint = authInfo?.jsonBody["owner_route_hint"].string ?? ""
            let contactKey = authInfo?.jsonBody["owner_contact_key"].string ?? ""
            
            UserContactsHelper.createContact(
                nickname: nickname,
                pubKey: pubkey,
                routeHint: routeHint,
                contactKey: contactKey,
                callback: { (success, contactId) in
                    
                    if let contactId = contactId, success {
                        self.configureFetchResultsControllerFor(contactId: contactId)
                        
                        self.timeOutTimer = Timer.scheduledTimer(
                            timeInterval: 30.0,
                            target: self,
                            selector: #selector(self.handleKeyExchangeTimeout),
                            userInfo: nil,
                            repeats: false
                        )
                        return
                    }
                    self.showErrorMessage()
                }
            )
        }
    }
    
    func sendInitialMessage() {
        if let pubkey = authInfo?.jsonBody["owner_pubkey"].string, let contact = UserContact.getContactWith(pubkey: pubkey) {
            let text = initialMessageField.stringValue
            let price = authInfo?.jsonBody["price_to_meet"].int ?? 0
            
            guard let params = TransactionMessage.getMessageParams(
                contact: contact,
                type: TransactionMessage.TransactionMessageType.message,
                text: text,
                priceToMeet: price
            ) else {
                showErrorMessage()
                return
            }
            
            API.sharedInstance.sendMessage(params: params, callback: { m in
                if let _ = TransactionMessage.insertMessage(
                    m: m,
                    existingMessage: TransactionMessage.getMessageWith(id: m["id"].intValue)
                ).0 {
                    self.delegate?.shouldDismissModals()
                }
            }, errorCallback: {
                self.showErrorMessage()
            })
        } else {
            showErrorMessage()
        }
    }
    
    func showErrorMessage() {
        showMessage(message: "generic.error.message".localized, color: NSColor.Sphinx.BadgeRed)
    }
    
    func showMessage(message: String, color: NSColor) {
        buttonLoading = false
        messageBubbleHelper.showGenericMessageView(text: message, delay: 3, textColor: NSColor.white, backColor: color, backAlpha: 1.0)
    }
    
}

extension PersonModalView: NSFetchedResultsControllerDelegate {
    func configureFetchResultsControllerFor(
        contactId: Int
    ) {
        let fetchRequest = UserContact.FetchRequests.encryptedContactWith(id: contactId)

        contactResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataManager.sharedManager.persistentContainer.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        contactResultsController.delegate = self
        
        do {
            try contactResultsController.performFetch()
        } catch {}
    }
    
    func resetFetchedResultsControllers() {
        contactResultsController = nil
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        if
            let resultController = controller as? NSFetchedResultsController<NSManagedObject>,
            let firstSection = resultController.sections?.first {
            
            if let contacts = firstSection.objects as? [UserContact], let _ = contacts.first {
                sendInitialMessage()
                cleanupKeyExchange()
            }
        }
    }
}
