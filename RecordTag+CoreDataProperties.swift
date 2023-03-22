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

// 一个DayAccount有多个Record，所以DayAccount下的relation是对多，Record下的relation是对一。
// 一个Record有一个RecordTag，但是RecordTag可以对应多个Record，所以Record下的relation是对一，Tag下的relation是对多。
// 总的来说，Record都是对一，另外两个都是对多。

// 此处用的tag的数据关联，真的比叶记的关联做的好太多了。
// Core Data中一般不需要字典，数组这些东西。字典，数组都只需要加入一个关联即可，一对多，然后字典的话，其实可以开放出来，化作结构体。
// 上面标签作为relation之后，单独访问所有标签只需要fetch标签即可，单独record的标签只需要访问record的belongTag就可以，方便很多。


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
