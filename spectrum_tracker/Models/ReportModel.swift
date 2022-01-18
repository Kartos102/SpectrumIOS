//
//  ReportModel.swift
//  spectrum_tracker
//
//  Created by Admin on 6/13/19.
//  Copyright © 2019 JO. All rights reserved.
//

import Foundation
struct ReportModel {
    let title: String
    let value: String
    let chartValue: [ReportChartModel]
    let eventValue: [ReportEventModel]
}
