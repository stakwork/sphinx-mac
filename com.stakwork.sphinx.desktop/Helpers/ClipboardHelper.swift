//
//  ClipboardHelper.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 02/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class ClipboardHelper {
    
    public static func copyToClipboard(text: String, message: String? = "text.copied.clipboard".localized, bubbleContainer: NSView? = nil) {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(text, forType: .string)
        
        if let message = message {
            NewMessageBubbleHelper().showGenericMessageView(text: message, in: bubbleContainer)
        }
    }
    
    public static func addVcImageToClipboard(vc:NSViewController,bubbleContainer: NSView? = nil){
        
        /*
        var displayCount: UInt32 = 0;
        var result = CGGetActiveDisplayList(0, nil, &displayCount)
        if (result != CGError.success) {
            print("error: \(result)")
            return
        }
        let allocated = Int(displayCount)
        let activeDisplays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: allocated)
        result = CGGetActiveDisplayList(displayCount, activeDisplays, &displayCount)
        
        if (result != CGError.success) {
            print("error: \(result)")
            return
        }
           
        for i in 1...displayCount {
            let screenShot:CGImage = CGDisplayCreateImage(activeDisplays[Int(i-1)])!
            let bitmapRep = NSBitmapImageRep(cgImage: screenShot)
            let jpegData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:])!
            
            
            NSPasteboard.general.setData(jpegData, forType: .png)
        }
         */
        
        if let screenshot : NSImage = vc.view.bitmapImage(),
           let cgScreenshot :CGImage = screenshot.cgImage{
            let bitmapRep = NSBitmapImageRep(cgImage: cgScreenshot)
            let jpegData = bitmapRep.representation(using: NSBitmapImageRep.FileType.png, properties: [:])!
            NSPasteboard.general.setData(jpegData, forType: .png)
            
            NewMessageBubbleHelper().showGenericMessageView(text: "QR Code Copied to Clipboard", in: bubbleContainer)
        }
        
    }

    func CreateTimeStamp() -> Int32
    {
        return Int32(Date().timeIntervalSince1970)
    }
}


extension NSView {
    func bitmapImage() -> NSImage? {
        guard let rep = bitmapImageRepForCachingDisplay(in: bounds) else {
            return nil
        }
        cacheDisplay(in: bounds, to: rep)
        guard let cgImage = rep.cgImage else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: bounds.size)
    }
}
