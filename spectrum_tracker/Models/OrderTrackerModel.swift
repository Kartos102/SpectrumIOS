//
//  OrderTrackerModel.swift
//  spectrum_tracker
//
//  Created by JO on 2018/5/7.
//  Copyright © 2018 JO. All rights reserved.
//

import Foundation

class OrderTrackerModel {
    var image: String!
    var name: String!
    var description: String!
    var count: Int!
    var price: Double!
    
    init(_ image: String,
    _ name: String,
    _ description: String,
    _ count: Int,
    _ price: Double) {
        self.image = image
        self.name = name
        self.description = description
        self.count = count
        self.price = price
    }
}
