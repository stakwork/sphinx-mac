//
//  String.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 05/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import AppKit

extension String {
    
    var localized: String {
        get {
            return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
        }
    }
    
    var withoutBreaklines: String {
        get {
            return self.replacingOccurrences(of: "\n", with: " ")
        }
    }
    
    var length: Int {
      return count
    }

    subscript (i: Int) -> String {
      return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> String {
      return self[fromIndex ..< length]
    }

    func substring(toIndex: Int) -> String {
      return self[0 ..< toIndex]
    }
    
    func charAt(index: Int) -> Character {
        let i = String.Index(utf16Offset: index, in: self)
        return self[i]
    }
    
    func substring(fromIndex: Int, toIndex: Int) -> String {
      return self[fromIndex ..< toIndex]
    }

    func substring(toIndexIncluded: Int) -> String {
        let end = String.Index(utf16Offset: toIndexIncluded, in: self)
        return String(self[...end])
    }
    
    func substring(fromIndex: Int, toIndexIncluded: Int) -> String {
      return self[fromIndex ..< toIndexIncluded]
    }
    
    mutating func insert(string:String,ind:Int) {
        self.insert(contentsOf: string, at:self.index(self.startIndex, offsetBy: ind) )
    }

    subscript (r: Range<Int>) -> String {
      let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                          upper: min(length, max(0, r.upperBound))))
      let start = index(startIndex, offsetBy: range.lowerBound)
      let end = index(start, offsetBy: range.upperBound - range.lowerBound)
      return String(self[start ..< end])
    }
    
    func starts(with prefixes: [String]) -> Bool {
        for prefix in prefixes where starts(with: prefix) {
            return true
        }
        return false
    }
    
    func trunc(length: Int) -> String {
        return (self.count > length) ? String(self.prefix(length)) : self
    }
    
    func toJSON() -> Any? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }
    
    func fixInvoiceString() -> String {
        var fixedInvoice = self
        
        let prefixes = PaymentRequestDecoder.prefixes
        for prefix in prefixes {
            if self.contains(prefix) {
                if let index = self.range(of: prefix)?.lowerBound {
                    let indexInt = index.utf16Offset(in: self)
                    fixedInvoice = self.substring(fromIndex: indexInt, toIndex: self.length)
                }
            }
        }
        return fixedInvoice
    }
    
    var fixedRestoreCode : String {
        get {
            let codeWithoutSpaces = self.replacingOccurrences(of: "\\n", with: "")
                                        .replacingOccurrences(of: "\\r", with: "")
                                        .replacingOccurrences(of: "\\s", with: "")
                                        .replacingOccurrences(of: " ", with: "")
            
            let fixedCode = codeWithoutSpaces.filter("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=".contains)
            
            return fixedCode
        }
    }
    
    func removeProtocol() -> String {
        return self.replacingOccurrences(of: "http://", with: "").replacingOccurrences(of: "https://", with: "")
    }
    
    func decodeUrl() -> String? {
        return self.removingPercentEncoding
    }
    
    var isRelayQRCode : Bool {
        get {
            return self.base64Decoded?.starts(with: "ip::") ?? false
        }
    }
    
    func getIPAndPassword() -> (String?, String?) {
        if let decodedString = self.base64Decoded, decodedString.starts(with: "ip::") {
            let stringWithoutPrefix = decodedString.replacingOccurrences(of: "ip::", with: "")
            let items = stringWithoutPrefix.components(separatedBy: "::")
            
            if items.count == 2 {
                return (items[0], items[1])
            }
        }
        return (nil, nil)
    }
    
    var isRestoreKeysString : Bool {
        get {
            return self.base64Decoded?.starts(with: "keys::") ?? false
        }
    }
    
    func getRestoreKeys() -> String? {
        if let decodedString = self.base64Decoded, decodedString.starts(with: "keys::") {
            let stringWithoutPrefix = decodedString.replacingOccurrences(of: "keys::", with: "")
            return stringWithoutPrefix
        }
        return nil
    }
    
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    func isEncryptedString() -> Bool {
        if let _ = Data(base64Encoded: self), self.hasSuffix("=") {
            return true
        }
        return false
    }
    
    func getBytesLength() -> Int {
        return self.utf8.count
    }
    
    func isValidLengthMemo() -> Bool {
        return getBytesLength() <= 639
    }
    
    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
    
    var percentEscaped: String? {
        return self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
    }
    
    var percentNotEscaped: String? {
        return NSString(string: self).removingPercentEncoding
    }
    
    var stringLinks: [NSTextCheckingResult] {
        if !self.contains(".") {
            return []
        }
        let types: NSTextCheckingResult.CheckingType = [.link]
        let detector = try? NSDataDetector(types: types.rawValue)
        let matches = detector!.matches(in: self, options: .reportCompletion, range: NSMakeRange(0, self.utf16.count))
        return matches

    }
    
    var pubKeyMatches: [NSTextCheckingResult] {
        let pubkeyRegex = try? NSRegularExpression(pattern: "\\b[A-F0-9a-f]{66}\\b")
        let virtualPubkeyRegex = try? NSRegularExpression(pattern: "\\b[A-F0-9a-f]{66}:[A-F0-9a-f]{66}:[0-9]+\\b")
        
        let virtualPubkeyResults = virtualPubkeyRegex?.matches(in: self, range: NSRange(self.startIndex..., in: self)) ?? []
        if virtualPubkeyResults.count > 0 { return virtualPubkeyResults }
        
        let pubkeyResults = pubkeyRegex?.matches(in: self, range: NSRange(self.startIndex..., in: self)) ?? []
        return pubkeyResults
    }
    
    var stringFirstLink : String {
        if let range = self.stringLinks.first?.range {
            let matchString = (self as NSString).substring(with: range) as String
            return matchString
        }
        return ""
    }
    
    var stringFirstTribeLink : String {
        for link in self.stringLinks {
            let range = link.range
            let matchString = (self as NSString).substring(with: range) as String
            if matchString.starts(with: "sphinx.chat://?action=tribe") {
                return matchString
            }
        }
        return ""
    }
    
    var stringFirstPubKey : String {
        if let range = self.pubKeyMatches.first?.range {
            let matchString = (self as NSString).substring(with: range) as String
            return matchString
        }
        return ""
    }
    
    var hasLinks: Bool {
        if self.isVideoCallLink {
            return false
        }
        
        if stringLinks.count == 0 {
            return false
        }
        
        for link in stringLinks {
            let matchString = (self as NSString).substring(with: link.range) as String
            if matchString.isValidEmail || matchString.starts(with: "sphinx.chat://") {
                return false
            }
        }
        return !hasTribeLinks && !hasPubkeyLinks
    }
    
    var hasTribeLinks: Bool {
        for link in stringLinks {
            let matchString = (self as NSString).substring(with: link.range) as String
            if matchString.starts(with: "sphinx.chat://?action=tribe") {
                return true
            }
        }
        return false
    }
    
    var hasPubkeyLinks: Bool {
        return pubKeyMatches.count > 0 && !hasTribeLinks
    }
    
    var isPubKey : Bool {
        get {
            let pubkeyRegex = try? NSRegularExpression(pattern: "^[A-F0-9a-f]{66}$")
            return (pubkeyRegex?.matches(in: self, range: NSRange(self.startIndex..., in: self)) ?? []).count > 0 || self.isVirtualPubKey
        }
    }
    
    var isVirtualPubKey : Bool {
         get {
             let completePubkeyRegex = try? NSRegularExpression(pattern: "^[A-F0-9a-f]{66}:[A-F0-9a-f]{66}:[0-9]+$")
             return (completePubkeyRegex?.matches(in: self, range: NSRange(self.startIndex..., in: self)) ?? []).count > 0
         }
     }
     
     var pubkeyComponents : (String, String) {
         get {
             let components = self.components(separatedBy: ":")
             if components.count >= 3 {
                 return (components[0], self.replacingOccurrences(of: components[0] + ":", with: ""))
             }
             return (self, "")
         }
     }
     
     func isExistingContactPubkey() -> (Bool, UserContact?) {
        let pubkey = self.stringFirstPubKey
        let (pk, _) = pubkey.pubkeyComponents
        if let contact = UserContact.getContactWith(pubkey: pk), !contact.fromGroup {
            return (true, contact)
        }
        if let owner = UserContact.getOwner(), owner.publicKey == pk {
            return (true, owner)
        }
        return (false, nil)
    }
    
    var isInviteCode : Bool {
        get {
            let regex = try? NSRegularExpression(pattern: "^[A-F0-9a-f]{40}$")
            return (regex?.matches(in: self, range: NSRange(self.startIndex..., in: self)) ?? []).count > 0
        }
    }
    
    var isLNDInvoice : Bool {
        get {
            let prDecoder = PaymentRequestDecoder()
            prDecoder.decodePaymentRequest(paymentRequest: self)
            return prDecoder.isPaymentRequest()
        }
    }
    
    var amountWithoutSpaces: String {
        return self.replacingOccurrences(of: " ", with: "")
    }
    
    var base64Decoded : String? {
        if let decodedData = Data(base64Encoded: self) {
            if let decodedString = String(data: decodedData, encoding: .utf8) {
                return decodedString
            }
        }
        return nil
    }
    
    var base64Encoded : String? {
        return Data(self.utf8).base64EncodedString()
    }
    
    var dataFromString : Data? {
        return Data(base64Encoded: self.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/"))
    }
    
    var lowerClean : String {
        return self.trim().lowercased()
    }
    
    var callServer : String {
        if let range = self.lowerClean.range(of: "sphinx.call.") {
            let room = self.lowerClean[..<range.lowerBound]
            return String(room)
        }
        return self.lowerClean
    }
    
    var callRoom : String {
        if let range = self.lowerClean.range(of: "sphinx.call.") {
            let room = self.lowerClean[range.lowerBound..<self.endIndex]
            return String(room)
        }
        return self.lowerClean
    }
    
    var isVideoCallLink: Bool {
        get {
            return self.lowerClean.starts(with: "http") && self.lowerClean.contains(TransactionMessage.kCallRoomName)
        }
    }
    
    var isGiphy: Bool {
        get {
            if self.starts(with: GiphyHelper.kPrefix) {
                if let _ = self.replacingOccurrences(of: GiphyHelper.kPrefix, with: "").base64Decoded {
                    return true
                }
            }
            return false
        }
    }
    
    var isPodcastComment: Bool {
        get {
            return self.starts(with: PodcastPlayerHelper.kClipPrefix)
        }
    }
    
    var isPodcastBoost: Bool {
        get {
            return self.starts(with: PodcastPlayerHelper.kBoostPrefix)
        }
    }
    
    var podcastId: Int {
        get {
            let components = self.components(separatedBy: ":")
            if components.count > 1 {
                let value = components[1]
                
                if let id = Int(value) {
                    return id
                }
            }
            return -1
        }
    }
    
    var tribeUUIDAndHost: (String?, String?) {
        get {
            let components = self.components(separatedBy: ":")
            if components.count > 1 {
                let uuid = components[1]
                let host = (components.count > 2) ? components[2] : nil
                
                return (uuid, host)
            }
            return (nil, nil)
        }
    }
    
    var isValidEmail: Bool {
        get {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            return emailPred.evaluate(with: self)
        }
    }
    
    var abbreviatedLink : String {
        if self.length > 30 {
            let first25 = String(self.prefix(20))
            let last5 = String(self.suffix(5))
            
            return "\(first25)...\(last5)"
        }
        return self
    }
    
    func getNameStyleString() -> String {
        if self == "" {
            return "Unknown"
        }
        
        let names = self.split(separator: " ")
        var namesString = ""
        var namesCount = 0
        
        for name in names {
            if namesCount == 0 {
                namesString = "\(name)"
                namesCount += 1
            } else if namesCount == 1 {
                namesString = "\(namesString)\n\(name)"
                namesCount += 1
            } else {
                namesString = "\(namesString) \(name)"
            }
        }
        
        return namesString.uppercased()
    }
    
    func getFirstNameStyleString() -> String {
        let names = self.split(separator: " ")
        if names.count > 0 {
            return String(names[0])
        }
        return "Unknown"
    }
    
    func getInitialsFromName() -> String{
        let names = self.trim().components(separatedBy: " ")
        if names.count > 1 {
            if names[0].length > 0 && names[1].length > 0 {
                return String(names[0].trim().charAt(index: 0)) + String(names[1].trim().charAt(index: 0)).uppercased()
            }
        }
        if names.count > 0 {
            if names[0].length > 0 {
                return String(names[0].trim().charAt(index: 0)).uppercased()
            }
        }
        return ""
    }
    
    func removeDuplicatedProtocol() -> String {
        let urlWithoutHTTPProtocol = self.replacingOccurrences(of: "http://", with: "")
        if urlWithoutHTTPProtocol.contains("http") {
            return urlWithoutHTTPProtocol
        }
        let urlWithoutHTTPSProtocol = self.replacingOccurrences(of: "https://", with: "")
        if urlWithoutHTTPSProtocol.contains("http") {
            return urlWithoutHTTPSProtocol
        }
        return self
    }
    
    func withDefaultValue(_ defaultValue:String) -> String {
        if self.isEmpty {
            return defaultValue
        }
        return self
    }
    
    public static func getAttributedText(string: String,
                                         boldStrings: [String],
                                         font: NSFont,
                                         boldFont: NSFont,
                                         color: NSColor = NSColor.white) -> NSAttributedString {
        
        let style = NSMutableParagraphStyle()
        style.alignment = NSTextAlignment.center
        
        let normalFont = font
        let stringRange = (string as NSString).range(of: string)
        let attributedString = NSMutableAttributedString(string: string)
        attributedString.addAttribute(.foregroundColor, value: color, range: stringRange)
        attributedString.addAttribute(.font, value: normalFont, range: stringRange)
        attributedString.addAttribute(.paragraphStyle, value: style, range: stringRange)
        
        for boldString in boldStrings {
            let boldRange = (string as NSString).range(of: boldString)
            attributedString.addAttribute(.font, value: boldFont, range: boldRange)
        }
        
        return attributedString
    }
    
    func mimeType() -> String {
        let url = NSURL(fileURLWithPath: self)
        let pathExtension = url.pathExtension

        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
    
    func fileExtension() -> String {
        let components = self.components(separatedBy: ".")
        if let fileExtension = components.last {
            return fileExtension
        }
        return "txt"
    }
    
    var isSingleEmoji: Bool { count == 1 && containsEmoji }

    var containsEmoji: Bool { contains { $0.isEmoji } }

    var containsOnlyEmoji: Bool { !isEmpty && !contains { !$0.isEmoji } }

    var emojiString: String { emojis.map { String($0) }.reduce("", +) }

    var emojis: [Character] { filter { $0.isEmoji } }

    var emojiScalars: [UnicodeScalar] { filter { $0.isEmoji }.flatMap { $0.unicodeScalars } }
}

extension Character {
    var isSimpleEmoji: Bool {
        guard let firstScalar = unicodeScalars.first else { return false }
        return firstScalar.properties.isEmoji && firstScalar.value > 0x238C
    }

    var isCombinedIntoEmoji: Bool { unicodeScalars.count > 1 && unicodeScalars.first?.properties.isEmoji ?? false }
    var isEmoji: Bool { isSimpleEmoji || isCombinedIntoEmoji }
}

extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        var indices: [Index] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                indices.append(range.lowerBound)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return indices
    }
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                result.append(range)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}
