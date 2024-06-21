//
//  NewMessageCollectionViewItem+StatusHeaderExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 20/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

extension NewMessageCollectionViewItem {
    func configureWith(
        statusHeader: BubbleMessageLayoutState.StatusHeader?,
        uploadProgressData: MessageTableCellState.UploadProgressData?
    ) {
        if let statusHeader = statusHeader {
            statusHeaderView.configureWith(
                statusHeader: statusHeader,
                uploadProgressData: uploadProgressData
            )
        }
    }
}
