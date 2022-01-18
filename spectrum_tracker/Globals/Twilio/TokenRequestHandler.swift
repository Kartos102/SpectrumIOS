import UIKit

class TokenRequestHandler {
    
    class func postDataFrom(params:[String:String]) -> String {
        var data = ""
        
        for (key, value) in params {
            if let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                if !data.isEmpty {
                    data = data + "&"
                }
                data += encodedKey + "=" + encodedValue;
            }
        }
        
        return data
    }
    
    class func fetchToken(params:[String:String], completion:@escaping ([String: Any], Error?) -> Void) {
        var urlString = "https://camel-mink-6453.twil.io/chat-token"
        let params = postDataFrom(params: params)
        urlString += "?\(params)"
        
        if let requestURL = URL(string: urlString) {
            let session = URLSession(configuration: URLSessionConfiguration.default)
            let task = session.dataTask(with: requestURL, completionHandler: { (data, _, error) in
                if let data = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: [])
                        if let tokenData = json as? [String: String] {
                            completion(tokenData, error)
                        } else {
                            completion([:], nil)
                        }
                    } catch let error as NSError {
                        completion([:], error)
                    }
                } else {
                    completion([:], error)
                }
            })
            task.resume()
        }
    }
}
