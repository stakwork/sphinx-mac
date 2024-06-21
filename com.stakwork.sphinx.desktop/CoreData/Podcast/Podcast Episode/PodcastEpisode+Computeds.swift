// PodcastEpisode+Computeds.swift
//
// Created by CypherPoet.
// ✌️
//
    

import Foundation
import SwiftyJSON
import CoreData


extension PodcastEpisode {
    
    var isAvailable: Bool {
        get { ConnectivityHelper.isConnectedToInternet || isDownloaded }
    }
    
    var isDownloaded: Bool {
        get {
            if let fileName = getLocalFileName() {
                if let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
                    return FileManager.default.fileExists(atPath: path.path)
                }
            }
            return false
        }
    }
    
    var dateString : String?{
        let date = self.datePublished
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        if let valid_date = date{
            let dateString = formatter.string(from: valid_date)
            return dateString
        }
        return nil
    }
    
    var wasPlayed: Bool {
        get {
            return (UserDefaults.standard.value(forKey: "wasPlayed-\(itemID)") as? Bool) ?? false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "wasPlayed-\(itemID)")
        }
    }
    
    func getRemoteAudioUrl() -> URL? {
        guard let episodeUrl = urlPath, !episodeUrl.isEmpty else {
            return nil
        }
        return URL(string: episodeUrl)
    }
    
    func getLocalFileName() -> String? {
        let itemID = itemID
        
        guard let feedId = feed?.feedID, !feedId.isEmpty, !itemID.isEmpty else {
            return nil
        }
        
        return "\(feedId)_\(itemID).mp3"
    }
    
    func getAudioUrl() -> URL? {
        if let fileName = getLocalFileName() {
            
            if let path = FileManager
                .default
                .urls(for: .documentDirectory, in: .userDomainMask)
                .first?
                .appendingPathComponent(fileName) {
                
                if FileManager.default.fileExists(atPath: path.path) {
                    return path
                }
            }
        }
        return getRemoteAudioUrl()
    }
    
    func shouldDeleteFile(deleteCompletion: @escaping () -> ()) {
        if let fileName = getLocalFileName() {
            
            if let path = FileManager
                .default
                .urls(for: .documentDirectory, in: .userDomainMask)
                .first?
                .appendingPathComponent(fileName) {
                
                if FileManager.default.fileExists(atPath: path.path) {
                    try? FileManager.default.removeItem(at: path)
                    deleteCompletion()
                }
            }
        }
    }
    
    /// Converts the HTML-formatted ``episodeDescription`` string to a standard Swift String
    var formattedDescription: String {
        episodeDescription?.attributedStringFromHTML?.string ?? ""
    }
}




