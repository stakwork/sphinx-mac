//
//  WelcomeLightningViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 11/02/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Cocoa

class WelcomeLightningViewController: NSViewController {
    
    @IBOutlet weak var leftContainer: NSView!
    @IBOutlet weak var leftContainerWidth: NSLayoutConstraint!
    @IBOutlet weak var lightningNetworkImage: NSImageView!
    @IBOutlet weak var bigTitleLabel: NSTextField!
    @IBOutlet weak var rightContainer: NSView!
    @IBOutlet weak var continueButtonView: SignupButtonView!
    @IBOutlet weak var userBubbleView: NSBox!
    @IBOutlet weak var bubbleImageView: AspectFillNSImageView!
    @IBOutlet weak var bubbleInitialsContainer: NSBox!
    @IBOutlet weak var bubbleInitials: NSTextField!
    @IBOutlet weak var bubbleNameLabel: NSTextField!
    @IBOutlet weak var bubbleArrow: NSView!
    
    public enum FormViewMode: Int {
        case Start
        case NamePin
        case Image
        case Ready
    }
    
    var mode : FormViewMode = .Start
    var formView: NSView? = nil
    
    static func instantiate(
        mode: FormViewMode = .Start
    ) -> WelcomeLightningViewController {
        
        let viewController = StoryboardScene.Signup.welcomeLightningViewController.instantiate()
        viewController.mode = mode
        
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        continueButtonView.configureWith(title: "continue".localized.capitalized, icon: "", tag: -1, delegate: self)
        configureView()
        
        lightningNetworkImage.loadGifWith(name: "lightningNetwork")
    }
    
    func configureView() {
        bubbleArrow.addDownTriangle()
        moveToView(mode: mode, animated: false)
    }
    
    func moveToView(mode: FormViewMode, animated: Bool) {
        self.mode = mode
        
        for subview in rightContainer.subviews {
            subview.removeFromSuperview()
        }
        
        if let subView = getViewFor(mode: mode) {
            rightContainer.addSubview(subView)
            subView.constraintTo(view: rightContainer)
        }
        continueButtonView.isHidden = mode != .Start
        
        addBubbleOnLeftContainer(mode: mode)
        animateLeftContainer(expanded: mode != .Start, animated: animated)
    }
    
    func getViewFor(mode: FormViewMode) -> NSView? {
        switch (mode) {
        case .NamePin:
            formView = NamePinView(
                frame: NSRect.zero,
                delegate: self
            )
        case .Image:
            let nickname = (formView as? NamePinView)?.getNickname() ?? UserContact.getOwner()?.nickname
            
            formView = ProfileImageView(
                frame: NSRect.zero,
                nickname: nickname ?? "",
                delegate: self
            )
            
        case .Ready:
            formView = SphinxReady(frame: NSRect.zero, delegate: self)
        default:
            break
        }
        return formView
    }
}

extension WelcomeLightningViewController : SignupButtonViewDelegate {
    func didClickButton(tag: Int) {
        moveToView(mode: .NamePin, animated: true)
    }
    
    func animateLeftContainer(expanded: Bool, animated: Bool) {
        let windowsWidth = (view.window ?? NSApplication.shared.keyWindow)?.frame.width
        let expectedWidth = expanded ? -((windowsWidth ?? 800) / 2) : 0
        
        if expectedWidth == leftContainerWidth.constant {
            return
        }
        leftContainerWidth.constant = expectedWidth
        if !animated {
            view.layoutSubtreeIfNeeded()
            return
        }
        AnimationHelper.animateViewWith(duration: 0.4, animationsBlock: {
            self.view.layoutSubtreeIfNeeded()
        })
    }
}

extension WelcomeLightningViewController : WelcomeEmptyViewDelegate {
    func shouldContinueTo(mode: Int) {
        if let mode = FormViewMode(rawValue: mode) {
            moveToView(mode: mode, animated: true)
        } else {
            view.window?.replaceContentBy(vc: WelcomeMobileViewController.instantiate())
        }
    }
    
    func addBubbleOnLeftContainer(mode: FormViewMode) {
        if let owner = UserContact.getOwner(), mode == .Ready {
            userBubbleView.isHidden = false
            bubbleArrow.isHidden = false
            bigTitleLabel.isHidden = true
            
            let nickname = owner.getUserName(forceNickname: true)
            bubbleInitialsContainer.fillColor = owner.getColor()
            bubbleInitials.stringValue = nickname.getInitialsFromName()
            bubbleNameLabel.stringValue = nickname
            
            if let urlString = owner.getPhotoUrl(), !urlString.isEmpty {
                MediaLoader.loadAvatarImage(url: urlString, objectId: owner.id, completion: { (image, id) in
                    self.bubbleImageView.image = image
                    self.bubbleImageView.gravity = .resizeAspectFill
                })
            }
        }
    }
}
