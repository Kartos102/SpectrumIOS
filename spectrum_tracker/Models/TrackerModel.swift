import Foundation
import SwiftyJSON

class TrackerModel {

    var _id = ""
    var spectrumId = ""
    var reportingId = ""
    var SIMCardNum = ""
    var hotspot = 0
    var lastLogDateTime: Date? = nil
    var lat: Double = 0.0
    var lng: Double = 0.0
    var lat1: Double = 0.0
    var lng1: Double = 0.0
    var lat2: Double = 0.0
    var lng2: Double = 0.0
    var latLngDateTime: Date? = nil
    var expirationDate: Date? = nil
    var dataPlan: String = ""
    var LTEData: String = ""
    var speedInMph: Double = 0.0
    var commandQueue: [String] = []
    var harshAcce: Int = 0
    var harshDece: Int = 0
    var daySpeeding: Int = 0
    var lastACCOntime: Date? = nil
    var lastACCOfftime: Date? = nil
    var voltage: Double = 0.0
    var tankVolume: Double = 0.0
    var battery: Double = 0.0
    var lastACCOnLat: Double = 0.0
    var lastACCOnLng: Double = 0.0
    var lastACCOffLat: Double = 0.0
    var lastACCOffLng: Double = 0.0
    var accStatus: Int = 0
    var trackerModel: String = ""
    var country: String = ""
    var weekMile: Float = 0.0
    var dayMile: Float = 0.0
    var monthMile: Float = 0.0
    var yearMile: Float = 0.0
    var geofence: [Geofence] = []
    
    var name: String = ""
    var lastAlert: String = ""
    var color: String = ""
    var autoRenew: Bool = false
    var userId: String = ""
    var plateNumber: String = ""
    var driverName: String = ""
    var driverPhoneNumber: String = ""
    var assetId: String = ""
    var heading: Double = 0.0
    var coolanttemp: Double = 0.0
    var photoStatus: Bool = false
    
    var lastStartAddress: String = ""
    var lastStopAddress: String = ""
    
    var dataLimit: Float = 0.0
    var dataVolumeCustomerCycle: Float = 0.0
    var rpm: Float = 0.0
    var yearFuel: Double = 0.0
    var maxSpeed: Double = 0.0
    var isSelected = false
    var oilChangeMileage: Double = 0.0

    static func parseJSON(_ json: JSON) -> TrackerModel {
        let item = TrackerModel()
        
        item._id = json["_id"].stringValue
        item.yearFuel = json["yearFuel"].doubleValue
        item.oilChangeMileage = json["oilChangeMileage"].doubleValue
        item.maxSpeed = json["maxSpeed"].doubleValue
        item.spectrumId = json["spectrumId"].stringValue
        item.reportingId = json["reportingId"].stringValue
        item.SIMCardNum = json["SIMCardNum"].stringValue
        item.hotspot = json["hotspot"].intValue
        item.lastLogDateTime = json["lastLogDateTime"].stringValue.toDate("yyyy-MM-dd'T'HH:mm:ss.SSSZ")
        item.lat = json["lat"].doubleValue
        item.lng = json["lng"].doubleValue
        item.lng1 = json["lng1"].doubleValue
        item.lng2 = json["lng2"].doubleValue
        item.lat1 = json["lat1"].doubleValue
        item.lat2 = json["lat2"].doubleValue
        item.latLngDateTime = json["latLngDateTime"].stringValue.toDate("yyyy-MM-dd'T'HH:mm:ss.SSSZ")
        item.expirationDate = json["expirationDate"].stringValue.toDate("yyyy-MM-dd'T'HH:mm:ss.SSSZ")
        item.dataPlan = json["dataPlan"].stringValue
        item.LTEData = json["LTEData"].stringValue
        item.speedInMph = json["speedInMph"].doubleValue
        item.commandQueue = json["commandQueue"].arrayValue.map({ $0.stringValue })
        item.harshAcce = json["harshAcce"].intValue
        item.harshDece = json["harshDece"].intValue
        item.daySpeeding = json["daySpeeding"].intValue
        item.lastACCOntime = json["lastACCOnTime"].stringValue.toDate("yyyy-MM-dd'T'HH:mm:ss.SSSZ")
        item.lastACCOfftime = json["lastACCOffTime"].stringValue.toDate("yyyy-MM-dd'T'HH:mm:ss.SSSZ")
        item.voltage = json["voltage"].doubleValue
        item.coolanttemp = json["coolantTemp"].doubleValue
        item.battery = json["battery"].doubleValue
        item.tankVolume = json["tankVolume"].doubleValue
        item.lastACCOnLat = json["lastACCOnLat"].doubleValue
        item.lastACCOnLng = json["lastACCOnLng"].doubleValue
        item.lastACCOffLat = json["lastACCOffLat"].doubleValue
        item.lastACCOffLng = json["lastACCOffLng"].doubleValue
        item.accStatus = json["ACCStatus"].intValue
        item.trackerModel = json["TrackerModel"].stringValue
        item.country = json["country"].stringValue
        item.weekMile = json["weekMile"].floatValue
        item.dayMile = json["dayMile"].floatValue
        item.monthMile = json["monthMile"].floatValue
        item.yearMile = json["yearMile"].floatValue
        item.name = json["name"].stringValue
        item.lastAlert = json["lastAlert"].stringValue
        item.color = json["color"].stringValue
        item.autoRenew = json["autoRenew"].boolValue
        item.userId = json["userId"].stringValue
        item.plateNumber = json["plateNumber"].stringValue
        item.driverName = json["driverName"].stringValue
        item.driverPhoneNumber = json["driverPhoneNumber"].stringValue
        item.assetId = json["assetId"].stringValue
        item.heading = json["heading"].doubleValue
        item.photoStatus = json["photoStatus"].boolValue
        
        for geofence in json["geofence"].arrayValue {
            item.geofence.append(Geofence.parseJSON(geofence))
        }
        
        item.dataLimit = json["dataLimit"].floatValue
        item.dataVolumeCustomerCycle = json["dataVolumeCustomerCycle"].floatValue
        item.rpm = json["RPM"].floatValue

        return item
    }
    
}
