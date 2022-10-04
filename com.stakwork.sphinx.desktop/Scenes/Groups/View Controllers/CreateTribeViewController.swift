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
    @IBOutlet weak var tribeImageView: NSImageView!
    @IBOutlet weak var imageDraggingView: DraggingDestinationView!
    @IBOutlet weak var descriptionField: NSTextField!
    @IBOutlet weak var tagsField: NSTextField!
    @IBOutlet weak var priceToJoinField: NSTextField!
    @IBOutlet weak var pricePerMessageField: NSTextField!
    @IBOutlet weak var amountToStakeField: NSTextField!
    @IBOutlet weak var timeToStakeField: NSTextField!
    @IBOutlet weak var appUrlField: NSTextField!
    @IBOutlet weak var feedUrlField: NSTextField!
    @IBOutlet weak var feedTypeField: NSTextField!
    @IBOutlet weak var feedTypeButton: NSButton!
    @IBOutlet weak var listSwitch: NSSwitch!
    @IBOutlet weak var approveRequestSwitch: NSSwitch!
    @IBOutlet weak var saveButtonContainer: NSView!
    @IBOutlet weak var saveButtonLoadingWheel: NSProgressIndicator!
    
    @IBOutlet weak var tribeTagsView: TribeTagsView!
    
    var imageSelected = false
    
    static func instantiate() -> CreateTribeViewController {
        let viewController = StoryboardScene.Groups.createTribeViewController.instantiate()
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureFields()
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
    }
    
    @IBAction func tagsButtonClicked(_ sender: Any) {
        tribeTagsView.isHidden = false
    }
    
    @IBAction func feedTypeButtonClicked(_ sender: Any) {
        MessageOptionsHelper.sharedInstance.showMenuForFeedContent(in: self.view, from: feedTypeField, with: self)
    }
    
    @IBAction func listSwitchChanged(_ sender: Any) {
    }
    
    @IBAction func approveSwitchChanged(_ sender: Any) {
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
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
