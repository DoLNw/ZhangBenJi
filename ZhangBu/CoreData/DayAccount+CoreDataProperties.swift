//
//  DayAccount+CoreDataProperties.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/12.
//
//

import Foundation
import CoreData
import SwiftUI


extension DayAccount {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DayAccount> {
        return NSFetchRequest<DayAccount>(entityName: "DayAccount")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var name: String?
    @NSManaged public var records: NSSet?
    
    
    public var wrappedID: UUID {
        id ?? UUID()
    }
    
    public var wrappedName: String {
        name ?? "name"
    }
    
    public var wrappedDate: Date {
        date ?? Date()
    }
    
    public var wrappedRecords: [Record] {
        let set = records as? Set<Record> ?? []
        
        
//        return set.sorted { a1, a2 in
//            a1.wrappedcreatedDate < a2.wrappedcreateDate
//        }
//        return set.sorted {
//            $0.wrappedCreatedDate < $1.wrappedCreatedDate
//        }
        
        return set.sorted {
            $0.wrappedcreateDate > $1.wrappedcreateDate
        }
    }
}

// MARK: Generated accessors for records
extension DayAccount {

    @objc(addRecordsObject:)
    @NSManaged public func addToRecords(_ value: Record)

    @objc(removeRecordsObject:)
    @NSManaged public func removeFromRecords(_ value: Record)

    @objc(addRecords:)
    @NSManaged public func addToRecords(_ values: NSSet)

    @objc(removeRecords:)
    @NSManaged public func removeFromRecords(_ values: NSSet)

}

extension DayAccount : Identifiable {

}
