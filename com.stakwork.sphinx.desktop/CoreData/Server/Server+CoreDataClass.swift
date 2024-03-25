//
//  Server+CoreDataClass.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 25/03/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON


@objc(Server)
public class Server: NSManagedObject {
    
    public static func getAllServers(context: NSManagedObjectContext) -> [Server] {
        let fetchRequest = NSFetchRequest<Server>(entityName: "Server")
        
        do {
            let servers = try context.fetch(fetchRequest)
            return servers
        } catch let error as NSError {
            print("Error fetching servers: \(error.localizedDescription)")
            return []
        }
    }
    
}
