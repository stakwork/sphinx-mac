//
//  ImportSeedView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 27/03/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol ImportSeedViewDelegate : NSObject{
    func showImportSeedView(network: String, host: String, relay: String)//TODO: review this before shipping prod. May not need this anymore
    func showImportSeedView()
    func didTapCancelImportSeed()
    func didTapConfirm()
}

class ImportSeedView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var loadingView: NSBox!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    
    var delegate : ImportSeedViewDelegate? = nil
    
    var originalFrame: CGRect = .zero
    var isKeyboardShown = false
    var network:String = ""
    var host:String = ""
    var relay:String = ""
    
    var loading: Bool = false {
        didSet {
            loadingView.isHidden = !loading
            
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.Sphinx.Text, controls: [])
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setup()
    }
    
    private func setup() {
        textView.delegate = self
    }
    
    func showWith(
        delegate: ImportSeedViewDelegate?,
        network: String,
        host: String,
        relay: String
    ) {
        self.delegate = delegate
        self.network = network
        self.host = host
        self.relay = relay
        
        textView.becomeFirstResponder()
    }
    
    func showWith(
        delegate: ImportSeedViewDelegate?
    ) {
        self.delegate = delegate
        
        textView.becomeFirstResponder()
    }
    
    func getMnemonicWords() -> String {
        return textView.string
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        textView.resignFirstResponder()
        textView.string = ""
        
        self.loading = false
        
        delegate?.didTapCancelImportSeed()
    }
    
    @IBAction func confirmTapped(_ sender: Any) {
        let words = textView.string.split(separator: " ").map { String($0).trim().lowercased() }
        let (error, additionalString) = CrypterManager.sharedInstance.validateSeed(words: words)
        
        if let error = error {
            AlertHelper.showAlert(
                title: "profile.seed-validation-error-title".localized,
                message: error.localizedDescription + (additionalString ?? "")
            )
            return
        }
        
        textView.resignFirstResponder()
        loading = true
        
        delegate?.didTapConfirm()
    }
}

extension ImportSeedView: NSTextViewDelegate {
    func textView(
        _ textView: NSTextView,
        shouldChangeTextIn affectedCharRange: NSRange,
        replacementString: String?
    ) -> Bool {
        if let replacementString = replacementString, replacementString == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
