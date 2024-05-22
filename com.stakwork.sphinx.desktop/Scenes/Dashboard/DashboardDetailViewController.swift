//
//  DashboardDetailViewController.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 18/04/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa
protocol DashboardDetailDismissDelegate: AnyObject {
    func closeButtonTapped()
}
class DashboardDetailViewController: NSViewController {

    weak var dismissDelegate: DashboardDetailDismissDelegate?
    
    @IBOutlet weak var headerView: DashboardDetailHeaderView!
    @IBOutlet weak var containerView: ThreadVCContainer!
    
    var addedVC: [NSViewController?]? = []
    var addedTitles: [String]? = []
    
    static func instantiate(delegate: DashboardDetailDismissDelegate? = nil) -> DashboardDetailViewController {
        let viewController = StoryboardScene.Dashboard.dashboardDetailViewController.instantiate()
        viewController.dismissDelegate = delegate
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        headerView.delegate = self
    }
    
    func resizeSubviews(frame: NSRect) {
        view.frame = frame
        
        guard let currentVC = addedVC?.last else {
            return
        }
        currentVC?.view.frame = containerView.bounds
    }
    
    func updateCurrentVCFrame() {
        if let currentVC = addedVC?.last as? TribeMembersViewController {
            currentVC.groupChatDataSource?.updateFrame()
        }
        
        if let currentVC = addedVC?.last as? NewChatViewController {
            currentVC.chatTableDataSource?.updateFrame()
        }
    }
    
    func displayVC(
        _ vc: NSViewController,
        vcTitle: String,
        shouldReplace: Bool = true,
        fixedWidth: CGFloat? = nil
    ) {
        if shouldReplace {
            backButtonTapped()
        }
        
        if let fixedWidth = fixedWidth {
            containerView.frame.size.width = fixedWidth
        }
        
        containerView.isHidden = false
        addedVC?.append(vc)
        addedTitles?.append(vcTitle)
        updateVCTitle()
        showBackButton()
        
        self.addChildVC(child: vc, container: containerView)
        guard let threadVC = vc as? NewChatViewController else { return }
        
        threadVC.chatBottomView.messageFieldView.setupForThread()
    }
    
    func updateVCTitle() {
        let title = addedTitles?.last ?? ""
        headerView.setHeaderTitle(title)
    }
    
    func showBackButton() {
        if addedVC?.count ?? 0 > 1 {
            headerView.hideBackButton(hide: false)
        } else {
            headerView.hideBackButton(hide: true)
        }
    }
}

extension DashboardDetailViewController: DetailHeaderViewDelegate {
    func backButtonTapped() {
        if let last = addedVC?.last, let last {
            self.removeChildVC(child: last)
            self.addedTitles?.removeLast()
            
            if let addedVC, addedVC.count > 1,
                let currentVC = addedVC[addedVC.count - 2] {
                self.addChildVC(child: currentVC, container: containerView)
                updateVCTitle()
            }
            
            var _ = self.addedVC?.removeLast()
            
            showBackButton()
        }
    }
    
    func closeButtonTapped() {
        guard let addedVC else { return }
        for vc in addedVC {
            if let vc {
                self.removeChildVC(child: vc)
            }
        }
        self.addedVC?.removeAll()
        dismissDelegate?.closeButtonTapped()
    }
    
}
