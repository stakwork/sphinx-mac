//
//  AttachmentItem.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 14/06/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa

enum AttachmentItemType {
    case video, image, pdf, gif
}
struct NewAttachmentItem {
    let previewImage: NSImage
    let previewType: AttachmentsManager.AttachmentType
    let previewData: Data?
    var previewURL: URL? = nil
}
