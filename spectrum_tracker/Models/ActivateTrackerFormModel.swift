//
//  ActivateTrackerFormModel.swift
//  spectrum_tracker
//
//  Created by JO on 2018/5/7.
//  Copyright © 2018 JO. All rights reserved.
//

import Foundation

class ActivateTrackerFormModel {
    
    var spectrumId: String = ""
    var plateNumber: String = ""
    var category: String = ""
    var isAutoRenew = true
    var cardName: String = ""
    var cardNumber: String = ""
    var cardStreet = ""
    var cardCity = ""
    var cardState = ""
    var cardZip = ""
    var cardCountry = ""
    var cardExpiry: String = ""
    var driverName: String = ""
    var cvCode: String = ""
    //var trackerCountry: String!
    
    init(_ spectrumId: String,
    _ plateNumber: String,
    _ driverName: String,
    //_ trackerCountry: String,
    _ cardName: String,
    _ cardNumber: String,
    _ cardExpiry: String,
    _ cvCode: String) {
        self.spectrumId = spectrumId
        self.plateNumber = plateNumber
        self.cardName = cardName
        self.cardNumber = cardNumber
        self.cardExpiry = cardExpiry
        self.driverName = driverName
        //self.trackerCountry = trackerCountry
        self.cvCode = cvCode
    }
    
}
