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
    }
    
    func showWithQuery(
        _ query: String,
        and delegate: ModalsViewControllerDelegate
    ) {
        self.delegate = delegate
        self.query = query
        
        self.authExternalView.isHidden = true
        self.personModalView.isHidden = true
        self.savePeopleProfileView.isHidden = true
        
        self.view.alphaValue = 0.0
        
        if let modal = getModal() {
            modal.isHidden = false
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
            self.authExternalView.isHidden = true
            self.personModalView.isHidden = true
            self.savePeopleProfileView.isHidden = true
            
            self.delegate.shouldHideContainer()
        })
    }
}
