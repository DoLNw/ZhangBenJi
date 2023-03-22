//
//  EditRecordTagNameView.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/21.
//

// 每一个标签都可以被修改，所以需要用一个DetailView来绑定
// 因为tags是数组，不好写数组的Binding

import SwiftUI

struct EditRecordTagDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let tag: RecordTag
    
    @State var tagName = ""
    @State var tagColor = Color.red
    
    var body: some View {
        HStack {
            TextField("\(tag.wrappedTagName)", text: $tagName)
                .onChange(of: tagName) { newValue in
                    tag.tagName = tagName
                    
                    viewContextSave()
                }
            
            ColorPicker("", selection: $tagColor)
                .onChange(of: tagColor) { newValue in
                    tag.setColor(color: tagColor)
                    
                    viewContextSave()
                }
        }
        .onAppear {
            tagName = tag.wrappedTagName
            tagColor = tag.wrappedColor
        }
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

