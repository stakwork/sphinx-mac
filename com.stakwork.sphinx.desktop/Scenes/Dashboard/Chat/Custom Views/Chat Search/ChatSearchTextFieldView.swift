//
//  ChatSearchTextFieldView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 05/10/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol ChatSearchTextFieldViewDelegate : AnyObject {
    func shouldSearchFor(term: String)
    func didTapSearchCancelButton()
}

class ChatSearchTextFieldView: NSView, LoadableNib {
    
    weak var delegate: ChatSearchTextFieldViewDelegate?

    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var clearButtonContainer: NSBox!
    @IBOutlet weak var clearButton: CustomButton!
    @IBOutlet weak var cancelButton: CustomButton!
    
    
    let kPlaceHolder = "Search"
    let kFieldPlaceHolderColor = NSColor.Sphinx.PlaceholderText
    let kTextColor = NSColor.Sphinx.Text
    
    var timer: Timer?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setupView()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
        setupView()
    }
    
    func setupView() {
        textField.delegate = self
        
        clearButton.cursor = .pointingHand
        cancelButton.cursor = .pointingHand
    }
    
    func setDelegate(
        _ delegate: ChatSearchTextFieldViewDelegate?
    ) {
        self.delegate = delegate
    }
    
    func makeFieldActive() {
        textField.becomeFirstResponder()
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        textField.stringValue = ""
        textField.resignFirstResponder()
        
        delegate?.didTapSearchCancelButton()
    }
    
    @IBAction func clearButtonClicked(_ sender: Any) {
        textFieldShouldClear()
    }
}

extension ChatSearchTextFieldView : NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            clearButtonContainer.isHidden = textField.stringValue.isEmpty
            performSearchWithDelay(term: textField.stringValue)
        }
    }
    
    func textFieldShouldClear() {
        textField.stringValue = ""
        clearButtonContainer.isHidden = textField.stringValue.isEmpty
        self.delegate?.shouldSearchFor(term: "")
    }
    
    func performSearchWithDelay(
        term: String
    ) {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false, block: { (timer) in
            self.delegate?.shouldSearchFor(term: term)
        })
    }
}
