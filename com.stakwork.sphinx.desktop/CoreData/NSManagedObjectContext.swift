//
//  NSManagedObjectContext.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 11/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {
    
    convenience init(parentContext parent: NSManagedObjectContext, concurrencyType: NSManagedObjectContextConcurrencyType) {
        self.init(concurrencyType: concurrencyType)
        self.parent = parent
    }
    
    func deleteAllObjects() {
        if let entitesByName = persistentStoreCoordinator?.managedObjectModel.entitiesByName {
            for (_, entityDescription) in entitesByName {
                deleteAllObjectsForEntity(entityDescription)
            }
        }
    }
    
    func deleteAllObjectsForEntity(_ entity: NSEntityDescription) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.entity = entity
        fetchRequest.includesPropertyValues = false
        
        var fetchResults: [AnyObject]
        do {
            fetchResults = try fetch(fetchRequest)
        } catch {
            return
        }
        
        if let managedObjects = fetchResults as? [NSManagedObject] {
            for object in managedObjects {
                delete(object)
            }
        }
    }
}
