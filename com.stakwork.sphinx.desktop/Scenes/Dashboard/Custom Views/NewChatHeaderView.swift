//
//  NewChatHeaderView.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 23/04/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol NewChatHeaderViewDelegate: AnyObject {
    func refreshTapped()
    func menuTapped(_ frame: CGRect)
    func profileButtonClicked()
}

class NewChatHeaderView: NSView, LoadableNib {
    
    weak var delegate: NewChatHeaderViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var profileImageView: AspectFillNSImageView!
    
    @IBOutlet weak var balanceLabel: NSTextField!
    @IBOutlet weak var balanceUnitLabel: NSTextField!
    
    @IBOutlet weak var healthCheckView: HealthCheckView!
    
    @IBOutlet weak var reloadButton: CustomButton!
    @IBOutlet weak var menuButton: CustomButton!
    @IBOutlet weak var balanceButton: CustomButton!
    
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    @IBOutlet weak var loadingWheelContainer: NSView!
    
    var walletBalanceService = WalletBalanceService()
    
    var ownerResultsController: NSFetchedResultsController<UserContact>!
    var profile: UserContact? = nil
    
    var hideBalance: Bool = false
    
    var loading = false {
        didSet {
            loadingWheelContainer.isHidden = !loading
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.Sphinx.Text, controls: [])
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        loadViewFromNib()
        setup()
        setupViews()
        loading = true
        healthCheckView.delegate = self
        configureProfile()
        listenForNotifications()
    }
    
    private func setup() {
        configureOwnerFetchResultsController()
    }
    
    func configureOwnerFetchResultsController() {
        if let _ = ownerResultsController {
            return
        }
        
        let ownerFetchRequest = UserContact.FetchRequests.owner()

        ownerResultsController = NSFetchedResultsController(
            fetchRequest: ownerFetchRequest,
            managedObjectContext: CoreDataManager.sharedManager.persistentContainer.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        ownerResultsController.delegate = self
        
        do {
            try ownerResultsController.performFetch()
        } catch {}
    }
    
    func configureProfile() {
        walletBalanceService.updateBalance(labels: [balanceLabel])
        balanceUnitLabel.stringValue = "sat"
        
        setupViews()
        
        if let profile = profile {
            if let imageUrl = profile.avatarUrl?.trim(), imageUrl != "" {
                MediaLoader.loadAvatarImage(url: imageUrl, objectId: profile.id, completion: { (image, id) in
                    guard let image = image else {
                        return
                    }
                    self.profileImageView.bordered = false
                    self.profileImageView.image = image
                })
            } else {
                profileImageView.image = NSImage(named: "profileAvatar")
            }
            
            let nickname = profile.nickname ?? ""
            nameLabel.stringValue = nickname.getNameStyleString(lineBreak: false)
        }
    }
    
    func setupViews() {
        reloadButton.cursor = .pointingHand
        menuButton.cursor = .pointingHand
        balanceButton.cursor = .pointingHand
        
        profileImageView.wantsLayer = true
        profileImageView.rounded = true
        profileImageView.layer?.cornerRadius = profileImageView.frame.height / 2
    }
    
    @IBAction func refreshButtonTapped(_ sender: NSButton) {
        loading = true
        delegate?.refreshTapped()
        updateBalance()
//        shouldCheckAppVersions()
    }
    
    @IBAction func menuButtonTapped(_ sender: NSButton) {
        delegate?.menuTapped(menuButton.frame)
    }
    
    @IBAction func toggleHideBalance(_ sender: NSButton) {
        hideBalance = !hideBalance
        hideBalance ? hideAmount() : updateBalance()
    }
    
    @IBAction func profileButtonClicked(_ sender: Any) {
        delegate?.profileButtonClicked()
    }
    
    func hideAmount() {
        var hiddenAmount = ""
        
        "\(walletBalanceService.balance)".forEach { char in
            hiddenAmount += "*"
        }
        
        balanceLabel.stringValue = hiddenAmount
    }
    
    func shouldCheckAppVersions() {
//        API.sharedInstance.getAppVersions(callback: { v in
//            self.loading = false
//            let version = Int(v) ?? 0
//            let appVersion = Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0") ?? 0

//            self.upgradeButton.isHidden = version <= appVersion
//            self.upgradeBox.isHidden = version <= appVersion
//        })
    }
    
    func listenForNotifications() {
        healthCheckView.listenForEvents()
        
        NotificationCenter.default.addObserver(
            forName: .onBalanceDidChange,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] (n: Notification) in
                self?.updateBalance()
        }
    }
    
    func updateBalance() {
        balanceUnitLabel.stringValue = "sat"
        walletBalanceService.updateBalance(labels: [balanceLabel])
    }
}

extension NewChatHeaderView : HealthCheckDelegate {
    func shouldShowBubbleWith(_ message: String) {
        NewMessageBubbleHelper().showGenericMessageView(text:message, in: self.contentView, position: .Top, delay: 3)
    }
}

extension NewChatHeaderView : NSFetchedResultsControllerDelegate {
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        if
            let resultController = controller as? NSFetchedResultsController<NSManagedObject>,
            let firstSection = resultController.sections?.first {
            
            if resultController == ownerResultsController {
                profile = firstSection.objects?.first as? UserContact
                configureProfile()
            }
        }
    }
}
