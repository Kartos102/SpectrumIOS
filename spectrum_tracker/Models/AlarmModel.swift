//
//  AlarmModel.swift
//  spectrum_tracker
//
//  Created by Yuanxue Ri on 20/11/2018.
//  Copyright © 2018 JO. All rights reserved.
//

import Foundation
import SwiftyJSON

class AlarmModel {
    var speedLimit : String!
    var fatigueTime : String!
    var harshTurn : String!
    var harshAcceleration : String!
    var harshDeceleration : String!
    var email : String!
    var phoneNumber : String!
    
    var  speedingAlarmStatus : Bool!
    var  fatigueAlarmStatus : Bool!
    var  harshTurnAlarmStatus : Bool!
    var  harshAcceAlarmStatus : Bool!
    var  harshDeceAlarmStatus : Bool!
    var  tamperAlarmStatus : Bool!
    var  geoFenceAlarmStatus : Bool!
    var  emailAlarmStatus : Bool!
    var  phoneAlarmStatus : Bool!
    var engineAlarmStatus : Bool!
    var soundAlarmStatus : Bool! = false
    var vibrationAlarmStatus : Bool! = false
    var stopAlarmStatus : Bool!
    var airplaneModeStatus : Bool! = false
    var coolantAlarmStatus : Bool! = false
    var engineIdleAlarmStatus : Bool! = false
    var engineHealthAlarmStatus : Bool! = false
    static func parseJSON(_ json: JSON) -> AlarmModel {
        let item = AlarmModel()
        
        item.speedLimit = json["speedLimit"].stringValue
        item.fatigueTime = json["fatigueTime"].stringValue
        item.harshTurn = json["harshTurn"].stringValue
        item.harshAcceleration = json["harshAcceleration"].stringValue
        item.harshDeceleration = json["harshDeceleration"].stringValue
        item.email = json["email"].stringValue
        item.phoneNumber = json["phoneNumber"].stringValue
        
        item.speedingAlarmStatus = json["speedingAlarmStatus"].boolValue
        item.fatigueAlarmStatus = json["fatigueAlarmStatus"].boolValue
        item.harshTurnAlarmStatus = json["harshTurnAlarmStatus"].boolValue
        item.harshAcceAlarmStatus = json["harshAcceAlarmStatus"].boolValue
        item.harshDeceAlarmStatus = json["harshDeceAlarmStatus"].boolValue
        item.tamperAlarmStatus = json["tamperAlarmStatus"].boolValue
        item.geoFenceAlarmStatus = json["geoFenceAlarmStatus"].boolValue
        item.emailAlarmStatus = json["emailAlarmStatus"].boolValue
        item.phoneAlarmStatus = json["phoneAlarmStatus"].boolValue
        item.engineAlarmStatus = json["accAlarmStatus"].boolValue
        item.stopAlarmStatus = json["stopAlarmStatus"].boolValue
        if json["soundAlarmStatus"] != nil {
            item.soundAlarmStatus = json["soundAlarmStatus"].boolValue
        }
        if json["vibrationAlarmStatus"] != nil {
            item.vibrationAlarmStatus = json["vibrationAlarmStatus"].boolValue
        }
        if json["airplaneMode"] != nil {
            item.airplaneModeStatus = json["airplaneMode"].boolValue
        }
        item.coolantAlarmStatus = json["coolantTempAlarmStatus"].boolValue
        item.engineIdleAlarmStatus = json["engineIdleAlarmStatus"].boolValue
        item.engineHealthAlarmStatus = json["engineAlarmStatus"].boolValue
        return item
    }
}
