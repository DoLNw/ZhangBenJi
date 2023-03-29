//
//  MySegmentSelection.swift
//  ZhangBu
//
//  Created by Jcwang on 2023/3/28.
//

import SwiftUI

struct MySegmentSelection: View {
    let selectedChangeGenerator = UISelectionFeedbackGenerator()
    
    
    
    @Binding var segmentationSelection: SegmentationEnum
    
    
    var body: some View {
        HStack {
            ForEach(SegmentationEnum.allCases, id: \.self) { option in
                Spacer()
                Text("\(option.rawValue)")
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(option.rawValue == segmentationSelection.rawValue ? Color.accentColor : Color(.systemFill))
                            .frame(width: 60, height: 30)
                            .shadow(color: .accentColor, radius: 5, x: 2, y: 2)
                    }
                    .frame(width: 60, height: 30)
                    .onTapGesture {
                        segmentationSelection = option
                        
                        selectedChangeGenerator.selectionChanged()
                    }
            }
            Spacer()
        }
    }
}

//struct MySegmentSelection_Previews: PreviewProvider {
//    static var previews: some View {
//        MySegmentSelection()
//    }
//}
