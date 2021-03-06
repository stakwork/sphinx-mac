//
//  CoreDataManager.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 11/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import CoreData

class CoreDataManager {
    
    static let sharedManager = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: "com_stakwork_sphinx_desktop")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func saveContext() {
        let context = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func clearCoreDataStore() {
        let context = CoreDataManager.sharedManager.persistentContainer.viewContext
        context.performAndWait {
            context.deleteAllObjects()
            do {
                try context.save()
            } catch {
                print("Error on deleting CoreData entities")
            }
        }
    }
    
    func resetContext() {
        let context = CoreDataManager.sharedManager.persistentContainer.viewContext
        context.reset()
    }
    
    func deleteExpiredInvites() {
        for contact in UserContact.getPendingContacts() {
            if let invite = contact.invite, !contact.isOwner, !contact.isConfirmed() && invite.isExpired() {
                invite.removeFromPaymentProcessed()
                API.sharedInstance.deleteContact(id: contact.id, callback: { _ in })
                deleteContactObjectsFor(contact)
            }
        }

        saveContext()
    }
    
    func deleteContactObjectsFor(_ contact: UserContact) {
        if let chat = contact.getConversation() {
            for message in chat.getAllMessages(limit: nil) {
                MediaLoader.clearMessageMediaCache(message: message)
                deleteObject(object: message)
            }
            deleteObject(object: chat)
        }

        if let subscription = contact.getCurrentSubscription() {
            deleteObject(object: subscription)
        }

        if let invite = contact.invite {
            invite.removeFromPaymentProcessed()
        }

        deleteObject(object: contact)
        CoreDataManager.sharedManager.saveContext()
    }
    
    func deleteChatObjectsFor(_ chat: Chat) {
        if let messagesSet = chat.messages, let groupMessages = Array<Any>(messagesSet) as? [TransactionMessage] {
            for m in groupMessages {
                MediaLoader.clearMessageMediaCache(message: m)
                deleteObject(object: m)
            }
        }
        deleteObject(object: chat)
        saveContext()
    }
    
    func getAllOfType<T>(entityName: String, sortDescriptors: [NSSortDescriptor]? = nil) -> [T] {
        let managedContext = persistentContainer.viewContext
        var objects:[T] = [T]()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"\(entityName)")
        fetchRequest.sortDescriptors = sortDescriptors ?? [NSSortDescriptor(key: "id", ascending: false)]
        
        do {
            try objects = managedContext.fetch(fetchRequest) as! [T]
        } catch let error as NSError {
            print("Error: " + error.localizedDescription)
        }
        
        return objects
    }
    
    func getObjectOfTypeWith<T>(id: Int, entityName: String) -> T? {
        let managedContext = persistentContainer.viewContext
        var objects:[T] = [T]()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"\(entityName)")
        let predicate = NSPredicate(format: "id == %d", id)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            try objects = managedContext.fetch(fetchRequest) as! [T]
        } catch let error as NSError {
            print("Error: " + error.localizedDescription)
        }
        
        if objects.count > 0 {
            return objects[0]
        }
        return nil
    }
    
    func getObjectsOfTypeWith<T>(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor], entityName: String, fetchLimit: Int? = nil) -> [T] {
        let managedContext = persistentContainer.viewContext
        var objects:[T] = [T]()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"\(entityName)")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        
        if let fetchLimit = fetchLimit {
            fetchRequest.fetchLimit = fetchLimit
        }
        
        do {
            try objects = managedContext.fetch(fetchRequest) as! [T]
        } catch let error as NSError {
            print("Error: " + error.localizedDescription)
        }
        
        return objects
    }
    
    func getObjectsCountOfTypeWith(predicate: NSPredicate? = nil, entityName: String) -> Int {
        let managedContext = persistentContainer.viewContext
        var count:Int = 0
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"\(entityName)")
        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }
        
        do {
            try count = managedContext.count(for: fetchRequest)
        } catch let error as NSError {
            print("Error: " + error.localizedDescription)
        }
        
        return count
    }
    
    func getObjectOfTypeWith<T>(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor], entityName: String) -> T? {
        let managedContext = persistentContainer.viewContext
        var objects:[T] = [T]()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"\(entityName)")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.fetchLimit = 1
        
        do {
            try objects = managedContext.fetch(fetchRequest) as! [T]
        } catch let error as NSError {
            print("Error: " + error.localizedDescription)
        }
        
        if objects.count > 0 {
            return objects[0]
        }
        return nil
    }
    
    func deleteObject(object: NSManagedObject) {
        let managedContext = persistentContainer.viewContext
        managedContext.delete(object)
        saveContext()
    }
}
