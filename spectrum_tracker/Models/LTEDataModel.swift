//
//  OrderTrackerModel.swift
//  spectrum_tracker
//
//  Created by JO on 2018/5/7.
//  Copyright © 2018 JO. All rights reserved.
//

import Foundation

class LTEDataModel {
    var lteData: String!
    var price: Double!
    
    init(_ lteData: String,
    _ price: Double) {
        self.lteData = lteData
        self.price = price
    }
}
