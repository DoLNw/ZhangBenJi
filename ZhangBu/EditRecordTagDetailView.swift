//
//  EditRecordTagNameView.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/21.
//

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

//struct EditRecordTagNameView_Previews: PreviewProvider {
//    static var previews: some View {
//        EditRecordTagNameView()
//    }
//}
