//
//  ThreadCollectionView+StatusHeaderExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 27/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation

extension ThreadCollectionViewItem {
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
