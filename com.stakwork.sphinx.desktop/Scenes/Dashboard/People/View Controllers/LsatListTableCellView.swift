//
//  LsatListTableCellView.swift
//  Sphinx
//
//  Created by James Carucci on 5/2/23.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class LsatListTableCellView: NSTableCellView {

    @IBOutlet weak var cellLabel: NSTextField!
    @IBOutlet weak var copyLabel: NSTextField!
    @IBOutlet weak var deleteLabel: NSTextField!
    @IBOutlet weak var paymentRequestLabel: NSTextField!
    
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    func configureWith(lsat:LSATObject){
        self.cellLabel.stringValue = lsat.identifier ?? "Unknown ID"
        self.paymentRequestLabel.stringValue = lsat.paymentRequest ?? "Unknown PR string"
        
        copyLabel.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(handleCopy)))
        deleteLabel.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(handleDelete)))
    }
    
    @objc func handleCopy(){
        print("copying")
    }
    
    @objc func handleDelete(){
        print("delete")
    }
    
}
