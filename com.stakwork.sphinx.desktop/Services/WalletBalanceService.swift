//
//  WalletBalanceService.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 14/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

public final class WalletBalanceService {
    
    var balance: Int {
        get {
            return UserDefaults.Keys.channelBalance.get() ?? 0 as Int
        }
        set {
            UserDefaults.Keys.channelBalance.set(newValue)
        }
    }
    
    var remoteBalance: Int {
        get {
            return UserDefaults.Keys.remoteBalance.get() ?? 0 as Int
        }
        set {
            UserDefaults.Keys.remoteBalance.set(newValue)
        }
    }
    
    init() {
        
    }
    
    func getBalance() -> Int? {
        let balance = UserData.sharedInstance.getBalanceSats()
        return balance
    }
    
    func getBalance(completion: @escaping (Int) -> ()) -> Int {
        API.sharedInstance.getWalletBalance(callback: { updatedBalance in
            self.balance = updatedBalance
            completion(updatedBalance)
        }, errorCallback: {
            completion(self.balance)
        })
        return balance
    }
    
    func getBalanceAll(completion: @escaping (Int, Int) -> ()) -> (Int, Int) {
        API.sharedInstance.getWalletLocalAndRemote(callback: { local, remote in
            self.balance = local
            self.remoteBalance = remote
            completion(local, remote)
        }, errorCallback: {
            completion(self.balance, self.remoteBalance)
        })
        return (balance, remoteBalance)
    }    
    
    func updateBalance(labels: [NSTextField]) {
        DispatchQueue.global().async {
            if let storedBalance = self.getBalance() {
                self.updateLabels(labels: labels, balance: storedBalance.formattedWithSeparator)
            }
        }
    }
    
    func updateLabels(labels: [NSTextField], balance: String) {
        for label in labels {
            label.stringValue = balance
        }
    }
}
