//
//  NewChatTableDataSource.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa
import WebKit

protocol NewChatTableDataSourceDelegate : AnyObject {
    ///New msgs indicator
    func configureNewMessagesIndicatorWith(newMsgCount: Int)
    
    ///Scrolling
    func didScrollToBottom()
    func didScrollOutOfBottomArea()
    
    ///Attachments
    func shouldGoToMediaFullScreenFor(messageId: Int)
    
    ///LinkPreviews
    func didTapOnContactWith(pubkey: String, and routeHint: String?)
    func didTapOnTribeWith(joinLink: String)
    
    ///Tribes
    func didDeleteTribe()
    
    ///First messages / Socket
    func didUpdateChat(_ chat: Chat)
    
    ///Message menu
//    func didLongPressOn(cell: UITableViewCell, with messageId: Int, bubbleViewRect: CGRect)
    
    ///Leaderboard
    func shouldShowLeaderboardFor(messageId: Int)
    
    ///Message reply
    func shouldReplyToMessage(message: TransactionMessage)
    
    ///File download
    func shouldOpenActivityVCFor(url: URL)
    
    ///Invoices
    func shouldPayInvoiceFor(messageId: Int)
    
    ///Messages search
    func isOnStandardMode() -> Bool
    func didFinishSearchingWith(matchesCount: Int, index: Int)
    func shouldToggleSearchLoadingWheel(active: Bool)
}

class NewChatTableDataSource : NSObject {
    
    ///Delegate
    weak var delegate: NewChatTableDataSourceDelegate?
    
    ///View references
    var collectionView : NSCollectionView!
    var collectionViewScroll: NSScrollView!
    var shimmeringView: ChatShimmeringView!
    var headerImage: NSImage?
    var bottomView: NSView!
    var webView: WKWebView!
    
    ///Chat
    var chat: Chat?
    var contact: UserContact?
    
    ///Data Source related
    var messagesResultsController: NSFetchedResultsController<TransactionMessage>!
    var additionMessagesResultsController: NSFetchedResultsController<TransactionMessage>!
    
    var currentDataSnapshot: DataSourceSnapshot!
    var dataSource: DataSource!
    
    ///Helpers
    var preloaderHelper = MessagesPreloaderHelper.sharedInstance
    let linkPreviewsLoader = CustomSwiftLinkPreview.sharedInstance
    let messageBubbleHelper = NewMessageBubbleHelper()
    let audioPlayerHelper = NewAudioPlayerHelper()
    var podcastPlayerController = PodcastPlayerController.sharedInstance
    
    ///Messages Data
    var messagesArray: [TransactionMessage] = []
    var messageTableCellStateArray: [MessageTableCellState] = []
    var mediaCached: [Int: MessageTableCellState.MediaData] = [:]
    var botsWebViewData: [Int: MessageTableCellState.BotWebViewData] = [:]
    var uploadingProgress: [Int: MessageTableCellState.UploadProgressData] = [:]
    
    var searchingTerm: String? = nil
    var searchMatches: [(Int, MessageTableCellState)] = []
    var currentSearchMatchIndex: Int = 0
    var isLastSearchPage = false
    
    ///Scroll and pagination
    var messagesCount = 0
    var loadingMoreItems = false
    var scrolledAtBottom = false
    var scrollViewDesiredOffset: CGFloat? = nil
    var distanceFromBottom: CGFloat? = nil
    var isPreload = true
    
    ///WebView Loading
    let webViewSemaphore = DispatchSemaphore(value: 1)
    var webViewLoadingCompletion: ((CGFloat?) -> ())? = nil
    
    ///Chat Helper
    let chatHelper = ChatHelper()
    
    init(
        chat: Chat?,
        contact: UserContact?,
        collectionView : NSCollectionView,
        collectionViewScroll: NSScrollView,
        shimmeringView: ChatShimmeringView,
        headerImage: NSImage?,
        bottomView: NSView,
//        webView: WKWebView,
        delegate: NewChatTableDataSourceDelegate?
    ) {
        super.init()
        
        self.chat = chat
        self.contact = contact
        
        self.collectionView = collectionView
        self.headerImage = headerImage
        self.collectionViewScroll = collectionViewScroll
        self.headerImage = headerImage
        self.bottomView = bottomView
        self.shimmeringView = shimmeringView
//        self.webView = webView
        
        self.delegate = delegate
        
        addScrollObservers()
        configureTableView()
        configureDataSource()
    }
    
    func updateFrame() {
        self.collectionView.collectionViewLayout?.invalidateLayout()
    }
    
    func isFinalDS() -> Bool {
        return self.chat != nil
    }
    
    func configureTableView() {
        collectionView.alphaValue = 0.0
        
        collectionView.delegate = self
        collectionView.reloadData()
        
        collectionView.registerItem(NewMessageCollectionViewItem.self)
        collectionView.registerItem(NewOnlyTextMessageCollectionViewitem.self)
        collectionView.registerItem(MessageNoBubbleCollectionViewItem.self)
    }
}
