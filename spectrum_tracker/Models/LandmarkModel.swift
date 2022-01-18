//
//  LandmarkModel.swift
//  spectrum_tracker
//
//  Created by test on 1/18/22.
//  Copyright © 2022 JO. All rights reserved.
//

import Foundation
class LandmarkModel {
    var name: String!
    var type: String!
    var lat: String!
    var lng: String!
    
    init(_ name: String,
    _ type: String,
    _ lat: String,
    _ lng: String) {
        self.name = name
        self.type = type
        self.lat = lat
        self.lng = lng
    }
}
