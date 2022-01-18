import Foundation
import SwiftyJSON

class ErrorModel {
    var name: String!
    var message: String!
    var httpStatus: Int!
    
    
    static func parseJSON(_ json: JSON) -> ErrorModel {
        let item = ErrorModel()
        
        item.name = json["name"].stringValue
        item.message = json["message"].stringValue
        item.httpStatus = json["httpStatus"].intValue
        
        return item
    }
    
}
