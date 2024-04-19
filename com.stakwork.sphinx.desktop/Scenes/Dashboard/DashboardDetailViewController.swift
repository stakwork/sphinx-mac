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
    }
    
    func displayVC(_ vc: NSViewController, vcTitle: String, shouldReplace: Bool = true) {
        if shouldReplace {
            backButtonTapped()
        }
        containerView.isHidden = false
        addedVC?.append(vc)
        addedTitles?.append(vcTitle)
        updateVCTitle()
        ShowBackButton()
        self.addChildVC(child: vc, container: containerView)
    }
    
    func updateVCTitle() {
        let title = addedTitles?.last ?? ""
        headerView.setHeaderTitle(title)
    }
    
    func ShowBackButton() {
        if addedVC?.count ?? 0 > 1 {
            headerView.hideBackButton(hide: false)
        } else {
            headerView.hideBackButton(hide: true)
        }
    }
}

extension DashboardDetailViewController: DetailHeaderViewDelegate {
    func backButtonTapped() {
        print("Back button clicked")
        if let last = addedVC?.last, let last {
            self.removeChildVC(child: last)
            self.addedTitles?.removeLast()
            
            if let addedVC, addedVC.count > 1,
                let currentVC = addedVC[addedVC.count - 2] {
                self.addChildVC(child: currentVC, container: containerView)
                updateVCTitle()
            }
            
            var lastVC = self.addedVC?.removeLast()
            lastVC = nil
            ShowBackButton()
        }
    }
    
    func closeButtonTapped() {
        print("Close button clicked")
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
