//
//  AuthExternalView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 05/01/2022.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Cocoa

class AuthExternalView: CommonModalView, LoadableNib {
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var hostLabel: NSTextField!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    override func modalWillShowWith(query: String, delegate: ModalViewDelegate) {
        super.modalWillShowWith(query: query, delegate: delegate)
        
        processQuery()
        
        hostLabel.stringValue = "\(authInfo?.host ?? "...")?"
    }
    
    override func modalDidShow() {
        super.modalDidShow()
    }
    
    override func didTapConfirmButton() {
        super.didTapConfirmButton()
        
        verifyExternal()
    }
    
    func verifyExternal() {
        API.sharedInstance.verifyExternal(callback: { success, object in
            if let object = object, let token = object["token"] as? String, let info = object["info"] as? [String: AnyObject] {
                self.authInfo?.token = token
                self.authInfo?.info = info
                self.signBase64()
            }
        })
    }
    
    func signBase64() {
        API.sharedInstance.signBase64(b64: "U3BoaW54IFZlcmlmaWNhdGlvbg==", callback: { sig in
            if let sig = sig {
                self.authInfo?.verificationSignature = sig
                self.authorize()
            }
        })
    }
    
    func authorize() {
        if let host = authInfo?.host,
           let challenge = authInfo?.challenge,
           let verificationSignature = authInfo?.verificationSignature,
           let token = authInfo?.token,
           var info = authInfo?.info {
            
            info["url"] = UserData.sharedInstance.getNodeIP() as AnyObject
            info["verification_signature"] = verificationSignature as AnyObject
            
            API.sharedInstance.authorizeExternal(host: host, challenge: challenge, token: token, params: info, callback: { success in
                self.authorizationDone(success: success, host: host)
            })
        }
    }
    
    func authorizationDone(success: Bool, host: String) {
        if success {
            if let host = authInfo?.host, let challenge = authInfo?.challenge, let url = URL(string: "https://\(host)?challenge=\(challenge)") {
                NSWorkspace.shared.open(url)
            }
        } else {
            messageBubbleHelper.showGenericMessageView(text: "authorization.failed".localized, delay: 5, textColor: NSColor.white, backColor: NSColor.Sphinx.BadgeRed, backAlpha: 1.0)
        }
        delegate?.shouldDismissModals()
    }
}
