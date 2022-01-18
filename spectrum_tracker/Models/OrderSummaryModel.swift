//
//  OrderTrackerModel.swift
//  spectrum_tracker
//
//  Created by JO on 2018/6/18.
//  Copyright © 2018 JO. All rights reserved.
//

import Foundation

class OrderSummaryModel {

    var vehicle: String!
    var tracker: String!
    var dataPlan: String!
    var LTEData: String!
    var dateTd: String!
    var autoRenew: String!

    
    init() {
        
    }
    
    init(_ vehicle: String,
    _ tracker: String,
    _ dataPlan: String,
    _ LTEData: String,
    _ dateTd: String,
    _ autoRenew: String) {
        self.vehicle = vehicle
        self.tracker = tracker
        self.dataPlan = dataPlan
        self.LTEData = LTEData
        self.dateTd = dateTd
        self.autoRenew = autoRenew
    }
}
