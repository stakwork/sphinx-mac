//
//  MessagesPreloaderHelper.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation

class MessagesPreloaderHelper {
    
    class var sharedInstance : MessagesPreloaderHelper {
        struct Static {
            static let instance = MessagesPreloaderHelper()
        }
        return Static.instance
    }
    
    struct ScrollState {
        var firstRowId: Int
        var difference: CGFloat
        
        init(
            firstRowId: Int,
            difference: CGFloat
        ) {
            self.firstRowId = firstRowId
            self.difference = difference
        }
    }
    
    var chatMessages: [Int: [MessageTableCellState]] = [:]
    var chatScrollState: [Int: ScrollState] = [:]
    
    var tribesData: [String: MessageTableCellState.TribeData] = [:]
    var linksData: [String: MessageTableCellState.LinkData] = [:]
    
    func add(
        messageStateArray: [MessageTableCellState],
        for chatId: Int
    ) {
        self.chatMessages[chatId] = messageStateArray
    }
    
    func getPreloadedMessagesCount(for chatId: Int) -> Int {
        return chatMessages[chatId]?.count ?? 0
    }
    
    func getMessageStateArray(for chatId: Int) -> [MessageTableCellState]? {
        if let messageStateArray = chatMessages[chatId], messageStateArray.count > 0 {
            return messageStateArray
        }
        return nil
    }
    
    func save(
        firstRowId: Int,
        difference: CGFloat,
        for chatId: Int
    ) {
        self.chatScrollState[chatId] = ScrollState(
            firstRowId: firstRowId,
            difference: difference
        )
    }
    
    func getScrollState(
        for chatId: Int
    ) -> ScrollState? {
        if let scrollState = chatScrollState[chatId] {
            return scrollState
        }
        return nil
    }
}
