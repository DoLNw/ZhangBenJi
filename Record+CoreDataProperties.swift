//
//  Record+CoreDataProperties.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/20.
//
//

import Foundation
import CoreData

// 一个DayAccount有多个Record，所以DayAccount下的relation是对多，Record下的relation是对一。
// 一个Record有一个RecordTag，但是RecordTag可以对应多个Record，所以Record下的relation是对一，Tag下的relation是对多。
// 总的来说，Record都是对一，另外两个都是对多。

extension Record {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Record> {
        return NSFetchRequest<Record>(entityName: "Record")
    }

    @NSManaged public var createDate: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var item: String?
    @NSManaged public var price: Double
    @NSManaged public var belongDayAccount: DayAccount?
    @NSManaged public var belongTag: RecordTag?
    
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
