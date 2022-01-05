//
//  CommonModalView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 05/01/2022.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Cocoa
import SwiftyJSON

protocol ModalViewDelegate: AnyObject {
    func shouldDismissVC()
    func shouldGoToContactChat(contactId: Int)
}

protocol ModalViewInterface: AnyObject {
    var alphaValue: CGFloat { get set }
    
    func modalWillShowWith(query: String, delegate: ModalViewDelegate)
    func modalDidShow()
    func didTapConfirmButton()
}

class CommonModalView: NSView, ModalViewInterface {
    
    weak var delegate: ModalViewDelegate?
    
    @IBOutlet weak var confirmButton: NSButton!
    @IBOutlet weak var confirmButtonContainer: NSBox!
    @IBOutlet weak var buttonLoadingWheel: NSProgressIndicator!
    
    var messageBubbleHelper = NewMessageBubbleHelper()
    
    struct AuthInfo {
        var host : String? = nil
        var challenge : String? = nil
        var token : String? = nil
        var pubkey : String? = nil
        var verificationSignature : String? = nil
        var ts : Int? = nil
        var info : [String: AnyObject] = [:]
        var personInfo : JSON = JSON()
    }
    
    var authInfo: AuthInfo? = nil
    var query: String! = nil
    
    var buttonLoading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: buttonLoading, loadingWheel: buttonLoadingWheel, color: NSColor.white, controls: [confirmButton])
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        confirmButtonContainer.wantsLayer = true
        confirmButtonContainer.layer?.cornerRadius = confirmButtonContainer.frame.height / 2
    }

    func modalWillShowWith(query: String, delegate: ModalViewDelegate) {
        self.query = query
        self.delegate = delegate
    }
    
    func modalDidShow() {
        //Will be override in subclass
    }
    
    func didTapConfirmButton() {
        //Will be override in subclass
    }
    
    func processQuery() {
        if let query = query {
            authInfo = AuthInfo()
            
            for component in query.components(separatedBy: "&") {
                let elements = component.components(separatedBy: "=")
                if elements.count > 1 {
                    let key = elements[0]
                    let value = component.replacingOccurrences(of: "\(key)=", with: "")
                    
                    switch(key) {
                    case "host":
                        authInfo?.host = value
                        break
                    case "challenge":
                        authInfo?.challenge = value
                        break
                    case "pubkey":
                        authInfo?.pubkey = value
                        break
                    default:
                        break
                    }
                }
            }
        }
    }
    
    @IBAction func closeButtonTouched(_ sender: Any) {
        delegate?.shouldDismissVC()
    }
    
    @IBAction func confirmButtonTouched(_ sender: Any) {
        didTapConfirmButton()
    }
}
