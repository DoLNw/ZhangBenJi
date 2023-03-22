//
//  EditRecordTagView.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/20.
//

import SwiftUI

// 需要至少存在一个标签
// 然后编辑标签是让currentRecordTag为nil实现的

struct EditRecordTagView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.editMode) var editMode
    
    // DayAccount中每一个Record会有一个RecordTag，我这里从tag入手，先拿到所有的tag
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \RecordTag.createdDate, ascending: true)],
        animation: .default)
    var tags: FetchedResults<RecordTag>
    
    @State var tagNames = [String]()
    
    var body: some View {
        Form {
            
            Section {
                HStack {
                    Spacer()
                    
                    EditButton()
                }
                
                List {
                    ForEach(tags) { tag in
                        EditRecordTagDetailView(tag: tag)
                            .environment(\.managedObjectContext, viewContext)
                    }
                    .onDelete { offset in
                        // 只剩下一条的话删除不掉
                        if tags.count >= 1 {
                            offset.map({tags[$0]}).forEach(viewContext.delete(_:))
                            viewContextSave()
                        }
                    }
                    .onMove { indexSet, destination in
                        // 此处交换貌似有一个小问题，一个移动之后，iCloud同步之后另一边的不会马上重新排序，重启会排序。但是考虑到这样的业务不多，就没有做。
                        // 要做的话估计是标签的删除以及重新加入，但是这样的话，关联的Record会有问题。
                        // Record的createdDate是给record排序用的，与RecordTag的的createdDate是一样的。
                        indexSet.forEach { source in
//                            print(source)
//                            print("aaa")
//                            print(destination)
                            if source > destination { // 从下往上
                                let tempTagCreatedDate = tags[source].wrappedcreatdDate
                                
                                tags[source].createdDate = tags[destination].createdDate

                                for i in destination ..< source-1 {
                                    print(tags[i].wrappedTagName)
                                    tags[i].createdDate = tags[i+1].createdDate
                                }
                                
                                tags[source-1].createdDate = tempTagCreatedDate
                            } else {                  // 从上往下
                                let tempTagCreatedDate = tags[source].wrappedcreatdDate
                                
                                tags[source].createdDate = tags[destination-1].createdDate

                                for i in (source+2 ..< destination).reversed() {
                                    tags[i].createdDate = tags[i-1].createdDate
                                }
                                
                                tags[source+1].createdDate = tempTagCreatedDate
                            }
                        }
                        
                        viewContextSave()
                    }
                }
                .listRowSeparatorTint(.accentColor)
            }
            
            
            Section {
                HStack {
                    Spacer()
                    
                    Button("添加标签") {
                        addNewTag()
                    }
                    
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            for tag in tags {
                tagNames.append(tag.wrappedTagName)
            }
        }
    }
    
    func debugPrintTagCreatedDate() {
        for tag in tags {
            print("\(tag.wrappedTagName): \(tag.wrappedcreatdDate.description)")
        }
    }
    
    func addNewTag() {
        let newTag = RecordTag(context: viewContext)
        newTag.id = UUID()
        newTag.setColor(color: .accentColor)
        newTag.tagName = "默认"
        newTag.createdDate = Date()
        
//        newTag.addToRecords()  // 此处只是添加一个新的标签
        viewContextSave()
    }
    
    func viewContextSave() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct EditRecordTagView_Previews: PreviewProvider {
    static var previews: some View {
        EditRecordTagView()
    }
}
