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
        var isAtBottom: Bool
        
        init(
            firstRowId: Int,
            difference: CGFloat,
            isAtBottom: Bool
        ) {
            self.firstRowId = firstRowId
            self.difference = difference
            self.isAtBottom = isAtBottom
        }
    }
    
    struct PreloadedMessagesState {
        var messageCellStates: [MessageTableCellState]
        var resultsControllerCount: Int
        
        init(
            messageCellStates: [MessageTableCellState],
            resultsControllerCount: Int
        ) {
            self.messageCellStates = messageCellStates
            self.resultsControllerCount = resultsControllerCount
        }
    }
    
    func releaseMemory() {
        tribesData = [:]
        linksData = [:]
        chatMessages = [:]
    }
    
    var chatMessages: [Int: PreloadedMessagesState] = [:]
    var chatScrollState: [Int: ScrollState] = [:]
    
    var tribesData: [String: MessageTableCellState.TribeData] = [:]
    var linksData: [String: MessageTableCellState.LinkData] = [:]
    
    func add(
        messageStateArray: [MessageTableCellState],
        resultsControllerCount: Int,
        for chatId: Int
    ) {
        self.chatMessages[chatId] = PreloadedMessagesState(
            messageCellStates: messageStateArray,
            resultsControllerCount: resultsControllerCount
        )
    }
    
    func getPreloadedMessagesState(for chatId: Int) -> PreloadedMessagesState? {
        if let preloadedMessagesState = chatMessages[chatId], preloadedMessagesState.messageCellStates.count > 0 {
            return preloadedMessagesState
        }
        return nil
    }
    
    func save(
        firstRowId: Int,
        difference: CGFloat,
        isAtBottom: Bool,
        for chatId: Int
    ) {
        self.chatScrollState[chatId] = ScrollState(
            firstRowId: firstRowId,
            difference: difference,
            isAtBottom: isAtBottom
        )
    }
    
    func getScrollState(
        for chatId: Int,
        pinnedMessageId: Int? = nil
    ) -> ScrollState? {
        if let pinnedMessageId = pinnedMessageId {
            return ScrollState(
                firstRowId: pinnedMessageId,
                difference: 0,
                isAtBottom: false
            )
        }
        if let scrollState = chatScrollState[chatId] {
            return scrollState
        }
        return nil
    }
}
