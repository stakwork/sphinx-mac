//
//  LsatListViewModel.swift
//  Sphinx
//
//  Created by James Carucci on 5/2/23.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation
import Cocoa



class LsatListViewModel : NSObject{
    var vc : LsatListViewController
    var tableView : NSTableView
    var lsatList : [LSATObject] = []
    
    
    init(vc:LsatListViewController,tableView:NSTableView){
        self.vc = vc
        self.tableView = tableView
        tableView.register(NSNib(nibNamed: "LsatListTableCellView", bundle: nil), forIdentifier: NSUserInterfaceItemIdentifier(rawValue: "LsatListTableCellView"))
    }
    
    func setupTableView(lsatsList:[LSATObject]){
        tableView.delegate = self
        tableView.dataSource = self
        self.lsatList = lsatsList
//        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("LsatListTableCellView"))
//        column.title = "LsatListTableCellView"
//        tableView.addTableColumn(column)
        tableView.tableColumns.first?.identifier = NSUserInterfaceItemIdentifier(rawValue: "LsatListTableCellView")

        
        tableView.reloadData()
    }
    
}

extension LsatListViewModel: NSTableViewDelegate, NSTableViewDataSource{
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 120.0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        print("hi")
        guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "LsatListTableCellView"), owner: self) as? LsatListTableCellView else { return nil }
        cell.configureWith(lsat: lsatList[row], index: row)
        cell.delegate = self
//        cell.backgroundColor = tableView.backgroundColor
//        cell.delegate = self
//        cell.index = row
        return cell
    }
    
    func tableView(_ tableView: NSTableView, didClick tableColumn: NSTableColumn) {
        print(tableColumn)
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return lsatList.count
    }
    
    func numberOfColumns(in tableView:NSTableView) -> Int{
        return 1
    }
}

extension LsatListViewModel : LsatListCellDelegate{
    func deleteLsat(index: Int) {
        AlertHelper.showTwoOptionsAlert(
            title: "Are you sure you want to delete this L402 credential?",
            message: "",
            confirm: {
                print("calling delete LSAT API")
                API.sharedInstance.deleteLsat(
                    lsat: self.lsatList[index],
                    callback: {
                        NewMessageBubbleHelper().showGenericMessageView(text: "Deletion succeeded.", in: nil)
                        self.lsatList.remove(at: index)
                        self.tableView.reloadData()
                    },
                    errorCallback: {
                        NewMessageBubbleHelper().showGenericMessageView(text: "Error deleting L402 data please try again.", in: nil)
                    })
            },
            cancel: {
                print("cancelling deletion")
            },
            confirmLabel: "Delete",
            cancelLabel: "Cancel"
        )
    }
    
    func debugLsat(index: Int) {
        let lsat = lsatList[index]
        var preamble = "LSAT"
        if let preimage = lsat.preImage,
           let macaroon = lsat.macaroon{
            preamble += " \(macaroon):\(preimage)"
            ClipboardHelper.copyToClipboard(text: preamble)
        }
        else{
            NewMessageBubbleHelper().showGenericMessageView(text: "Error copying L402 data please try again.", in: nil)
        }
    }
    
    func copyLsat(index: Int) {
        let lsat = lsatList[index]
        if let jsonString = lsat.toJSONString(prettyPrint: true){
            var preamble = ""
            preamble += "JSON:\n\(jsonString)"
            ClipboardHelper.copyToClipboard(text: preamble)
        }
        else{
            NewMessageBubbleHelper().showGenericMessageView(text: "Error copying L402 data please try again.", in: nil)
        }
    }
}
