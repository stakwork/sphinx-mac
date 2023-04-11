//
//  ChoosePaymentModeVC.swift
//  Sphinx
//
//  Created by James Carucci on 4/11/23.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation
import Cocoa


protocol ChoosePaymentModeVCDelegate{
    func handleReceiveClick()
    func handleSentClick()
}

class ChoosePaymentModeVC : NSViewController{
    
    @IBOutlet weak var sendPaymentButton: NSView!
    @IBOutlet weak var receivePaymentButton: NSView!
    var delegate:ChoosePaymentModeVCDelegate? = nil
    
    static func instantiate(delegate:ChoosePaymentModeVCDelegate) -> ChoosePaymentModeVC {
        let viewController = StoryboardScene.Payments.choosePaymentModeVC.instantiate()
        viewController.delegate = delegate
        return viewController
    }
    
    override func viewDidLoad() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
            self.view.addSubview(self.sendPaymentButton)
            self.view.addSubview(self.receivePaymentButton)
        })
        
        sendPaymentButton.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(handleSendClick)))
        receivePaymentButton.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(handleReceiveClick)))
    }
    
    @objc func handleReceiveClick(){
        delegate?.handleReceiveClick()
    }
    
    @objc func handleSendClick(){
        delegate?.handleSentClick()
    }
    
}
