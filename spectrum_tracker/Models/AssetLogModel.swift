import Foundation
import SwiftyJSON

class AssetLogModel {
    var lat: Double = 0.0
    var lng: Double = 0.0
    var dateTime: Date = Date()
    var speedInMph: Double = 0.0
    var trackerModel: String = ""
    var reportType: String = ""
    var reportingId: String = ""
    var ACCStatus: Int = 0
    var stepDis: Double = 0.0
    var lastAlert: String = ""
    
    var cctr: cctrType? = nil
    var huaheng: huahengType? = nil
    var sinocastel: sinocastelType? = nil
    var mictrack: mictrackType? = nil

    class huahengType {
        var coolantTemp: Double!
        var aveSpeed: Double!
        var tripID: String!
        var voltage: Double!
        var alarmNumberAdd1: Int!
        var fuelConsump: Double!
        var mileageM: Double!
        var fuelEfficiency: Double!
        var RPM: Int!
        
        static func parseJSON(_ json: JSON) -> huahengType {
            let item = huahengType()
            
            item.coolantTemp = json["coolantTemp"].doubleValue
            item.aveSpeed = json["aveSpeed"].doubleValue
            item.tripID = json["tripID"].stringValue
            item.voltage = json["voltage"].doubleValue
            item.alarmNumberAdd1 = json["alarmNumberAdd1"].intValue
            item.fuelConsump = json["fuelConsump"].doubleValue
            item.mileageM = json["mileageM"].doubleValue
            item.fuelEfficiency = json["fuelEfficiency"].doubleValue
            item.RPM = json["RPM"].intValue

            return item
        }
    }
    
    class sinocastelType {
        var totalFuelConsum: Double!
        var totalMileage: Double!
        var currentTripConsum: Double!
        var currentTripMileage: Double!
        var vehicleStatus: vehicleStatusType!
        var ACCOnTime: Date!
        
        static func parseJSON(_ json: JSON) -> sinocastelType {
            let item = sinocastelType()
            
            item.totalFuelConsum = json["totalFuelConsum"].doubleValue
            item.totalMileage = json["totalMileage"].doubleValue
            item.currentTripConsum = json["currentTripConsum"].doubleValue
            item.currentTripMileage = json["currentTripMileage"].doubleValue
            item.ACCOnTime = json["ACCOnTime"].stringValue.toDate("yyyy-MM-dd'T'HH:mm:ss.SSSZ") ?? Date()
            
            if(json["vehicleStatus"].exists()) {
                item.vehicleStatus = vehicleStatusType.parseJSON(json["vehicleStatus"])
            }
            
            return item
        }
        
    }
    
    class mictrackType {
        var vehicleStatus: vehicleStatusType!
        
        static func parseJSON(_ json: JSON) -> mictrackType {
            let item = mictrackType()
            
            if(json["vehicleStatus"].exists()) {
                item.vehicleStatus = vehicleStatusType.parseJSON(json["vehicleStatus"])
            }
            
            return item
        }
        
    }
    
    class cctrType {
        var vehicleStatus: vehicleStatusType!
        
        static func parseJSON(_ json: JSON) -> cctrType {
            let item = cctrType()
            
            if(json["vehicleStatus"].exists()) {
                item.vehicleStatus = vehicleStatusType.parseJSON(json["vehicleStatus"])
            }
            
            return item
        }
        
    }
    
    class vehicleStatusType {
        var vibration: Int! = 0
        var dangerousDriving: Int! = 0
        var noCard: Int! = 0
        var unlock: Int! = 0
        var MIL: Int! = 0
        var OBDError: Int! = 0
        var powerOff: Int! = 0
        var noGPSDevice: Int! = 0
        var privacyStatus: Int! = 0
        var ignitionOn: Int! = 0
        var illegalIgnition: Int! = 0
        var illegalEnter: Int! = 0
        var tamper: Int! = 0
        var crash: Int! = 0
        var emergency: Int! = 0
        var fatigueDriving: Int! = 0
        var sharpTurn: Int! = 0
        var quickLaneChange: Int! = 0
        var powerOn: Int! = 0
        var highRPM: Int! = 0
        var exhauseEmission: Int! = 0
        var idleEngine: Int! = -1
        var hardDece: Int! = -1
        var hardAcce: Int! = -1
        var coolantTemp: Int! = 0
        var speeding: Int! = -1
        var towing: Int! = 0
        var lowVoltag: Int! = 0
        var ACCOff: Int! = 0
        var lowVoltage: Int! = 0
        var unPlug: Int! = 0
        var overSpeed2: Int! = -1
        var batteryLowAlarm: Int! = 0
        var ignitionOff: Int! = 0
        
        static func parseJSON(_ json: JSON) -> vehicleStatusType {
            let item = vehicleStatusType()
            
            item.vibration = json["vibration"].intValue
            item.dangerousDriving = json["dangerousDriving"].intValue
            item.noCard = json["noCard"].intValue
            item.unlock = json["unlock"].intValue
            item.MIL = json["MIL"].intValue
            item.OBDError = json["OBDError"].intValue
            item.powerOff = json["powerOff"].intValue
            item.noGPSDevice = json["noGPSDevice"].intValue
            item.privacyStatus = json["privacyStatus"].intValue
            item.ignitionOn = json["ignitionOn"].intValue
            item.illegalIgnition = json["illegalIgnition"].intValue
            item.illegalEnter = json["illegalEnter"].intValue
            item.tamper = json["tamper"].intValue
            item.crash = json["crash"].intValue
            item.emergency = json["emergency"].intValue
            item.fatigueDriving = json["fatigueDriving"].intValue
            item.sharpTurn = json["sharpTurn"].intValue
            item.quickLaneChange = json["quickLaneChange"].intValue
            item.powerOn = json["powerOn"].intValue
            item.highRPM = json["highRPM"].intValue
            item.exhauseEmission = json["exhauseEmission"].intValue
           
            if(json["idleEngine"].exists()) {
                 item.idleEngine = json["idleEngine"].intValue
            }
            if(json["hardDece"].exists()) {
                item.hardDece = json["hardDece"].intValue
            }
            if(json["hardAcce"].exists()) {
                item.hardAcce = json["hardAcce"].intValue
            }
            if(json["speeding"].exists()) {
                 item.speeding = json["speeding"].intValue
            }
           
            
            item.coolantTemp = json["coolantTemp"].intValue
           
            item.towing = json["towing"].intValue
            item.lowVoltag = json["lowVoltag"].intValue
            item.ACCOff = json["ACCOff"].intValue
            item.lowVoltage = json["lowVoltage"].intValue
            item.unPlug = json["unPlug"].intValue
            
            if(json["overSpeed2"].exists()) {
                item.overSpeed2 = json["overSpeed2"].intValue
            }
            item.batteryLowAlarm = json["batteryLowAlarm"].intValue
            item.ignitionOff = json["ignitionOff"].intValue
            
            return item
        }
        
    }
    
    static func parseJSON(_ json: JSON) -> AssetLogModel {
        let item = AssetLogModel()
        
        item.lat = json["lat"].doubleValue
        item.lng = json["lng"].doubleValue
        item.dateTime = json["dateTime"].stringValue.toDate("yyyy-MM-dd'T'HH:mm:ss.SSSZ") ?? Date()
       // print(item.dateTime.toString("yyyy/MM/dd HH:mm a"))
        item.speedInMph = json["speedInMph"].doubleValue
        item.trackerModel = json["trackerModel"].stringValue
        item.reportType = json["reportType"].stringValue
        item.ACCStatus = json["ACCStatus"].intValue
        item.reportingId = json["reportingId"].stringValue
        item.stepDis = json["stepDis"].doubleValue
        item.lastAlert = json["lastAlert"].stringValue

        if json["huaheng"].exists() {
            item.huaheng = huahengType.parseJSON(json["huaheng"])
        }
        
        if json["sinocastel"].exists() {
            item.sinocastel = sinocastelType.parseJSON(json["sinocastel"])
        }

        if json["mictrack"].exists() {
            item.mictrack = mictrackType.parseJSON(json["mictrack"])
        }

        if json["cctr"].exists() {
            item.cctr = cctrType.parseJSON(json["cctr"])
        }

        return item
    }
}
