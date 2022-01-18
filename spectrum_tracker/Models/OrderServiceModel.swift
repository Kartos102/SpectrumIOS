//
//  OrderTrackerModel.swift
//  spectrum_tracker
//
//  Created by JO on 2018/5/7.
//  Copyright © 2018 JO. All rights reserved.
//

import Foundation

class OrderServiceModel {

    var name: String!
    var trackerId: String!
    var expirationDate: String!
    var servicePlanList: [ServicePlanModel]!
    var lteDataList: [LTEDataModel]!
    var autoReview: Bool!
    
    var selectedServicePlanId: Int!
    var selectedLTEDataId: Int!
    
    var servicePlanEnabled: Bool!
    var lteDataEnabled: Bool!
    
    init() {
        
    }
    
    init(_ name: String,
    _ trackerId: String,
    _ expirationDate: String,
    _ servicePlanList: [ServicePlanModel],
    _ lteDataList: [LTEDataModel],
    _ autoReview: Bool,
    
    _ selectedServicePlanId: Int,
    _ selectedLTEDataId: Int,
    
    _ servicePlanEnabled: Bool,
    _ lteDataEnabled: Bool) {
        self.name = name
        self.trackerId = trackerId
        self.expirationDate = expirationDate
        self.servicePlanList = servicePlanList
        self.lteDataList = lteDataList
        self.autoReview = autoReview
        self.selectedServicePlanId = selectedServicePlanId
        self.selectedLTEDataId = selectedLTEDataId
        self.servicePlanEnabled = servicePlanEnabled
        self.lteDataEnabled = lteDataEnabled
    }
}
