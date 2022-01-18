import Foundation
import UIKit
import Alamofire
import SwiftyJSON
import CoreLocation
import SwiftyUserDefaults

class Global {
    static var shared: Global! = Global()
    
    init() {
        self.csrfToken = ""
        self.username = "---"
        self.alertArray = [String:String]()
        self.metricScale = 1.0
        self.volumeMetricScale = 1.0
    }
    
    var csrfToken: String!
    var alertArray: [String:String]!
    var allAddress = [String:String]()
    var selectedTrackerIds = [String]()
    var userLocation: CLLocationCoordinate2D!
    var sharedTrackerList = [TrackerModel]()
    var landmarkList = [LandmarkModel]()
    var AllTrackerList = [TrackerModel]()
    var driverPhotos: [String: String] = [:]
    var username: String!
    var app_user: JSON!
    var metricScale: Double!
    var volumeMetricScale: Double!
    static var AFManager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10 // seconds
        configuration.timeoutIntervalForResource = 10 //seconds
        return Alamofire.SessionManager(configuration: configuration)
    }()
    
    static func annotationFillColor(color: String) -> UIColor {
        switch color {
        case "RED":
            return .red
        case "ORGANGE":
            return UIColor(red: 255, green: 165, blue: 0)
        case "WHITE":
            return .white
        case "GREY":
            return UIColor(red: 192, green: 192, blue: 192)
        case "BLACK":
            return UIColor(red: 20, green: 20, blue: 20)
        case "SILVER":
            return UIColor(red: 192, green: 192, blue: 192)
        case "BLUE":
            return UIColor(red: 43, green: 56, blue: 86)
        case "GREEN":
            return UIColor(red: 37, green: 65, blue: 23)
        default:
            return UIColor(red: 253, green: 208, blue: 23)
        }
    }
    
    static func annotationBorderColor(color: String) -> UIColor {
        switch color {
        case "RED":
            return .blue
        case "ORGANGE":
            return .red
        case "WHITE":
            return .red
        case "GREY":
            return .blue
        case "BLACK":
            return .red
        case "SILVER":
            return UIColor(red: 255, green: 165, blue: 0)
        case "BLUE":
            return UIColor(red: 255, green: 165, blue: 0)
        case "GREEN":
            return .red
        default:
            return .black
        }
    }
    
    static func isUSAsset(tracker: TrackerModel?) -> Bool {
        if tracker?.country == "United States" || tracker?.country == "US" {
            return true
        }
        return false
    }
    
    static func getDistanceUnit() -> String {
        let distanceUnit = Defaults[.distanceUnit] ?? "miles"
        if distanceUnit == "" {
            return "miles"
        }
        return distanceUnit
    }
}


struct Regex_strings {
    static let mobile = "^[0-9]{11}$"
    static let password = "^.{8,18}$"
    static let age = "^(0?[1-9]|[1-9][0-9])$"
    static let specialChars = "[$&+,:;=\\?@#|/'<>.^*()%!-]"
    static let email = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
}


var countryList = ["United States", "Afghanistan", "Åland Islands", "Albania", "Algeria", "American Samoa", "Andorra", "Angola", "Anguilla",
"Antarctica", "Antigua and Barbuda", "Argentina", "Armenia", "Aruba", "Australia", "Austria", "Azerbaijan", "Bahamas", "Bahrain", "Bangladesh",
"Barbados", "Belarus", "Belgium", "Belize", "Benin", "Bermuda", "Bhutan", "Bolivia", "Bosnia and Herzegovina", "Botswana", "Bouvet Island", "Brazil",
"British Indian Ocean Territory", "Brunei Darussalam", "Bulgaria", "Burkina Faso", "Burundi", "Cambodia", "Cameroon", "Canada", "Cape Verde", "Cayman Islands",
"Central African Republic", "Chad", "Chile", "China", "Christmas Island", "Cocos (Keeling) Islands", "Colombia", "Comoros", "Congo",
"Congo, The Democratic Republic of The", "Cook Islands", "Costa Rica", "Cote D'ivoire", "Croatia", "Cuba", "Cyprus", "Czech Republic", "Denmark", "Djibouti",
"Dominica", "Dominican Republic", "Ecuador", "Egypt", "El Salvador", "Equatorial Guinea", "Eritrea", "Estonia", "Ethiopia", "Falkland Islands (Malvinas)",
"Faroe Islands", "Fiji", "Finland", "France", "French Guiana", "French Polynesia", "French Southern Territories", "Gabon", "Gambia", "Georgia", "Germany",
"Ghana", "Gibraltar", "Greece", "Greenland", "Grenada", "Guadeloupe", "Guam", "Guatemala", "Guernsey", "Guinea", "Guinea-bissau", "Guyana", "Haiti",
"Heard Island and Mcdonald Islands", "Holy See (Vatican City State)", "Honduras", "Hong Kong", "Hungary", "Iceland", "India", "Indonesia", "Iran, Islamic Republic of",
"Iraq", "Ireland", "Isle of Man", "Israel", "Italy", "Jamaica", "Japan", "Jersey", "Jordan", "Kazakhstan", "Kenya", "Kiribati",
"Korea, Democratic People's Republic of", "Korea, Republic of", "Kuwait", "Kyrgyzstan", "Lao People's Democratic Republic", "Latvia", "Lebanon", "Lesotho",
"Liberia", "Libyan Arab Jamahiriya", "Liechtenstein", "Lithuania", "Luxembourg", "Macao", "Macedonia, The Former Yugoslav Republic of", "Madagascar",
"Malawi", "Malaysia", "Maldives", "Mali", "Malta", "Marshall Islands", "Martinique", "Mauritania", "Mauritius", "Mayotte", "Mexico",
"Micronesia, Federated States of", "Moldova, Republic of", "Monaco", "Mongolia", "Montenegro", "Montserrat", "Morocco", "Mozambique", "Myanmar", "Namibia",
"Nauru", "Nepal", "Netherlands", "Netherlands Antilles", "New Caledonia", "New Zealand", "Nicaragua", "Niger", "Nigeria", "Niue", "Norfolk Island",
"Northern Mariana Islands", "Norway", "Oman", "Pakistan", "Palau", "Palestinian Territory, Occupied", "Panama", "Papua New Guinea", "Paraguay", "Peru",
"Philippines", "Pitcairn", "Poland", "Portugal", "Puerto Rico", "Qatar", "Reunion", "Romania", "Russian Federation", "Rwanda", "Saint Helena",
"Saint Kitts and Nevis", "Saint Lucia", "Saint Pierre and Miquelon", "Saint Vincent and The Grenadines", "Samoa", "San Marino", "Sao Tome and Principe",
"Saudi Arabia", "Senegal", "Serbia", "Seychelles", "Sierra Leone", "Singapore", "Slovakia", "Slovenia", "Solomon Islands", "Somalia", "South Africa",
"South Georgia and The South Sandwich Islands", "Spain", "Sri Lanka", "Sudan", "Suriname", "Svalbard and Jan Mayen", "Swaziland", "Sweden", "Switzerland",
"Syrian Arab Republic", "Taiwan, Province of China", "Tajikistan", "Tanzania, United Republic of", "Thailand", "Timor-leste", "Togo", "Tokelau", "Tonga",
"Trinidad and Tobago", "Tunisia", "Turkey", "Turkmenistan", "Turks and Caicos Islands", "Tuvalu", "Uganda", "Ukraine", "United Arab Emirates", "United Kingdom",
"United States Minor Outlying Islands", "Uruguay", "Uzbekistan", "Vanuatu", "Venezuela", "Viet Nam", "Virgin Islands, British", "Virgin Islands, U.S.",
"Wallis and Futuna", "Western Sahara", "Yemen", "Zambia", "Zimbabwe"]
