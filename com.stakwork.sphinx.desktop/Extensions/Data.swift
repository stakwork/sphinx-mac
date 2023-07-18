//
//  Data.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 11/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import AVFoundation
import PDFKit

extension Data {
    var uint32: UInt32 {
        get {
            let value = UInt32(bigEndian: self.withUnsafeBytes { $0.load(as: UInt32.self) })
            return value
        }
    }
    
    var formattedSize : String {
        get {
            let bcf = ByteCountFormatter()
            bcf.allowedUnits = [.useAll]
            bcf.countStyle = .file
            return bcf.string(fromByteCount: Int64(self.count))
        }
    }
    
    func isAnimatedImage() -> Bool {
        if let source = CGImageSourceCreateWithData(self as CFData, nil) {
            let count = CGImageSourceGetCount(source)
            return count > 1
        }
        return false
    }
    
    func createGIFAnimation() -> CAKeyframeAnimation? {
        guard let src = CGImageSourceCreateWithData(self as CFData, nil) else { return nil }
        let frameCount = CGImageSourceGetCount(src)

        var time : Float = 0

        var framesArray = [AnyObject]()
        var tempTimesArray = [NSNumber]()

        for i in 0..<frameCount {
            var frameDuration : Float = 0.1;

            let cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(src, i, nil)
            guard let framePrpoerties = cfFrameProperties as? [String:AnyObject] else {return nil}
            guard let gifProperties = framePrpoerties[kCGImagePropertyGIFDictionary as String] as? [String:AnyObject]
                else { return nil }

            if let delayTimeUnclampedProp = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber {
                frameDuration = delayTimeUnclampedProp.floatValue
            } else {
                if let delayTimeProp = gifProperties[kCGImagePropertyGIFDelayTime as String] as? NSNumber {
                    frameDuration = delayTimeProp.floatValue
                }
            }

            if frameDuration < 0.011 {
                frameDuration = 0.100;
            }

            if let frame = CGImageSourceCreateImageAtIndex(src, i, nil) {
                tempTimesArray.append(NSNumber(value: frameDuration))
                framesArray.append(frame)
            }

            time = time + frameDuration
        }

        var timesArray = [NSNumber]()
        var base : Float = 0
        for duration in tempTimesArray {
            timesArray.append(NSNumber(value: base))
            base += duration.floatValue / time
        }

        timesArray.append(NSNumber(value: 1.0))

        let animation = CAKeyframeAnimation(keyPath: "contents")

        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.duration = CFTimeInterval(time)
        animation.repeatCount = Float.greatestFiniteMagnitude;
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.values = framesArray
        animation.keyTimes = timesArray
        animation.calculationMode = CAAnimationCalculationMode.discrete

        return animation
    }
    
    func getPDFDescription(fileName: String, currentPage: Int) -> String? {
        if let pdf = PDFDocument(data: self) {
            let pageCount = pdf.pageCount
            return String(format: "pdf.description".localized, fileName, currentPage, pageCount)
        }
        return nil
    }
    
    func getPDFPagesCount() -> Int? {
        if let pdf = PDFDocument(data: self) {
            let pageCount = pdf.pageCount
            return pageCount
        }
        return nil
    }
    
    func getPDFImage(ofPage pageIndex: Int) -> NSImage? {
        if let pdf = PDFDocument(data: self) {
            let pdfDocumentPage = pdf.page(at: pageIndex)
            if let data = pdfDocumentPage?.dataRepresentation {
                return NSImage(data: data)
            }
        }
        return nil
    }
    
    func getPDFThumbnail() -> NSImage? {
        if let pdf = PDFDocument(data: self) {
            let pdfDocumentPage = pdf.page(at: 0)
            if let image = pdfDocumentPage?.thumbnail(of: CGSize(width: 250, height: CGFloat.greatestFiniteMagnitude), for: .cropBox) {
                return image
            }
        }
        return nil
    }
}
