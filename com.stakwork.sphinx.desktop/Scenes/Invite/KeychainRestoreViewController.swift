//
//  KeychainRestoreViewController.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 12/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol KeychainRestoreDelegate: AnyObject {
    func didRestoreNode(node: String?)
    func shouldShowError()
}

class KeychainRestoreViewController: NSViewController {
    
    weak var delegate: KeychainRestoreDelegate?
    
    @IBOutlet weak var nodesCollectionView: NSCollectionView!
    
    let userData = UserData.sharedInstance
    var nodesArray = [String]()
    
    static func instantiate(delegate: KeychainRestoreDelegate) -> KeychainRestoreViewController {
        let viewController = StoryboardScene.Invite.keychainRestoreViewController.instantiate()
        viewController.delegate = delegate
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        nodesArray = userData.getPubKeysForRestore()
        
        configureCollectionView()
        listenForResize()
    }
    
    fileprivate func configureCollectionView() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: self.view.frame.width, height: 60.0)
        flowLayout.sectionInset = NSEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.minimumLineSpacing = 0.0
        
        nodesCollectionView.collectionViewLayout = flowLayout
        view.wantsLayer = true
        nodesCollectionView.layer?.backgroundColor = NSColor.Sphinx.Body.cgColor
        
        nodesCollectionView.dataSource = self
        nodesCollectionView.delegate = self
    }
    
    fileprivate func listenForResize() {
        NotificationCenter.default.addObserver(forName: NSWindow.didResizeNotification, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            self?.nodesCollectionView.collectionViewLayout?.invalidateLayout()
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        NotificationCenter.default.removeObserver(self, name: NSWindow.didResizeNotification, object: nil)
    }
    
    func restoreNode(pubKey: String) {
        if let credentials = userData.getAllValuesFor(pubKey: pubKey) {
            if EncryptionManager.sharedInstance.insertKeys(privateKey: credentials[3], publicKey: credentials[4]) {
                UserData.sharedInstance.save(ip: credentials[0], token: credentials[1], pin: credentials[2])
                
                self.delegate?.didRestoreNode(node: pubKey)
                self.view.window?.close()
            } else {
                dismissAndShowError()
            }
        } else {
            dismissAndShowError()
        }
    }
    
    func dismissAndShowError() {
        view.window?.close()
        delegate?.shouldShowError()
    }
    
    @IBAction func closeButtonTouched(_ sender: Any) {
        view.window?.close()
    }
}

extension KeychainRestoreViewController : NSCollectionViewDataSource {
  
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
  
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return nodesArray.count
    }
  
    func collectionView(_ itemForRepresentedObjectAtcollectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = nodesCollectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "KeychainRestoreCollectionViewItem"), for: indexPath)
        guard let collectionViewItem = item as? KeychainRestoreCollectionViewItem else {return item}
        let node = nodesArray[indexPath.item]
        collectionViewItem.pubKey = node
        return item
    }
}

extension KeychainRestoreViewController : NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return NSSize(width: self.view.window?.frame.width ?? 400, height: 60)
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        if let indexPath = indexPaths.first {
            let pubKey = nodesArray[indexPath.item]
            restoreNode(pubKey: pubKey)
        }
    }
}
