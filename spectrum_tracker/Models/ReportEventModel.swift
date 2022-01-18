import Foundation
import SwiftyJSON

class ReportEventModel {
    var dateTime: String!
    var alarm: String!
    var address: String!
    
    static func parseJSON(_ json: JSON) -> ReportEventModel {
        let item = ReportEventModel()
        item.dateTime = json["localDateTime"].stringValue
        item.alarm = json["alarm"].stringValue
        item.address = json["address"].stringValue
        return item
    }
    
}
