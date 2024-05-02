//
//  ChatsSegmentedControl.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 05/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol ChatsSegmentedControlDelegate: AnyObject {
    
    func segmentedControlDidSwitch(
        _ segmentedControl: ChatsSegmentedControl,
        to index: Int
    )
}

class ChatsSegmentedControl: NSView {
    
    private var buttonContainers: [NSView]!
    private var buttons: [NSButton]!
    private var buttonTitles: [String]!
    private var buttonTitleBadges: [NSView]!
    private var selectorView: NSView!

    public var buttonBackgroundColor: NSColor = .Sphinx.HeaderBG
    public var buttonTextColor: NSColor = .Sphinx.DashboardWashedOutText
    public var activeTextColor: NSColor = .Sphinx.PrimaryText
    
    public var buttonTitleFont = NSFont(
        name: "Roboto-Medium",
        size: 14.0
    )!
    
    public var selectorViewColor: NSColor = .Sphinx.PrimaryBlue
    public var selectorWidthRatio: CGFloat = 0.667
    
    let kButtonWidth: CGFloat = 86.0
    let kButtonHeight: CGFloat = 48.0
    
    
    /// Indices for tabs that should have a circular badge displayed next to their title.
    public var indicesOfTitlesWithBadge: [Int] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.updateTitleBadges()
            }
        }
    }
    

    public weak var delegate: ChatsSegmentedControlDelegate?
    
    let contactsService = ContactsService.sharedInstance
    
    convenience init(
        frame: CGRect,
        buttonTitles: [String]
    ) {
        self.init(frame: frame)
        
        self.buttonTitles = buttonTitles
        
        setupInitialViews()
    }
}

// MARK: - Lifecycle
extension ChatsSegmentedControl {
        
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        self.wantsLayer = true
        self.layer?.masksToBounds = true
        self.layer?.backgroundColor = buttonBackgroundColor.cgColor
    }
}

// MARK: - Action Handling
extension ChatsSegmentedControl {
    
    @objc func buttonAction(sender: NSButton) {
        
        for (buttonIndex, button) in buttons.enumerated() {
            
            resetButton(button)
            
            if button == sender {
                delegate?.segmentedControlDidSwitch(self, to: buttonIndex)
                updateButtonsOnIndexChange()
            }
        }
    }
    
    func resetButton(_ button: NSButton) {
        button.attributedTitle = NSAttributedString(
            string: button.attributedTitle.string,
            attributes:
                [
                    NSAttributedString.Key.foregroundColor : buttonTextColor,
                    NSAttributedString.Key.font: buttonTitleFont
                ]
        )
    }
}

// MARK: - Public Methods
extension ChatsSegmentedControl {

    public func configureFromOutlet(
        buttonTitles: [String],
        indicesOfTitlesWithBadge: [Int] = [],
        delegate: ChatsSegmentedControlDelegate?
    ) {
        self.buttonTitles = buttonTitles
        self.delegate = delegate
        
        setupInitialViews()
        updateButtonsOnIndexChange()
    }
}

// MARK: -  View Configuration
extension ChatsSegmentedControl {
    
    private func setupInitialViews() {
        createButtons()
        configureSelectorView()
        configureStackView()
    }
    
    
    private func configureStackView() {
        let stackView = NSStackView(views: buttonContainers)
        
        stackView.orientation = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        
        addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        stackView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        
        stackView.widthAnchor.constraint(equalToConstant: kButtonWidth * 2).isActive = true
    }
    
    private var selectorPosition: CGFloat {
        return kButtonWidth * CGFloat(contactsService.selectedTabIndex)
    }
    
    private func configureSelectorView() {
        selectorView = NSView(
            frame: CGRect(
                x: selectorPosition,
                y: 0,
                width: kButtonWidth,
                height: 2
            )
        )
        
        selectorView.wantsLayer = true
        selectorView.layer?.masksToBounds = true
        selectorView.layer?.backgroundColor = selectorViewColor.cgColor

        addSubview(selectorView)
    }
    
    
    private func createButtons() {
        buttonContainers = [NSView]()
        buttonContainers.removeAll()
        
        buttons = [NSButton]()
        buttons.removeAll()
        
        for buttonTitle in buttonTitles {
            
            let view = NSView(
                frame: NSRect(
                    x: 0,
                    y: 0,
                    width: kButtonWidth,
                    height: kButtonHeight
                )
            )
            
            let button = NSButton(
                frame: NSRect(
                    x: 0,
                    y: 0,
                    width: kButtonWidth,
                    height: kButtonHeight
                )
            )
            
            button.attributedTitle = NSAttributedString(
                string: buttonTitle,
                attributes:
                    [
                        NSAttributedString.Key.foregroundColor : buttonTextColor,
                        NSAttributedString.Key.font: buttonTitleFont
                    ]
            )
            
            button.target = self
            button.action = #selector(ChatsSegmentedControl.buttonAction(sender:))
            
            button.wantsLayer = true
            button.layer?.backgroundColor = NSColor.clear.cgColor
            button.isBordered = false
            
            view.addSubview(button)
            
            buttonContainers.append(view)
            buttons.append(button)
        }
        
        let selectedButton = buttons[contactsService.selectedTabIndex]
        
        selectedButton.attributedTitle = NSAttributedString(
            string: selectedButton.attributedTitle.string,
            attributes:
                [
                    NSAttributedString.Key.foregroundColor : activeTextColor,
                    NSAttributedString.Key.font: buttonTitleFont
                ]
        )
        
        createButtonTitleBadges()
    }
    
    func updateButtonsOnIndexChange() {
        for button in buttons {
            resetButton(button)
        }
        
        AnimationHelper.animateViewWith(duration: 0.3, animationsBlock: {
            
            self.selectorView.frame.origin.x = self.selectorPosition
            
            let selectedButton = self.buttons[self.contactsService.selectedTabIndex]
            
            selectedButton.attributedTitle = NSAttributedString(
                string: selectedButton.attributedTitle.string,
                attributes:
                    [
                        NSAttributedString.Key.foregroundColor : self.activeTextColor,
                        NSAttributedString.Key.font: self.buttonTitleFont
                    ]
            )
        })
    }
    
    
    private func updateTitleBadges() {
        buttonTitleBadges.enumerated().forEach { (index, badge) in
            badge.isHidden = !indicesOfTitlesWithBadge.contains(index)
        }
    }
    
    private func createButtonTitleBadges() {
        buttonTitleBadges = buttonContainers!.map { view in
            let badgeView = NSView(
                frame: .init(
                    x: kButtonWidth / 2 + 30,
                    y: kButtonHeight - 15,
                    width: 5.0,
                    height: 5.0
                )
            )
            
            badgeView.isHidden = false
            
            badgeView.wantsLayer = true
            badgeView.layer?.masksToBounds = true
            badgeView.layer?.backgroundColor = NSColor.Sphinx.PrimaryBlue.cgColor
            badgeView.makeCircular()
                
            return badgeView
        }
        
        buttonTitleBadges.enumerated().forEach { (index, badge) in
            buttonContainers[index].addSubview(badge)
            badge.isHidden = !indicesOfTitlesWithBadge.contains(index)
        }
    }
}
