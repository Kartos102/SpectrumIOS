import Foundation
import SwiftyJSON

class Geofence {

    var id: String = ""
    var name: String = ""
    var type: String = ""
    var lat: Double? = nil
    var lng: Double? = nil
    var radius: Double? = nil
    var boundary: [CLLocationCoordinate2D] = []
    var note: String = ""
    
    var dictionary: [String: Any] {
        let points = boundary.map({ [$0.longitude, $0.latitude] })
        return [
            "id": id,
            "name": name,
            "type": type,
            "lat": lat ?? 0.0,
            "lng": lng ?? 0.0,
            "radius": radius ?? 0.0,
            "boundary": points,
            "note": note
        ]
    }
    
    static func parseJSON(_ json: JSON) -> Geofence {
        let item = Geofence()
        
        item.id = json["id"].stringValue
        item.name = json["name"].stringValue
        item.lat = json["lat"].double
        item.lng = json["lng"].double
        item.radius = json["radius"].double
        item.note = json["note"].stringValue
        item.type = json["type"].stringValue
        
        item.boundary = []
        
        for coordinate in json["boundary"].arrayValue {
            let latLng = coordinate.arrayValue
            let lat = latLng[1].doubleValue
            let lng = latLng[0].doubleValue
            
            let _coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            item.boundary.append(_coordinate)
        }

        return item
    }
    
}
