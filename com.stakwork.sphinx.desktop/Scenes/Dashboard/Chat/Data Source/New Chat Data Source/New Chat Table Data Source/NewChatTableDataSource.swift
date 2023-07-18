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
    func shouldGoToAttachmentViewFor(messageId: Int, isPdf: Bool)
    func shouldGoToVideoPlayerFor(messageId: Int, with data: Data)
    
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
    
    ///WebView Loading
    let webViewSemaphore = DispatchSemaphore(value: 1)
    var webViewLoadingCompletion: ((CGFloat?) -> ())? = nil
    
    init(
        chat: Chat?,
        contact: UserContact?,
        collectionView : NSCollectionView,
        headerImageView: NSImageView?,
        bottomView: NSView
//        webView: WKWebView,
//        delegate: NewChatTableDataSourceDelegate?
    ) {
        super.init()
        
        self.chat = chat
        self.contact = contact
        
        self.collectionView = collectionView
        self.headerImage = headerImageView?.image
        self.bottomView = bottomView
//        self.webView = webView
        
//        self.delegate = delegate
        
        configureTableView()
        configureDataSource()
        processChatAliases()
    }
    
    func updateFrame() {
        self.collectionView.collectionViewLayout?.invalidateLayout()
    }
    
    func processChatAliases() {
        DispatchQueue.global(qos: .background).async {
            self.chat?.processAliases()
        }
    }
    
    func isFinalDS() -> Bool {
        return self.chat != nil
    }
    
    func configureTableView() {
//        let flowLayout = NSCollectionViewFlowLayout()
//        flowLayout.sectionInset = NSEdgeInsets(
//            top: Constants.kMargin,
//            left: 0.0,
//            bottom: 0.0,
//            right: 0.0
//        )
//        flowLayout.minimumInteritemSpacing = 0.0
//        flowLayout.minimumLineSpacing = 0.0

//        collectionView.superview?.wantsLayer = true
//        collectionView.wantsLayer = true
//        collectionView.layer?.setAffineTransform(
//            CGAffineTransform(scaleX: 1, y: -1)
//        )
        collectionView.layer?.backgroundColor = NSColor.green.cgColor
//        collectionView.collectionViewLayout = flowLayout
        
        collectionView.delegate = self
        collectionView.reloadData()
        
        collectionView.registerItem(NewOnlyTextMessageCollectionViewitem.self)
        collectionView.registerItem(ChatMentionAutocompleteCell.self)
    }
}
