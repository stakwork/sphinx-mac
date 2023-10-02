//
//  NewChatViewController+FetchControllerExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

extension NewChatViewController: NSFetchedResultsControllerDelegate {
    func configureFetchResultsController() {
        if isThread {
            return
        }
        
        if let contact = contact {
            let fetchRequest = UserContact.FetchRequests.matching(id: contact.id)

            contactResultsController = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: CoreDataManager.sharedManager.persistentContainer.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            contactResultsController.delegate = self
            
            do {
                try contactResultsController.performFetch()
            } catch {}
        }
        
        if let chat = chat {
            let fetchRequest = Chat.FetchRequests.matching(id: chat.id)

            chatResultsController = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: CoreDataManager.sharedManager.persistentContainer.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            chatResultsController.delegate = self
            
            do {
                try chatResultsController.performFetch()
            } catch {}
        }
    }
    
    func resetFetchedResultsControllers() {
        contactResultsController = nil
        chatResultsController = nil
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        if
            let resultController = controller as? NSFetchedResultsController<NSManagedObject>,
            let firstSection = resultController.sections?.first {
            
            var shouldReloadView = false
        
            if let contacts = firstSection.objects as? [UserContact], let contact = contacts.first {
                self.contact = contact
                shouldReloadView = true
            }
            
            if let chats = firstSection.objects as? [Chat], let chat = chats.first {
                self.chat = chat
                shouldReloadView = true
            }
        
            if shouldReloadView {
                setupChatTopView()
                setupChatBottomView()
            }
            
        }
    }
}
