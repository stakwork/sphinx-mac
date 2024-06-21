//
//  Cache.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 18/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation

final class SphinxCache {
    func insert(_ value: Data, forKey key: String) {
        let _ = saveToDisk(value, forKey: key)
    }

    func value(forKey key: String) -> Data? {
        if let diskData = getFromDisk(forKey: key) {
            return diskData
        }
        return nil
    }

    func removeValue(forKey key: String) {
        let _ = removeFromDisk(forKey: key)
    }
}

extension SphinxCache {
    func saveToDisk(_ data: Data, forKey key: String, using fileManager: FileManager = .default) -> Bool {
        if let fileURL = getFileUrlFrom(key: key) {
            do {
                try data.write(to: fileURL)
                return true
            } catch let error {
                print(error)
            }
        }
        return false
    }
    
    func getFromDisk(forKey key: String, using fileManager: FileManager = .default) -> Data? {
        if let fileURL = getFileUrlFrom(key: key) {
            return MediaLoader.getDataFromUrl(url: fileURL)
        }
        return nil
    }
    
    func removeFromDisk(forKey key: String, using fileManager: FileManager = .default) -> Bool {
        if let fileURL = getFileUrlFrom(key: key) {
            do {
                try fileManager.removeItem(at: fileURL)
                return true
            } catch let error {
                print(error)
            }
        }
        return false
    }
    
    func getFileUrlFrom(key: String, using fileManager: FileManager = .default) -> URL? {
        if let path = URL(string: key)?.path {
            let name = path.replacingOccurrences(of: "/file/", with: "")
                            .replacingOccurrences(of: "/media/", with: "")
                            .replacingOccurrences(of: "/", with: "")
                            .replacingOccurrences(of: ".", with: "")
            
            let folderURLs = fileManager.urls (
                for: .cachesDirectory,
                in: .userDomainMask
            )
            let fileURL = folderURLs[0].appendingPathComponent(name + ".cache")
            return fileURL
        }
        
        return nil
    }
    
    func removeAll(using fileManager: FileManager = .default) {
        let folderURLs = fileManager.urls (
            for: .cachesDirectory,
            in: .userDomainMask
        )
        
        if folderURLs.count > 0 {
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(
                    at: folderURLs[0],
                    includingPropertiesForKeys: nil,
                    options: .skipsHiddenFiles
                )
                
                for fileURL in fileURLs {
                    try FileManager.default.removeItem(at: fileURL)
                }
                
            } catch  { print(error) }
        }
    }
}

extension SphinxCache {
    subscript(key: String) -> Data? {
        get { return value(forKey: key) }
        set {
            guard let value = newValue else {
                removeValue(forKey: key)
                return
            }
            insert(value, forKey: key)
        }
    }
}
