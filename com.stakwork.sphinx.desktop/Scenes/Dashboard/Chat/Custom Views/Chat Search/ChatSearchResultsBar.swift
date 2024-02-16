//
//  ChatSearchResultsBar.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 05/10/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol ChatSearchResultsBarDelegate : AnyObject {
    func didTapNavigateArrowButton(button: ChatSearchResultsBar.NavigateArrowButton)
}

class ChatSearchResultsBar: NSView, LoadableNib {
    
    var delegate: ChatSearchResultsBarDelegate?
    
    @IBOutlet var contentView: NSView!

    @IBOutlet weak var matchIndexLabel: NSTextField!
    @IBOutlet weak var matchesCountLabel: NSTextField!
    @IBOutlet weak var arrowUpButton: CustomButton!
    @IBOutlet weak var arrowDownButton: CustomButton!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    @IBOutlet weak var searchingLabel: NSTextField!
    
    public enum NavigateArrowButton: Int {
        case Up
        case Down
    }
    
    var matchesCount: Int = 0
    var matchIndex: Int = 0

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setupView()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
        setupView()
    }
    
    func setupView() {
        loadingWheel.set(tintColor: NSColor.Sphinx.SecondaryText)
    }
    
    func toggleLoadingWheel(
        active: Bool,
        showLabel: Bool = true
    ) {
        loadingWheel.isHidden = !active
        searchingLabel.isHidden = !active || !showLabel
        
        if active {
            loadingWheel.startAnimation(nil)
        } else {
            loadingWheel.stopAnimation(nil)
        }
    }
    
    func configureWith(
        matchesCount: Int? = nil,
        matchIndex: Int,
        loading: Bool,
        delegate: ChatSearchResultsBarDelegate?
    ) {
        self.delegate = delegate
        self.matchesCount = matchesCount ?? 0
        self.matchIndex = matchIndex
        
        configureArrowsWith(
            matchesCount: matchesCount ?? 0,
            matchIndex: matchIndex
        )
        
        toggleLoadingWheel(active: loading)
    }
    
    func configureArrowsWith(
        matchesCount: Int,
        matchIndex: Int
    ) {
        matchIndexLabel.isHidden = matchesCount <= 0
        matchIndexLabel.stringValue = "\(matchIndex+1)\\"
        matchesCountLabel.stringValue = matchesCount.searchMatchesString
        
        arrowUpButton.isEnabled = (matchesCount > 0 && matchIndex < (matchesCount - 1))
        arrowUpButton.alphaValue = (matchesCount > 0 && matchIndex < (matchesCount - 1)) ? 1.0 : 0.3
        
        arrowDownButton.isEnabled = (matchesCount > 0 && matchIndex > 0)
        arrowDownButton.alphaValue = (matchesCount > 0 && matchIndex > 0) ? 1.0 : 0.3
    }

    @IBAction func navigateArrowButtonTouched(_ sender: NSButton) {
        switch(sender.tag) {
        case NavigateArrowButton.Up.rawValue:
            if matchIndex + 1 >= matchesCount {
                return
            }
            
            sender.isEnabled = false
            
            matchIndex = matchIndex + 1
            
            configureArrowsWith(
                matchesCount: matchesCount,
                matchIndex: matchIndex
            )
            
            delegate?.didTapNavigateArrowButton(button: NavigateArrowButton.Up)
        case NavigateArrowButton.Down.rawValue:
            if matchIndex <= 0 {
                return
            }
            
            sender.isEnabled = false
            
            matchIndex = matchIndex - 1
            
            configureArrowsWith(
                matchesCount: matchesCount,
                matchIndex: matchIndex
            )
            
            delegate?.didTapNavigateArrowButton(button: NavigateArrowButton.Down)
        default:
            break
        }
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
            sender.isEnabled = true
        })
    }
    
}
