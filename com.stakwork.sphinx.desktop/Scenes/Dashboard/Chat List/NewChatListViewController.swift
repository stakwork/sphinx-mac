//
//  NewChatListViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 05/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol NewChatListViewControllerDelegate: AnyObject {
    func didClickRowAt(index: Int, tab: NewChatListViewController.Tab)
}

class NewChatListViewController: NSViewController {
    
    weak var delegate: NewChatListViewControllerDelegate?
    
    @IBOutlet weak var chatsCollectionView: NSCollectionView!
    
    var chatListObjects: [ChatListCommonObject] = []
    
    var onChatSelected: ((ChatListCommonObject) -> Void)?
    var onContentScrolled: ((NSScrollView) -> Void)?

    private var currentDataSnapshot: DataSourceSnapshot!
    private var dataSource: DataSource!
    
    private var owner: UserContact!
    
    var selectedIndex: Int? = nil
    
    public enum Tab: Int {
        case Friends
        case Tribes
    }
    
    var tab: Tab = Tab.Friends
    
    private let itemContentInsets = NSDirectionalEdgeInsets(
        top: 0,
        leading: 0,
        bottom: 0,
        trailing: 0
    )
    
    static func instantiate(
        tab: Tab,
        delegate: NewChatListViewControllerDelegate?
    ) -> NewChatListViewController {
        let viewController = StoryboardScene.Dashboard.newChatListViewController.instantiate()
        viewController.tab = tab
        viewController.delegate = delegate
        return viewController
    }
    
    public func updateWithNewChats(
        _ chats: [ChatListCommonObject]
    ) {
        self.chatListObjects = chats
        
        updateSnapshot()
    }
    
    public func updateWith(
        newSelectedIndex: (Tab, Int)
    ) {
        if newSelectedIndex.0 == tab {
            selectedIndex = newSelectedIndex.1
        } else {
            selectedIndex = nil
        }
        
        DispatchQueue.main.async {
            self.updateSnapshot()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadChatsList()
    }
    
    func loadChatsList() {
        registerViews()
        configureCollectionView()
        configureDataSource()
    }
    
}

// MARK: - Layout & Data Structure
@available(macOS 10.15.1, *)
extension NewChatListViewController {
    enum CollectionViewSection: Int, CaseIterable {
        case all
    }
    
    struct DataSourceItem: Hashable {
        
        var objectId: String
        var messageId: Int?
        var messageSeen: Bool
        var contactStatus: Int?
        var inviteStatus: Int?
        var muted: Bool
        var selected: Bool

        init(
            objectId: String,
            messageId: Int?,
            messageSeen: Bool,
            contactStatus: Int?,
            inviteStatus: Int?,
            muted: Bool,
            selected: Bool
        )
        {
            self.objectId = objectId
            self.messageId = messageId
            self.messageSeen = messageSeen
            self.contactStatus = contactStatus
            self.inviteStatus = inviteStatus
            self.muted = muted
            self.selected = selected
        }
        
        static func == (lhs: DataSourceItem, rhs: DataSourceItem) -> Bool {
            let isEqual =
                lhs.objectId == rhs.objectId &&
                lhs.messageId == rhs.messageId &&
                lhs.messageSeen == rhs.messageSeen &&
                lhs.contactStatus == rhs.contactStatus &&
                lhs.inviteStatus == rhs.inviteStatus &&
                lhs.muted == rhs.muted &&
                lhs.selected == rhs.selected
            
            return isEqual
         }

        func hash(into hasher: inout Hasher) {
            hasher.combine(objectId)
            hasher.combine(messageId)
            hasher.combine(messageSeen)
            hasher.combine(contactStatus)
            hasher.combine(inviteStatus)
            hasher.combine(muted)
            hasher.combine(selected)
        }
    }


    typealias CollectionViewCell = ChatListCollectionViewItem
    typealias CellDataItem = DataSourceItem
    
    @available(macOS 10.15.1, *)
    typealias DataSource = NSCollectionViewDiffableDataSource<CollectionViewSection, CellDataItem>
    
    @available(macOS 10.15.1, *)
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<CollectionViewSection, CellDataItem>
}

// MARK: - Collection View Configuration and View Registration
extension NewChatListViewController {

    func registerViews() {
        if let nib = CollectionViewCell.nib {
            chatsCollectionView.register(
                nib,
                forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: CollectionViewCell.reuseID)
            )
        }
    }


    func configureCollectionView() {
        chatsCollectionView.collectionViewLayout = makeLayout()
        chatsCollectionView.wantsLayer = true
        chatsCollectionView.layer?.backgroundColor = NSColor.Sphinx.DashboardHeader.cgColor
        chatsCollectionView.delegate = self
    }
    
//    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        onContentScrolled?(scrollView)
//    }
}

// MARK: - Layout Composition
extension NewChatListViewController {

    func makeSectionHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(80)
        )

        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: NSCollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }


    func makeListSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = itemContentInsets


        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(Constants.kChatListRowHeight)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])


        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .none

        return section
    }


    func makeSectionProvider() -> NSCollectionViewCompositionalLayoutSectionProvider {
        { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            switch CollectionViewSection(rawValue: sectionIndex) {
            case .all:
                return self.makeListSection()
            case nil:
                return nil
            }
        }
    }


    func makeLayout() -> NSCollectionViewLayout {
        let layoutConfiguration = NSCollectionViewCompositionalLayoutConfiguration()

        let layout = NSCollectionViewCompositionalLayout(
            sectionProvider: makeSectionProvider()
        )

        layout.configuration = layoutConfiguration

        return layout
    }
}

// MARK: - Private Helpers
extension NewChatListViewController {
    
    func reloadCollectionView() {
        loadChatsList()
    }
    
    func configureDataSource() {
        dataSource = makeDataSource()

        updateSnapshot()
    }
    
    func makeDataSource() -> DataSource {
        return DataSource(
            collectionView: chatsCollectionView,
            itemProvider: makeCellProvider()
        )
    }
}

// MARK: - Data Source View Providers
extension NewChatListViewController {

    func makeCellProvider() -> DataSource.ItemProvider {
        { (collectionView, indexPath, chatItem) -> NSCollectionViewItem? in
            let section = CollectionViewSection.allCases[indexPath.section]

            switch section {
            case .all:
                guard let cell = collectionView.makeItem(
                    withIdentifier: NSUserInterfaceItemIdentifier(
                        rawValue: CollectionViewCell.reuseID
                    ),
                    for: indexPath
                ) as? CollectionViewCell else { return nil }

                cell.rowSelected = (self.selectedIndex == indexPath.item)
                cell.owner = self.owner
                cell.chatListObject = self.chatListObjects[indexPath.item]

                return cell
            }
        }
    }
}

// MARK: - Data Source Snapshot
extension NewChatListViewController {

    func updateSnapshot() {
        guard let dataSource = dataSource else {
            return
        }
        
        updateOwner()
        
        var snapshot = DataSourceSnapshot()

        snapshot.appendSections(CollectionViewSection.allCases)

        let items = chatListObjects.enumerated().map { (index, element) in
            
            DataSourceItem(
                objectId: element.getObjectId(),
                messageId: element.lastMessage?.id,
                messageSeen: element.isSeen(ownerId: owner.id),
                contactStatus: element.getContactStatus(),
                inviteStatus: element.getInviteStatus(),
                muted: element.isMuted(),
                selected: selectedIndex == index
            )
            
        }

        snapshot.appendItems(items, toSection: .all)
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func updateOwner() {
        if owner == nil {
            owner = UserContact.getOwner()
        }
    }
}

extension NewChatListViewController : NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        if let indexPath = indexPaths.first {
            delegate?.didClickRowAt(
                index: indexPath.item,
                tab: tab
            )
        }
    }
}
