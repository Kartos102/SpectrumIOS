//
//  CreditTokenInfoModel.swift
//  spectrum_tracker
//
//  Created by JO on 2018/5/7.
//  Copyright © 2018 JO. All rights reserved.
//

import Foundation

class CreditTokenInfoModel {
    var token_type: String!
    var token_number: String!
    var cardholder_name: String!
    var card_type: String!
    var exp_date: String!
    
    init(_ token_type: String,
         _ token_number: String,
         _ cardholder_name: String,
         _ card_type: String,
         _ exp_date: String) {
        self.token_type = token_type
        self.token_number = token_number
        self.cardholder_name = cardholder_name
        self.card_type = card_type
        self.exp_date = exp_date
    }
    
}
