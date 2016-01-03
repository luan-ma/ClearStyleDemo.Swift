//
//  TDCToDoItem.swift
//  ToDoClearStyle
//
//  Created by LuanMa on 16/1/2.
//  Copyright © 2016年 luanma. All rights reserved.
//

import Foundation

class TDCToDoItem: NSObject {
    
    // A text description of this item.
    var text: String = ""

    // A Boolean value that determines the completed state of this item.
    var completed = false

    init(text: String) {
        super.init()
        self.text = text
    }
}