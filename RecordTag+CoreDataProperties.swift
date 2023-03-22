//
//  RecordTag+CoreDataProperties.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/20.
//
//

import Foundation
import CoreData
import SwiftUI


extension RecordTag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RecordTag> {
        return NSFetchRequest<RecordTag>(entityName: "RecordTag")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var tagName: String?
    @NSManaged public var color: String?
    @NSManaged public var createdDate: Date?
    @NSManaged public var records: NSSet?

    public var wrappedID: UUID {
        id ?? UUID()
    }
    
    public var wrappedcreatdDate: Date {
        createdDate ?? Date.now
    }
    
    public var wrappedTagName: String {
        tagName ?? ""
    }
    
    public var wrappedColor: Color {
        Color(hex: self.color ?? "")
    }
    
    public func setColor(color: Color) {
        self.color = color.toHexString()
    }
    
    public var wrappedRecords: [Record] {
        let set = records as? Set<Record> ?? []
        
        return set.sorted {
            $0.wrappedcreateDate > $1.wrappedcreateDate
        }
    }
}

// MARK: Generated accessors for records
extension RecordTag {

    @objc(addRecordsObject:)
    @NSManaged public func addToRecords(_ value: Record)

    @objc(removeRecordsObject:)
    @NSManaged public func removeFromRecords(_ value: Record)

    @objc(addRecords:)
    @NSManaged public func addToRecords(_ values: NSSet)

    @objc(removeRecords:)
    @NSManaged public func removeFromRecords(_ values: NSSet)

}

extension RecordTag : Identifiable {

}
