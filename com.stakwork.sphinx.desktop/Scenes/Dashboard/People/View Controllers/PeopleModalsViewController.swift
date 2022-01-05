//
//  PeopleModalsViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 05/01/2022.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol ModalsViewControllerDelegate: AnyObject {
    func shouldHideContainer()
}

class PeopleModalsViewController: NSViewController {

    @IBOutlet weak var authExternalView: AuthExternalView!
    @IBOutlet weak var personModalView: PersonModalView!
    @IBOutlet weak var savePeopleProfileView: SavePeopleProfileView!
    
    var query: String? = nil
    
    weak var delegate: ModalsViewControllerDelegate! = nil
    
    static func instantiate() -> PeopleModalsViewController {
        let viewController = StoryboardScene.Dashboard.peopleModalsViewController.instantiate()
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        authExternalView.alphaValue = 0
        personModalView.alphaValue = 0
    }
    
    func showWithQuery(
        _ query: String,
        and delegate: ModalsViewControllerDelegate
    ) {
        self.delegate = delegate
        self.query = query
        
        self.view.alphaValue = 0.0
        
        if let modal = getModal() {
            modal.alphaValue = 1.0
            modal.modalWillShowWith(query: query, delegate: self)
            
            AnimationHelper.animateViewWith(duration: 0.3, animationsBlock: {
                self.view.alphaValue = 1.0
            }, completion: {
                modal.modalDidShow()
            })
        } else {
            shouldDismissModals()
        }
    }
    
    func getModal() -> ModalViewInterface? {
        if let query = query, let action = query.getLinkAction() {
            switch(action) {
            case "auth":
                return authExternalView
            case "person":
                return personModalView
            case "save":
                return savePeopleProfileView
            default:
                break
            }
        }
        return nil
    }
}

extension PeopleModalsViewController : ModalViewDelegate {
    func shouldDismissModals() {
        AnimationHelper.animateViewWith(duration: 0.3, animationsBlock: {
            self.view.alphaValue = 0.0
        }, completion: {
            self.authExternalView.alphaValue = 0.0
            self.personModalView.alphaValue = 0.0
            
            self.delegate.shouldHideContainer()
        })
    }
    
    func shouldGoToContactChat(contactId: Int) {
        //Post notification
        
        shouldDismissModals()
    }
}
