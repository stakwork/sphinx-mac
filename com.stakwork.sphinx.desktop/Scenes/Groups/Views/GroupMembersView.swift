//
//  GroupMembersView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 08/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class GroupMembersView: NSView, LoadableNib {
    
    weak var delegate: CommonPaymentViewDelegate?
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var closeButton: NSButton!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var nextButtonContainer: NSBox!
    @IBOutlet weak var nextButtonLabel: NSTextField!
    @IBOutlet weak var nextButton: NSButton!
    @IBOutlet weak var selectAllButton: NSButton!
    
    @IBOutlet weak var searchFieldContainer: NSBox!
    @IBOutlet weak var searchField: NSTextField!
    
    @IBOutlet weak var addedContactsScrollView: NSScrollView!
    @IBOutlet weak var addedContactsCollectionView: NSCollectionView!
    @IBOutlet weak var addedContactsCollectionViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var contactsHeaderView: NSView!
    @IBOutlet weak var contactsHeaderViewHeight: NSLayoutConstraint!
    @IBOutlet weak var contactsCollectionView: NSCollectionView!
    
    var contactsCVDataSource : GroupAllContactsDataSource!
    var addedContactCVDataSource : GroupAddedContactsDataSource!

    var allContacts = [UserContact]()
    var selectedContactIds = [Int]()
    var paymentViewModel: PaymentViewModel!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    func configureViewWith(paymentViewModel: PaymentViewModel, delegate: CommonPaymentViewDelegate) {
        self.paymentViewModel = paymentViewModel
        self.delegate = delegate
        
        searchFieldContainer.wantsLayer = true
        searchFieldContainer.layer?.cornerRadius = searchFieldContainer.frame.size.height / 2
        searchFieldContainer.layer?.borderWidth = 1
        searchFieldContainer.layer?.borderColor = NSColor.Sphinx.LightDivider.cgColor

        nextButtonContainer.wantsLayer = true
        nextButtonContainer.layer?.cornerRadius = nextButtonContainer.frame.size.height / 2
        nextButtonContainer.isHidden = true
        searchField.delegate = self
        
        loadData()
    }
    
    func loadData() {
        allContacts = getContactsToShow()
        configureAllContactCollectionView()
        configureAddedContactsCollectionView()
    }
    
    func configureAllContactCollectionView() {
        contactsCVDataSource = GroupAllContactsDataSource(collectionView: contactsCollectionView, delegate: self, title: "group.members.upper".localized)
        contactsCollectionView.delegate = contactsCVDataSource
        contactsCollectionView.dataSource = contactsCVDataSource

        contactsCVDataSource.reloadContacts(contacts: allContacts)
    }
    
    func configureAddedContactsCollectionView() {
        addedContactsScrollView.contentInsets = NSEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        addedContactsScrollView.horizontalScroller?.alphaValue = 0.0
        
        addedContactCVDataSource = GroupAddedContactsDataSource(collectionView: addedContactsCollectionView, delegate: self)
        toggleCollectionView(show: false, animated: false)

        addedContactsCollectionView.delegate = addedContactCVDataSource
        addedContactsCollectionView.dataSource = addedContactCVDataSource
        
        toggleCollectionView(show: getCurrentPayment().contacts.count > 0, animated: false)
        
        for contact in getCurrentPayment().contacts {
            addedContactCVDataSource.addContact(contact: contact)
            contactsCVDataSource.select(contact: contact)
            selectedContactIds.append(contact.id)
        }
        toggleNextButton()
    }
    
    func getCurrentPayment() -> PaymentViewModel.PaymentObject {
        return paymentViewModel.currentPayment
    }
    
    func getChatContacts() -> [UserContact] {
        return getCurrentPayment().chat?.getContacts() ?? []
    }
    
    func getContactsToShow() -> [UserContact] {
        return getChatContacts().filter { !$0.isOwner && !$0.shouldBeExcluded() }
    }
    
    @IBAction func nextButtonClicked(_ sender: Any) {
        let selectedContacts = allContacts.filter {
            return selectedContactIds.contains($0.id)
        }
        paymentViewModel.setContacts(contacts: selectedContacts)
        
        delegate?.didConfirm()
    }
    
    @IBAction func closeButtonClicked(_ sender: Any) {
        delegate?.shouldClose()
    }
    
    @IBAction func selectAllButtonClicked(_ sender: Any) {
        contactsCVDataSource.selectAll()
    }
}

extension GroupMembersView : GroupAllContactsDSDelegate {
    func didToggleAll(selected: Bool) {
        selectedContactIds = selected ? allContacts.map { $0.id } : []
        updateLayouts(added: selected, ids: selectedContactIds)
    }
    
    func shouldUpdateHeader(allSelected: Bool) {
        selectAllButton.title = allSelected ? "unselect.all.upper".localized : "select.all.upper".localized
    }
    
    func didAddedContactWith(id: Int) {
        selectedContactIds.append(id)
        updateLayouts(added: true, ids: [id])
    }
    
    func didRemoveContactWith(id: Int) {
        if let index = selectedContactIds.firstIndex(of: id) {
            selectedContactIds.remove(at: index)
        }
        updateLayouts(added: false, ids: [id])
    }
    
    func updateLayouts(added: Bool, ids: [Int]) {
        let shouldShow = selectedContactIds.count > 0
        if added {
            toggleCollectionView(show: shouldShow, completion: {
                self.reloadCollectionView(added: added, contactIds: ids)
            })
        } else {
            reloadCollectionView(added: false, contactIds: ids)
            toggleCollectionView(show: shouldShow)
        }
        toggleNextButton()
    }
    
    func reloadCollectionView(added: Bool, contactIds: [Int]) {
        let contactId = (contactIds.count == 1) ? contactIds[0] : nil
        if let contactId = contactId, let contact = UserContact.getContactWith(id: contactId) {
            if added {
                addedContactCVDataSource.addContact(contact: contact)
            } else {
                addedContactCVDataSource.removeContact(contact: contact)
            }
        } else {
            if added {
                let contacts = contactIds.map { UserContact.getContactWith(id: $0) }
                addedContactCVDataSource.addAll(contacts: contacts)
            } else {
                addedContactCVDataSource.removeAll()
            }
        }
    }
    
    func toggleNextButton() {
        let shouldShow = selectedContactIds.count > 0
        nextButtonContainer.isHidden = !shouldShow
    }
    
    func toggleCollectionView(show: Bool, completion: (() -> ())? = nil, animated: Bool = true) {
        let expectedHeight:CGFloat = show ? 102 : 12
        
        if addedContactsCollectionViewHeight?.constant == expectedHeight {
            completion?()
            return
        }
        
        if !animated {
            addedContactsCollectionViewHeight?.constant = expectedHeight
            addedContactsCollectionView.superview?.layoutSubtreeIfNeeded()
            completion?()
        } else {
            AnimationHelper.animateViewWith(duration: 0.3, animationsBlock: {
                self.addedContactsCollectionViewHeight?.constant = expectedHeight
                self.layoutSubtreeIfNeeded()
            }, completion: {
                completion?()
            })
        }
    }
}

extension GroupMembersView : GroupContactCellDelegate {
    func didDeleteContact(contact: UserContact, item: NSCollectionViewItem) {
        contactsCVDataSource.unselect(contact: contact)
        didRemoveContactWith(id: contact.id)
    }
}

extension GroupMembersView : NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        contactsCVDataSource.processContacts(searchTerm: searchField.stringValue.lowercased(), selectedContactIds: selectedContactIds)
        contactsCollectionView.reloadData()
    }
}
