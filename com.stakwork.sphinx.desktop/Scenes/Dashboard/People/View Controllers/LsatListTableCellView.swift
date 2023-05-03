//
//  LsatListTableCellView.swift
//  Sphinx
//
//  Created by James Carucci on 5/2/23.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol LsatListCellDelegate{
    func deleteLsat(index:Int)
    func copyLsat(index:Int)
}


class LsatListTableCellView: NSTableCellView {

    @IBOutlet weak var cellLabel: NSTextField!
    @IBOutlet weak var copyLabel: NSTextField!
    @IBOutlet weak var deleteLabel: NSTextField!
    @IBOutlet weak var paymentRequestLabel: NSTextField!
    
    var delegate : LsatListCellDelegate? = nil
    var index : Int? = nil
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    func configureWith(lsat:LSATObject,index:Int){
        self.cellLabel.stringValue = lsat.identifier ?? "Unknown ID"
        self.paymentRequestLabel.stringValue = lsat.preImage ?? "Unknown Preimage string"
        self.index = index
        copyLabel.isSelectable = true
        deleteLabel.isSelectable = true
        copyLabel.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(handleCopy)))
        deleteLabel.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(handleDelete)))
    }
    
    @objc func handleCopy(){
        print("copying")
        if let index = index{
            delegate?.copyLsat(index: index)
        }
    }
    
    @objc func handleDelete(){
        print("delete")
        if let index = index{
            delegate?.deleteLsat(index: index)
        }
    }
    
}
