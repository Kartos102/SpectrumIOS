//
//  ShippingAddressHolder.swift
//  spectrum_tracker
//
//  Created by JO on 2018/5/8.
//  Copyright © 2018 JO. All rights reserved.
//

import Foundation

class ShippingAddressHolder {
    var name: String!
    var email: String!
    var streetAddress: String!
    var city: String!
    var zipCode: String!
    var state: String!
    
    init(    _ name: String,
    _ email: String,
    _ streetAddress: String,
    _ city: String,
    _ zipCode: String,
    _ state: String) {
        self.name = name
        self.email = email
        self.streetAddress = streetAddress
        self.city = city
        self.zipCode = zipCode
        self.state = state
    }
    
}
