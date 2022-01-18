import Foundation
import SwiftyJSON

class AssetModel: Hashable{
    
    var hashValue: Int {
        var val: Int = _id.hashValue
        val = val ^ name.hashValue
        val = val ^ trackerId.hashValue
        val = val ^ driverName.hashValue
        val = val ^ driverPhoneNumber.hashValue
        return val
    }
    
    static func == (lhs: AssetModel, rhs: AssetModel) -> Bool {
        if lhs._id != rhs._id {
            return false
        }
        if lhs.name != rhs.name {
            return false
        }
        if lhs._id != rhs._id {
            return false
        }
        if lhs.userId != rhs.userId {
            return false
        }
        if lhs.driverName != rhs.driverName {
            return false
        }
        if lhs.driverPhoneNumber != rhs.driverPhoneNumber {
            return false
        }

        return true
    }
    
    var _id: String!
    var name: String!
    var assetId: String!
    var plateNumber: String!
    var trackerId: String!
    var userId: String!
    var spectrumId: String!
    var driverName: String!
    var driverPhoneNumber: String!
    var accStatus: Int!
    var speedInMph: Double!
    var latLngDateTime: Date!
    var isSelected: Bool!
    var lat: Double!
    var color: String!
    var lng: Double!
    var country: String!
    var photoStatus: Bool!
    var changeFlag: Bool!
    var trackerModel: String!
    
    static func parseJSON(_ json: JSON) -> AssetModel {
        let item = AssetModel()
        
        item._id = json["_id"].stringValue
        item.name = json["name"].stringValue
        item.assetId = json["assetId"].stringValue
        item.plateNumber = json["plateNumber"].stringValue
        item.trackerId = json["trackerId"].stringValue
        item.userId = json["userId"].stringValue
        item.spectrumId = json["spectrumId"].stringValue
        item.driverName = json["driverName"].stringValue
        item.driverPhoneNumber = json["driverPhoneNumber"].stringValue
        item.color = json["color"].stringValue
        item.isSelected = false
        item.trackerModel = json["TrackerModel"].stringValue
        
        return item
    }
}
