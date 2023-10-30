//
//  ChatCollectionViewItemProtocol.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol ChatCollectionViewItemProtocol: AnyObject {
    func configureWith(
        messageCellState: MessageTableCellState,
        mediaData: MessageTableCellState.MediaData?,
        threadOriginalMsgMediaData: MessageTableCellState.MediaData?,
        tribeData: MessageTableCellState.TribeData?,
        linkData: MessageTableCellState.LinkData?,
        botWebViewData: MessageTableCellState.BotWebViewData?,
        uploadProgressData: MessageTableCellState.UploadProgressData?,
        delegate: ChatCollectionViewItemDelegate?,
        searchingTerm: String?,
        indexPath: IndexPath,
        collectionViewWidth: CGFloat
    )
    
    func releaseMemory()
}

protocol ChatCollectionViewItemDelegate: AnyObject {
    //Loading content in background
    func shouldLoadTribeInfoFor(messageId: Int, and rowIndex: Int)
    func shouldLoadImageDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadPdfDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadFileDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadVideoDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadGiphyDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadTextDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadLinkDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadBotWebViewDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadAudioDataFor(messageId: Int, and rowIndex: Int)
    func shouldPodcastCommentDataFor(messageId: Int, and rowIndex: Int)
    
    //Actions handling
    ///Message reply
    func didTapMessageReplyFor(messageId: Int, and rowIndex: Int)
    ///Avatar view
    func didTapAvatarViewFor(messageId: Int, and rowIndex: Int)
    ///Call Links
    func didTapCallLinkCopyFor(messageId: Int, and rowIndex: Int)
    func didTapCallJoinAudioFor(messageId: Int, and rowIndex: Int)
    func didTapCallJoinVideoFor(messageId: Int, and rowIndex: Int)
    ///Media
    func didTapMediaButtonFor(messageId: Int, and rowIndex: Int)
    func didTapFileDownloadButtonFor(messageId: Int, and rowIndex: Int)
    ///Link Previews
    func didTapTribeButtonFor(messageId: Int, and rowIndex: Int)
    func didTapContactButtonFor(messageId: Int, and rowIndex: Int)
    func didTapOnLinkButtonFor(messageId: Int, and rowIndex: Int)
    ///Tribe actions
    func didTapDeleteTribeButtonFor(messageId: Int, and rowIndex: Int)
    func didTapApproveRequestButtonFor(messageId: Int, and rowIndex: Int)
    func didTapRejectRequestButtonFor(messageId: Int, and rowIndex: Int)
    ////Label Links
    func didTapOnLink(_ link: String)
    ///Paid Content
    func didTapPayButtonFor(messageId: Int, and rowIndex: Int)
    ///Audio
    func didTapPlayPauseButtonFor(messageId: Int, and rowIndex: Int)
    ///Podcast CLip
    func didTapClipPlayPauseButtonFor(messageId: Int, and rowIndex: Int, atTime time: Double)
    func shouldSeekClipFor(messageId: Int, and rowIndex: Int, atTime time: Double)
    ///Invoices
    func didTapInvoicePayButtonFor(messageId: Int, and rowIndex: Int)
    ///Menu
    func shouldShowOptionsFor(messageId: Int, from button: NSButton)
    ///Reply on Swipe
    func shouldReplyToMessageWith(messageId: Int, and rowIndex: Int)
}
