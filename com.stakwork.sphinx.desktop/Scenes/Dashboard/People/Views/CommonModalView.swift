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
    func shouldDismissModals()
}

protocol ModalViewInterface: AnyObject {
    var isHidden: Bool { get set }
    
    func modalWillShowWith(query: String, delegate: ModalViewDelegate)
    func modalDidShow()
    func didTapConfirmButton()
}

class CommonModalView: NSView, ModalViewInterface {
    
    weak var delegate: ModalViewDelegate?
    
    @IBOutlet weak var closeButton: CustomButton!
    @IBOutlet weak var confirmButton: CustomButton!
    @IBOutlet weak var confirmButtonContainer: NSBox!
    @IBOutlet weak var buttonLoadingWheel: NSProgressIndicator!
    
    var messageBubbleHelper = NewMessageBubbleHelper()
    
    struct AuthInfo {
        var action: String? = nil
        
        var id : String? = nil
        var host : String? = nil
        var challenge : String? = nil
        var sig : String? = nil
        var token : String? = nil
        var pubkey : String? = nil
        var routeHint : String? = nil
        var name : String? = nil
        var amount : Int? = nil
        var verificationSignature : String? = nil
        var ts : Int? = nil
        var info : [String: AnyObject] = [:]
        var jsonBody : JSON = JSON()
        
        var key : String? = nil
        var path : String? = nil
        var updateMethod : String? = nil
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
        
        closeButton.cursor = .pointingHand
        confirmButton.cursor = .pointingHand
        
        confirmButtonContainer.wantsLayer = true
        confirmButtonContainer.layer?.cornerRadius = confirmButtonContainer.frame.height / 2
    }

    func modalWillShowWith(query: String, delegate: ModalViewDelegate) {
        self.query = query
        self.delegate = delegate
        
        buttonLoading = false
    }
    
    func modalDidShow() {
        //Will be override in subclass
    }
    
    func didTapConfirmButton() {
        buttonLoading = true
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
                    case "action":
                        authInfo?.action = value
                        break
                    case "host":
                        authInfo?.host = value
                        break
                    case "id":
                        authInfo?.id = value
                        break
                    case "challenge":
                        authInfo?.challenge = value
                        break
                    case "pubkey":
                        authInfo?.pubkey = value
                        break
                    case "key":
                        authInfo?.key = value
                        break
                    case "name":
                        authInfo?.name = value
                        break
                    case "token":
                        authInfo?.token = value
                        break
                    case "amount":
                        if let intValue = Int(value) {
                            authInfo?.amount = intValue
                        }
                        break
                    default:
                        break
                    }
                }
            }
        }
    }
    
    @IBAction func closeButtonTouched(_ sender: Any) {
        delegate?.shouldDismissModals()
    }
    
    @IBAction func confirmButtonTouched(_ sender: Any) {
        didTapConfirmButton()
    }
}
