//
//  EncryptionManager.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/12/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation

class EncryptionManager {
    
    let KEY_SIZE: CryptorRSA.RSAKey.KeySize = CryptorRSA.RSAKey.KeySize(bits: 2048)
    let PUBLIC_KEY = "public.com.stakwork.sphinx-desktop"
    let PRIVATE_KEY = "private.com.stakwork.sphinx-desktop"
    
    class var sharedInstance : EncryptionManager {
        struct Static {
            static let instance = EncryptionManager()
        }
        return Static.instance
    }
    
    let userData = UserData.sharedInstance
    
    var ownPrivateKey: SecKey? {
        get {
            return retrieveKey(keyClass: kSecAttrKeyClassPrivate, tag: PRIVATE_KEY)
        }
        set {
            saveKey(key: newValue, keyClass: kSecAttrKeyClassPrivate, tag: PRIVATE_KEY)
        }
    }

    var ownPublicKey: SecKey? {
        get {
            return retrieveKey(keyClass: kSecAttrKeyClassPublic, tag: PUBLIC_KEY)
        }
        set {
            saveKey(key: newValue, keyClass: kSecAttrKeyClassPublic, tag: PUBLIC_KEY)
        }
    }
    
    func deleteKey(keyClass: CFString, tag: String) -> Bool {
        let query: [String: Any] = [
            String(kSecClass)              : kSecClassKey,
            String(kSecAttrKeyClass)       : keyClass,
            String(kSecAttrKeyType)        : kSecAttrKeyTypeRSA,
            String(kSecReturnRef)          : true as Any,
            String(kSecAttrApplicationTag) : tag,
            String(kSecAttrLabel)          : tag,
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess {
            return false
        }
        return true
    }
    
    func saveKey(key: SecKey?, keyClass: CFString, tag: String) {
        if let key = key {
            let attribute = [
                String(kSecClass)              : kSecClassKey,
                String(kSecAttrKeyClass)       : keyClass,
                String(kSecAttrKeyType)        : kSecAttrKeyTypeRSA,
                String(kSecValueRef)           : key,
                String(kSecReturnPersistentRef): true,
                String(kSecAttrApplicationTag) : tag,
                String(kSecAttrLabel)          : tag,
                ] as [String : Any]

            let status = SecItemAdd(attribute as CFDictionary, nil)

            if status != noErr {
                return
            }
        }
    }

    func retrieveKey(keyClass: CFString, tag: String) -> SecKey? {
        let query: [String: Any] = [
            String(kSecClass)              : kSecClassKey,
            String(kSecAttrKeyClass)       : keyClass,
            String(kSecAttrKeyType)        : kSecAttrKeyTypeRSA,
            String(kSecReturnRef)          : true as Any,
            String(kSecAttrApplicationTag) : tag,
            String(kSecAttrLabel)          : tag,
        ]

        var result : AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            return result as! SecKey?
        }
        return nil
    }
    
    func deleteOldKeys() {
        let _ = deleteKey(keyClass: kSecAttrKeyClassPublic, tag: PUBLIC_KEY)
        let _ = deleteKey(keyClass: kSecAttrKeyClassPrivate, tag: PRIVATE_KEY)
    }
    
    func getOrCreateKeys(completion: (() -> ())? = nil) -> (CryptorRSA.PrivateKey?, CryptorRSA.PublicKey?) {
        let (privateKey, publicKey) = getKeysFromReferences()

        if let privateKey = privateKey, let publicKey = publicKey {
            saveKeysOnKeychain()
            sendPublicKeyToServer(completion: completion)
            return (privateKey, publicKey)
        }
        
        if let owner = UserContact.getOwner(), let contactKey = owner.contactKey, !contactKey.isEmpty {
            let keychainRestoredKeys = restoreFromKeychain()

            if let privateKey = keychainRestoredKeys.0, let publicKey = keychainRestoredKeys.1 {

                ownPublicKey = publicKey.reference
                ownPrivateKey = privateKey.reference

                return (privateKey, publicKey)
            }
        }
        
        var keyPair : (privateKey: CryptorRSA.PrivateKey, publicKey: CryptorRSA.PublicKey)?
        
        do {
            keyPair = try CryptorRSA.makeKeyPair(KEY_SIZE)
        } catch {
            return (nil, nil)
        }
        
        if let privateKey = keyPair?.privateKey, let publicKey = keyPair?.publicKey {
            let publicKeyString = getBase64String(key: publicKey)
            let privateKeyString = getBase64String(key: privateKey)
            
            deleteOldKeys()
            
            if let publicKeyString = publicKeyString, let privateKeyString = privateKeyString,
               let publicK = getPublicKeyFromBase64String(base64String: publicKeyString), let privateK = getPrivateKeyFromBase64String(base64String: privateKeyString) {
                
                ownPublicKey = publicK.reference
                ownPrivateKey = privateK.reference
                
                saveKeysOnKeychain()
                sendPublicKeyToServer(completion: completion)
                
                return (privateKey, publicKey)
            }
        }
        return (nil, nil)
    }
    
    func restoreFromKeychain() -> (CryptorRSA.PrivateKey?, CryptorRSA.PublicKey?) {
        let (privKeyString, pubKeyString) = userData.getEncryptionKeys()
        if let privKeyString = privKeyString, let pubKeyString = pubKeyString, !privKeyString.isEmpty && !pubKeyString.isEmpty {
            if let privateKey = getPrivateKeyFromBase64String(base64String: privKeyString), let publicKey = getPublicKeyFromBase64String(base64String: pubKeyString) {
                return (privateKey, publicKey)
            }
        }
        return (nil, nil)
    }
    
    func saveKeysOnKeychain() {
        if let publicKey = getOwnPublicKey(), let base64PublicKey = getBase64String(key: publicKey),
            let privateKey = getOwnPrivateKey(), let base64PrivateKey = getBase64String(key: privateKey) {
            let _  = userData.save(privateKey: base64PrivateKey, andPublicKey: base64PublicKey)
        }
    }
    
    func sendPublicKeyToServer(completion: (() -> ())? = nil) {
        if let publicKey = getOwnPublicKey(), let base64PublicKey = getBase64String(key: publicKey), let owner = UserContact.getOwner() {
            if let _ = owner.contactKey {
                return
            }

            UserContactsHelper.updateContact(contact: owner, contactKey: base64PublicKey, callback: { _ in
                completion?()
            })
        }
    }
    
    func getPublicKeyFromBase64String(base64String: String) -> CryptorRSA.PublicKey? {
        do {
            let userKey = try CryptorRSA.createPublicKey(withBase64: base64String)
            return userKey
        } catch {
            return nil
        }
    }
    
    func getPrivateKeyFromBase64String(base64String: String) -> CryptorRSA.PrivateKey? {
        do {
            let userKey = try CryptorRSA.createPrivateKey(withBase64: base64String)
            return userKey
        } catch {
            return nil
        }
    }
    
    func getKeysFromReferences() -> (CryptorRSA.PrivateKey?, CryptorRSA.PublicKey?) {
        if let privateKey = getOwnPrivateKey(), let publicKey = getOwnPublicKey() {
            return (privateKey, publicKey)
        }
        return (nil, nil)
    }
    
    func getOwnPrivateKey() -> CryptorRSA.PrivateKey? {
        guard let privateKeyReference = ownPrivateKey else {
            return getOwnPrivateKeyFromKeychain()
        }

        return CryptorRSA.PrivateKey(with: privateKeyReference)
    }
    
    func getOwnPrivateKeyFromKeychain() -> CryptorRSA.PrivateKey? {
        var privateKey : CryptorRSA.PrivateKey?
        
        guard let privateKeyString = userData.getEncryptionKeys().0, !privateKeyString.isEmpty else {
            return nil
        }
        
        privateKey = getPrivateKeyFromBase64String(base64String: privateKeyString)

        if let privateKey = privateKey {
            return privateKey
        }
        
        return nil
    }
    
    func getOwnPublicKey() -> CryptorRSA.PublicKey? {
        guard let publicKeyReference = self.ownPublicKey else {
            return nil
        }

        return CryptorRSA.PublicKey(with: publicKeyReference)
    }
    
    func getBase64String(key: CryptorRSA.RSAKey?) -> String? {
        guard let key = key else {
            return nil
        }
        
        do {
            let pem = try CryptorRSA.base64String(for: key.pemString)
            return pem
        } catch {
            return nil
        }
    }
    
    //Export Keys
    func getKeysStringForExport() -> (String?, String?) {
        if let publicKey = getOwnPublicKey(), let base64PublicKey = getBase64String(key: publicKey),
           let privateKey = getOwnPrivateKey(), let base64PrivateKey = getBase64String(key: privateKey) {
            return (base64PrivateKey, base64PublicKey)
        }
        return (nil, nil)
    }
    
    //ImportKeys
    func insertKeys(privateKey: String, publicKey: String) -> Bool {
        if let privatek = getPrivateKeyFromBase64String(base64String: privateKey),
            let publicK = getPublicKeyFromBase64String(base64String: publicKey) {
            
            ownPrivateKey = privatek.reference
            ownPublicKey = publicK.reference
            
            return true
        }
        return false
    }
    
    func encryptToken(token: String, key: CryptorRSA.PublicKey) -> String? {
        let (encrypted, encryptedToken) = encrypt(token: token, with: key.reference)
        if encrypted {
            return encryptedToken
        }
        return nil
    }
    
    //Encrypting messages
    func encryptMessageForOwner(message: String) -> String {
        if let owner = UserContact.getOwner() {
            return encryptMessage(message: message, for: owner).1
        }
        return message
    }
    
    func encryptMessage(message: String, for contact: UserContact) -> (Bool, String) {
        guard let contactKey = contact.contactKey, let key = getPublicKeyFromBase64String(base64String: contactKey) else {
            return (false, message)
        }

        return encryptMessage(message: message, key: key)
    }
    
    func encryptMessage(message: String, groupKey: String) -> (Bool, String) {
        guard let key = getPublicKeyFromBase64String(base64String: groupKey) else {
            return (false, message)
        }
        return encryptMessage(message: message, key: key)
    }
    
    func encryptMessage(message: String, key: CryptorRSA.PublicKey) -> (Bool, String) {
        return encrypt(message: message, with: key.reference)
    }
    
    public func encrypt(
        token: String,
        with key: SecKey
    ) -> (Bool, String) {
        guard let messageData = token.data(using: String.Encoding.utf8) else {
            return (false, token)
        }
        
        guard let encryptData = SecKeyCreateEncryptedData(key, SecKeyAlgorithm.rsaEncryptionPKCS1, messageData as CFData, nil) else {
            return (false, token)
        }

        let encryptedData = encryptData as Data
        let encrypted = CryptorRSA.createEncrypted(with: encryptedData)
        return (true, encrypted.base64String)
    }
    
    public func encrypt(
        message: String,
        with key: SecKey
    ) -> (Bool, String) {
        let blockSize = SecKeyGetBlockSize(key)
        let maxChunkSize: Int = blockSize - 11
        
        guard let messageData = message.data(using: String.Encoding.utf8) else {
            return (false, message)
        }
        
        var decryptedDataAsArray = [UInt8](repeating: 0, count: messageData.count)
        (messageData as NSData).getBytes(&decryptedDataAsArray, length: messageData.count)
        
        var encryptedDataBytes = [UInt8](repeating: 0, count: 0)
        var idx = 0
        while idx < decryptedDataAsArray.count {
            
            let idxEnd = min(idx + maxChunkSize, decryptedDataAsArray.count)
            let chunkData = [UInt8](decryptedDataAsArray[idx..<idxEnd])
            
            if let cfData = CFDataCreate(nil, chunkData, chunkData.count) {
                guard let encryptData = SecKeyCreateEncryptedData(key, SecKeyAlgorithm.rsaEncryptionPKCS1, cfData, nil) else {
                    return (false, message)
                }
                
                encryptedDataBytes += encryptData as Data
                idx += maxChunkSize
            }
        }
        
        let encryptedData = Data(bytes: UnsafePointer<UInt8>(encryptedDataBytes), count: encryptedDataBytes.count)
        let encrypted = CryptorRSA.createEncrypted(with: encryptedData)
        return (true, encrypted.base64String)
    }
    
    public func decrypt(message: String, with key: SecKey) -> (Bool, String) {
        let blockSize = SecKeyGetBlockSize(key)
        
        guard let messageData = Data(base64Encoded: message) else {
            return (false, message)
        }
        
        var encryptedDataAsArray = [UInt8](repeating: 0, count: messageData.count)
        (messageData as NSData).getBytes(&encryptedDataAsArray, length: messageData.count)
        
        var decryptedDataBytes = [UInt8](repeating: 0, count: 0)
        var idx = 0
        while idx < encryptedDataAsArray.count {
            
            let idxEnd = min(idx + blockSize, encryptedDataAsArray.count)
            let chunkData = [UInt8](encryptedDataAsArray[idx..<idxEnd])
            
            if let cfData = CFDataCreate(nil, chunkData, chunkData.count) {
                guard let decryptData = SecKeyCreateDecryptedData(key, SecKeyAlgorithm.rsaEncryptionPKCS1, cfData, nil) else {
                    return (false, message)
                }
                
                decryptedDataBytes += decryptData as Data
                idx += blockSize
            }
        }
        
        let decryptedData = Data(bytes: UnsafePointer<UInt8>(decryptedDataBytes), count: decryptedDataBytes.count)
        return (true, String(decoding: decryptedData, as: UTF8.self))
    }
    
    func decryptMessage(message: String) -> (Bool, String) {
        guard let privateKeyReference = getOwnPrivateKey()?.reference else {
            return (false, message)
        }
        
        return decrypt(message: message, with: privateKeyReference)
    }
    
    public static func randomString(length: Int) -> String {
        let uuidString = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        
        return String(
            Data(uuidString.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .prefix(length)
        )
    }
}
