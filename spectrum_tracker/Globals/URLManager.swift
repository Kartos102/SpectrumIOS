import Foundation
import Alamofire

class URLManager {
    static var baseUrl = "https://api.spectrumtracking.com/v1/"
    static var imageBaseUrl = "https://app.spectrumtracking.com/"
    
    class var isConnectedToInternet:Bool {
        return NetworkReachabilityManager()!.isReachable
    }
    
    static func authLogin() -> (String, HTTPMethod) {
        return (baseUrl + "auth/login", .post)
    }
    
    static func authLogout() -> (String, HTTPMethod) {
        return (baseUrl + "auth/logout", .post)
    }
    
    static func authLoginGoogle() -> (String, HTTPMethod) {
        return (baseUrl + "auth/socialAppLogin", .post)
    }
    
    static func authResendPasswordReset() -> (String, HTTPMethod) {
        return (baseUrl + "auth/resend-password-reset", .post)
    }
    
    static func authRegister() -> (String, HTTPMethod) {
        return (baseUrl + "auth/register", .post)
    }
    
    static func getUserInfo() -> (String, HTTPMethod) {
        return (baseUrl + "users/getUserFromId", .post)
    }
    
    static func authVerify() -> (String, HTTPMethod) {
        return (baseUrl + "auth/verify", .post)
    }
    
    static func authResetPassword() -> (String, HTTPMethod) {
        return (baseUrl + "auth/reset-password", .post)
    }
    
    static func postFirebaseToken() -> (String, HTTPMethod) {
        return (baseUrl + "users/submitToken", .post)
    }
    
    static func assets() -> (String, HTTPMethod) {
        return (baseUrl + "assets", .get)
    }
    
    static func getAllTrackersWeb() -> (String, HTTPMethod) {
        return (baseUrl + "trackers/getAllTrackersWeb",  .post)
    }
    
    static func postUserLocation() -> (String, HTTPMethod) {
        return (baseUrl + "asset-logs", .post)
    }

    static func updateAsset(_ id: String!) -> (String, HTTPMethod) {
        return (baseUrl + "assets/" + id, .put)
    }
    
    static func addReviewNumber(_ email: String!) -> (String, HTTPMethod) {
        return (baseUrl + "users/updateAppReviewReminder/" + email, .put)
    }
    
    static func modifyTracker() -> (String, HTTPMethod) {
        return (baseUrl + "trackers/modify", .post)
    }
    
    static func registerPhoneTracker() -> (String, HTTPMethod) {
        return (baseUrl + "trackers/registerPhoneTracker", .post)
    }
    
    static func setPhoneTrackerFlag() -> (String, HTTPMethod) {
        return (baseUrl + "users/registerPhoneTracker", .post)
    }
    
    static func createPhoneAsset() -> (String, HTTPMethod) {
        return (baseUrl + "assets/createPhoneAsset", .post)
    }
    
    static func setShareFlag() -> (String, HTTPMethod) {
        return (baseUrl + "users/setShareFlag", .post)
    }
    
    static func getCheckOutPlans() -> (String, HTTPMethod) {
        return (baseUrl + "trackers/getCheckOutPlans", .get)
    }
    
    static func getAllTrackers() -> (String, HTTPMethod) {
        return (baseUrl + "trackers/getTrackersByTrackerIds", .post)
    }
    
    static func getAllTrackersWithShareTrackers() -> (String, HTTPMethod) {
        return (baseUrl + "trackers/getAllTrackers", .post)
    }
    
    static func shareTracker() -> (String, HTTPMethod) {
        return (baseUrl + "trackers/shareTrakcer", .post)
    }
    
    static func unShareTracker() -> (String, HTTPMethod) {
        return (baseUrl + "trackers/unShareTrakcer", .post)
    }
    
    static func getShareUsers() -> (String, HTTPMethod) {
        return (baseUrl + "trackers/getShareUsers", .post)
    }
    
    static func getImageUrl() -> (String, HTTPMethod) {
        return (baseUrl + "trackers/getImageUrl", .post)
    }

    static func tokenizeCreditCard() -> (String, HTTPMethod) {
        return ("https://app.spectrumtracking.com/php/route.php", .post)
    }

    static func doAuth() -> (String, HTTPMethod) {
        return (baseUrl + "auth", .get)
    }
    
    static func updateCreditCardInfoSecondary(_ id: String) -> (String, HTTPMethod) {
        return (baseUrl + "users/" + id, .put)
    }
    
    static func trackerRegister() -> (String, HTTPMethod) {
        return (baseUrl + "trackers/register", .post)
    }
    static func createAssets() -> (String, HTTPMethod) {
        return (baseUrl + "assets", .post)
    }

    static func ordersPayment() -> (String, HTTPMethod) {
        return (baseUrl + "orders/payment", .post)
    }
    
    static func trackers_id(_ id: String!) -> (String, HTTPMethod) {
        return (baseUrl + "trackers/" + id, .get)
    }
    
    static func users_id(_ id: String!) -> (String, HTTPMethod) {
        return (baseUrl + "users/" + id, .get)
    }
    
    static func getTrackerBySpectrumId(_ id: String!) -> (String, HTTPMethod) {
        return (baseUrl + "trackers/getTrackerBySpectrumId/" + id, .get)
    }
    
    static func getTrackerModelBySpectrumId(_ id: String!) -> (String, HTTPMethod) {
        return (baseUrl + "trackers/getTrackerModelBySpectrumId/" + id, .get)
    }
    
    static func assets_logs(_ id: String!) -> (String, HTTPMethod) {
        return (baseUrl + "assets/" + id + "/logs", .get)
    }
    
    static func tripInfo() -> (String , HTTPMethod) {
        return (baseUrl + "asset-logs/tripInfo", .get)
    }
    
    static func trip_log_summary() -> (String , HTTPMethod) {
        return (baseUrl + "triplog/tripLogSummary", .get)
    }
    
    static func trip_logs(_ id: String!) -> (String, HTTPMethod) {
        return (baseUrl + "triplog/" + id + "/logs", .get)
    }
    
    static func event_logs(_ id: String!) -> (String, HTTPMethod) {
        return (baseUrl + "alertlog/" + id + "/logs", .get)
    }
    
    static func generateToken() -> (String, HTTPMethod) {
        return (baseUrl + "orders/generateToken", .post)
    }
    static func addLandmark() -> (String, HTTPMethod) {
        return (baseUrl + "users/landmark", .post)
    }
    
    //added by Robin
    static func setGeofence() -> (String, HTTPMethod) {
        return (baseUrl + "trackers/setGeoFence" , .post)
    }
    
    //added by Robin
    static func alarm(_ id: String!) -> (String, HTTPMethod) {
        return (baseUrl + "trackers/byAssetName/" + id, .get)
    }
    
    //added by Robin
    static func modify() -> (String, HTTPMethod) {
        return (baseUrl + "trackers/modify" , .post)
    }
    
    static func inviteJoinChat() -> (String, HTTPMethod) {
        return (baseUrl + "api-inerface/inviteJoinChat", .post)
    }
    
    static func testUrl() -> (String, HTTPMethod) {
        return ("http://192.168.0.104/test.php", .get)
    }
    
}
