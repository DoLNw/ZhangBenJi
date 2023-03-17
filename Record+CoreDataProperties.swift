//
//  Record+CoreDataProperties.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/17.
//
//

import Foundation
import CoreData


extension Record {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Record> {
        return NSFetchRequest<Record>(entityName: "Record")
    }

    @NSManaged public var createDate: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var item: String?
    @NSManaged public var price: Double
    @NSManaged public var belongDayAccount: DayAccount?
    
    public var wrappedcreateDate: Date {
        createDate ?? Date()
    }
    
    public var wrappedID: UUID {
        id ?? UUID()
    }
    
    public var wrappedItem: String {
        item ?? ""
    }
}

extension Record : Identifiable {

}
