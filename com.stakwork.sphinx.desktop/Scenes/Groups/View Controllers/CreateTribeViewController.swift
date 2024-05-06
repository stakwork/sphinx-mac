//
//  CreateTribeViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 03/10/2022.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Cocoa

class CreateTribeViewController: NSViewController {
    
    @IBOutlet weak var formScrollView: NSScrollView!
    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var imageField: NSTextField!
    @IBOutlet weak var tribeImageView: AspectFillNSImageView!
    @IBOutlet weak var imageDraggingView: DraggingDestinationView!
    @IBOutlet weak var descriptionField: NSTextField!
    @IBOutlet weak var tagsField: NSTextField!
    @IBOutlet weak var priceToJoinField: NSTextField!
    @IBOutlet weak var pricePerMessageField: NSTextField!
    @IBOutlet weak var amountToStakeField: NSTextField!
    @IBOutlet weak var timeToStakeField: NSTextField!
    @IBOutlet weak var appUrlField: NSTextField!
    @IBOutlet weak var feedUrlField: NSTextField!
    @IBOutlet weak var secondBrainUrlField: NSTextField!
    @IBOutlet weak var feedTypeField: NSTextField!
    @IBOutlet weak var feedTypeButton: NSButton!
    @IBOutlet weak var listSwitch: NSSwitch!
    @IBOutlet weak var approveRequestSwitch: NSSwitch!
    @IBOutlet weak var saveButtonContainer: NSView!
    @IBOutlet weak var saveButtonLoadingWheel: NSProgressIndicator!
    @IBOutlet weak var saveButtonLabel: CustomButton!
    @IBOutlet weak var tribeTagsView: TribeTagsView!
    
    var imageSelected = false
    
    var chat: Chat? = nil
    
    var viewModel: CreateTribeViewModel! = nil
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: saveButtonLoadingWheel, color: NSColor.white, controls: [saveButtonLabel])
        }
    }
    
    static func instantiate(
        chat: Chat? = nil
    ) -> CreateTribeViewController {
        let viewController = StoryboardScene.Groups.createTribeViewController.instantiate()
        viewController.chat = chat
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tribeImageView.wantsLayer = true
        tribeImageView.rounded = true
        tribeImageView.layer?.cornerRadius = tribeImageView.frame.height / 2
        
        self.viewModel = CreateTribeViewModel(chat: chat, successCallback: {
            WindowsManager.sharedInstance.dismissViewFromCurrentWindow()
        }, errorCallback: {
            self.loading = false
        })
        
        configureFields()
        completeEditView()
    }
    
    func configureFields() {
        imageDraggingView.configureForTribeImage()
        imageDraggingView.delegate = self
        imageDraggingView.setup()
        
        let numberFormatter = OnlyIntegerValueFormatter()
        priceToJoinField.formatter = numberFormatter
        pricePerMessageField.formatter = numberFormatter
        amountToStakeField.formatter = numberFormatter
        timeToStakeField.formatter = numberFormatter
        
        nameField.delegate = self
        descriptionField.delegate = self
        feedUrlField.delegate = self
        
        tribeImageView.layer?.cornerRadius = tribeImageView.frame.size.height / 2
        
        tribeTagsView.setDelegate(delegate: self)
    }
    
    func completeEditView() {
        if let _ = chat, let chatTribeInfo = viewModel.tribeInfo() {
            nameField.stringValue = chatTribeInfo.name ?? ""
            descriptionField.stringValue = chatTribeInfo.description ?? ""
            imageField.stringValue = chatTribeInfo.img ?? ""
            completeUrlAndLoadImage()
            
            let priceToJoin = chatTribeInfo.priceToJoin ?? 0
            priceToJoinField.stringValue = priceToJoin > 0 ? "\(priceToJoin)" : ""
            
            let pricePerMessage = chatTribeInfo.pricePerMessage ?? 0
            pricePerMessageField.stringValue = pricePerMessage > 0 ? "\(pricePerMessage)" : ""
            
            let amountToStake = chatTribeInfo.amountToStake ?? 0
            amountToStakeField.stringValue = amountToStake > 0 ? "\(amountToStake)" : ""
            
            let timeToStake = chatTribeInfo.timeToStake ?? 0
            timeToStakeField.stringValue = timeToStake > 0 ? "\(timeToStake)" : ""
            
            appUrlField.stringValue = chatTribeInfo.appUrl ?? ""
            secondBrainUrlField.stringValue = chatTribeInfo.secondBrainUrl ?? ""
            feedUrlField.stringValue = chatTribeInfo.feedUrl ?? ""
            
            let feedUrl = chatTribeInfo.feedUrl ?? ""
            let feedType = (chatTribeInfo.feedContentType ?? FeedContentType.defaultValue).description
            feedTypeField.stringValue = (feedUrl.isEmpty) ? "" : feedType
            
            listSwitch.state = !chatTribeInfo.unlisted ? NSControl.StateValue.on : NSControl.StateValue.off
            approveRequestSwitch.state = chatTribeInfo.privateTribe ? NSControl.StateValue.on : NSControl.StateValue.off
            
            tribeTagsView.configureWith(tags: chatTribeInfo.tags)
            
            completeTagsField()
            
            saveButtonContainer.isHidden = false
            
            nameField.becomeFirstResponder()
        }
    }
    
    func completeTagsField() {
        if let chatTribeInfo = viewModel.tribeInfo() {
            let tagsArray = chatTribeInfo.tags.filter { $0.selected }
            let tagsStringt = tagsArray.map { $0.description }.joined(separator: ", ")
            tagsField.stringValue = tagsStringt
        }
    }
    
    func completeUrlAndLoadImage() {
        let imgUrl = imageField.stringValue
        if imgUrl.isValidURL {
            if let nsUrl = URL(string: imgUrl) {
                MediaLoader.asyncLoadImage(imageView: tribeImageView, nsUrl: nsUrl, placeHolderImage: NSImage(named: "tribePlaceHolder"))
            }
        }
    }
    
    func validateForm() {
        let isNameCompleted = !nameField.stringValue.isEmpty
        let isDescriptionCompleted = !descriptionField.stringValue.isEmpty
        let isFeedValid = (feedUrlField.stringValue.isEmpty || !feedTypeField.stringValue.isEmpty)
        
        saveButtonContainer.isHidden = !isNameCompleted || !isDescriptionCompleted || !isFeedValid
    }
    
    @IBAction func tagsButtonClicked(_ sender: Any) {
        tribeTagsView.isHidden = false
    }
    
    @IBAction func feedTypeButtonClicked(_ sender: Any) {
        if !feedUrlField.stringValue.isEmpty {
            MessageOptionsHelper.sharedInstance.showMenuForFeedContent(in: self.view, from: feedTypeField, with: self)
        }
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        loading = true
        
        viewModel.setInfo(
            name: nameField.stringValue,
            description: descriptionField.stringValue,
            img: imageField.stringValue,
            priceToJoin: Int(priceToJoinField.stringValue),
            pricePerMessage: Int(pricePerMessageField.stringValue),
            amountToStake: Int(amountToStakeField.stringValue),
            timeToStake: Int(timeToStakeField.stringValue),
            appUrl: appUrlField.stringValue,
            secondBrainUrl: secondBrainUrlField.stringValue,
            feedUrl: feedUrlField.stringValue,
            listInTribes: listSwitch.state == NSControl.StateValue.on,
            privateTribe: approveRequestSwitch.state == NSControl.StateValue.on
        )
        
        let image = imageSelected ? tribeImageView.image : nil
        viewModel.saveChanges(image)
    }
}

extension CreateTribeViewController : DraggingViewDelegate {
    func imageDragged(image: NSImage) {
        tribeImageView.image = image
        imageField.stringValue = "image".localized.capitalized
        imageSelected = true
    }
}

extension CreateTribeViewController : MessageOptionsDelegate {
    func shouldSetFeedType(type: Int) {
        if let feedTypeItem = MessageOptionsHelper.FeedTypeItem(rawValue: type) {
            switch (feedTypeItem) {
            case .Podcast:
                viewModel.updateFeedType(type: FeedContentType.podcast)
                feedTypeField.stringValue = "Podcast"
                break
            case .Video:
                viewModel.updateFeedType(type: FeedContentType.video)
                feedTypeField.stringValue = "Video"
                break
            case .Newsletter:
                viewModel.updateFeedType(type: FeedContentType.newsletter)
                feedTypeField.stringValue = "Newsletter"
                break
            }
        }
    }
    
    func willHideMenu() {
        validateForm()
    }
}

extension CreateTribeViewController : TribeTagViewDelegate {
    func didTapOnTag(tag: Int, selected: Bool) {
        viewModel.updateTag(index: tag, selected: selected)
        completeTagsField()
    }
}

extension CreateTribeViewController : NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        validateForm()
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        if let textField = obj.object as? NSTextField, textField == feedUrlField {
            feedTypeButtonClicked(textField)
        }
    }
}

class OnlyIntegerValueFormatter: NumberFormatter {

    override func isPartialStringValid(
        _ partialString: String,
        newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {

        if partialString.isEmpty {
            return true
        }
        return Int(partialString) != nil
    }
}
