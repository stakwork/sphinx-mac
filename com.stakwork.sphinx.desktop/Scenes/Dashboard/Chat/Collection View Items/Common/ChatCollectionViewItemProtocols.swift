//
//  ChatCollectionViewItemProtocols.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 01/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation

protocol MessageRowProtocol: AnyObject {
    var delegate: MessageCellDelegate? { get set }
    var audioDelegate: AudioCellDelegate? { get set }
    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat)
}

protocol GroupActionRowProtocol: AnyObject {
    var delegate: GroupRowDelegate? { get set }
    func configureMessage(message: TransactionMessage)
}

protocol MediaUploadingProtocol: AnyObject {
    func isUploading() -> Bool
    func configureUploadingProgress(progress: Int, finishUpload: Bool)
}
