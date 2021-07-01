//
//  NSImage.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 09/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

extension NSImage {
    static func qrCode(from string: String, size: CGSize) -> NSImage? {
        let stringData = string.data(using: .isoLatin1)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(stringData, forKey: "inputMessage")
        filter?.setValue("H", forKey: "inputCorrectionLevel")
        
        let scale = CGAffineTransform(scaleX: 10, y: 10)
        if let output = filter?.outputImage?.transformed(by: scale) {
            let rep = NSCIImageRep(ciImage: output)
            let nsImage = NSImage(size: rep.size)
            nsImage.addRepresentation(rep)
            return nsImage
        }
        return nil
    }
    
    func image(withTintColor tintColor: NSColor) -> NSImage {
        guard isTemplate else { return self }
        guard let copiedImage = self.copy() as? NSImage else { return self }
        copiedImage.lockFocus()
        tintColor.set()
        let imageBounds = NSMakeRect(0, 0, copiedImage.size.width, copiedImage.size.height)
        imageBounds.fill(using: .sourceAtop)
        copiedImage.unlockFocus()
        copiedImage.isTemplate = false
        return copiedImage
    }
}
