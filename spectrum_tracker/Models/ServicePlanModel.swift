//
//  OrderTrackerModel.swift
//  spectrum_tracker
//
//  Created by JO on 2018/5/7.
//  Copyright © 2018 JO. All rights reserved.
//

import Foundation

class ServicePlanModel {
    var servicePlan: String!
    var price: Double!
    var planDetails: [String] = []
    
    init(_ servicePlan: String, _ price: Double, _ planDetails: [String]) {
        self.servicePlan = servicePlan
        self.price = price
        self.planDetails = planDetails
    }
}
