import Foundation
import SwiftyJSON

class TripLogModel {
    var dateTime: Date!
    var fatigueDriving: Int!
    var fuel: Double!
    var harshAcce: Int!
    var harshDece: Int!
    var idle: Int!
    var maxSpeed: Double!
    var mileage: Double!
    var speeding: Int!
    var stops: Int!
    
    static func parseJSON(_ json: JSON) -> TripLogModel {
        let item = TripLogModel()
        item.dateTime = json["dateTime"].stringValue.toDate("yyyy-MM-dd'T'HH:mm:ss.SSSZ")
        item.fatigueDriving = json["fatigueDriving"].intValue
        item.fuel = json["fuel"].doubleValue
        item.harshAcce = json["harshAcce"].intValue
        item.harshDece = json["harshDece"].intValue
        item.idle = json["idle"].intValue
        item.maxSpeed = json["maxSpeed"].doubleValue
        item.mileage = json["mileage"].doubleValue
        item.speeding = json["speeding"].intValue
        item.stops = json["stops"].intValue
        
        return item
    }
    
}
