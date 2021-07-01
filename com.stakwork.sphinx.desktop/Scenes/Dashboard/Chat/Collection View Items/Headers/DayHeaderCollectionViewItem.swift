//
//  DayHeaderCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 25/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class DayHeaderCollectionViewItem: NSCollectionViewItem {
    
    public static let kHeaderHeight: CGFloat = 40.0
    
    @IBOutlet weak var dateLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func configureCell(messageRow: TransactionMessageRow) {
        let date = messageRow.headerDate ?? Date()
        let (shouldShowMonth, shouldShowYear) = date.shouldShowMonthAndYear()
        
        if date.isToday() {
            dateLabel.stringValue = "today".localized
        } else if shouldShowMonth && shouldShowYear {
            dateLabel.stringValue = date.getStringDate(format: "EEEE MMMM dd, yyyy")
        } else if shouldShowMonth {
            dateLabel.stringValue = date.getStringDate(format: "EEEE MMMM dd")
        } else {
            dateLabel.stringValue = date.getStringDate(format: "EEEE dd")
        }
    }
}
