//
//  Extensions.swift
//  spectrum_tracker
//
//  Created by JO on 2018/5/7.
//  Copyright © 2018 JO. All rights reserved.
//

import Foundation
import UIKit
import SwiftyUserDefaults


extension UIViewController: NVActivityIndicatorViewable{
    func showLoader(_ isForceShow: Bool = false) {
//        if isForceShow {
//            startAnimating(CGSize(width: 30, height: 30), message: "Please wait", type: .ballRotateChase)
//        }
    }
    
    func hideLoader() {
//        stopAnimating()
    }
}

extension DefaultsKeys {
    static let username = DefaultsKey<String?>("username")
    static let password = DefaultsKey<String?>("password")
    static let isLoggedIn = DefaultsKey<Bool?>("isLoggedIn")
    static let alertSound = DefaultsKey<Bool?>("alertSound")
    static let vibration = DefaultsKey<Bool?>("vibration")
    static let remember = DefaultsKey<Bool?>("remember")
    static let sautolock = DefaultsKey<Bool?>("sautolock")
    static let phoneTracking = DefaultsKey<Bool?>("phoneTracking")
    static let uploadDelay = DefaultsKey<Int?>("uploadDelay")
    static let launchCount = DefaultsKey<Int?>("LaunchCount")
    static let distanceUnit = DefaultsKey<String?>("distanceUnit")
    static let fcmToken = DefaultsKey<String?>("fcmToken")
}


extension UIViewController {
    @IBAction func onBtnHamburger() {
        self.slideMenuController()?.openLeft()
    }
}



extension Int {
    func toString() -> String {
        return String(self)
    }
}

extension Double {
    func toString() -> String {
        return String(self)
    }
    func priceString() -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 2
        return nf.string(for: self) ?? ""
    }
}

extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
    /*
     let text = "hello world"
     text.substring(from: 0, to: 5) // returns "hello"
     */
    func substring(from fromValue: Int, to toValue: Int) -> String {
        
        var f = fromValue < toValue ? fromValue : toValue
        var t = toValue > fromValue ? toValue : fromValue
        
        if ( f < 0 ) {
            f = 0
        }
        if ( t > self.count ) {
            t = self.count
        }
        
        let range = self.index(self.startIndex, offsetBy: f) ..< self.index(self.startIndex, offsetBy: t)
        return String(self[range])
    }
    
    /*
     regex check
     */
    
    func matchRegex(_ regex: String!) -> Bool! {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
    
    
    /* string to html data */
    
    func htmlAttributedString() -> NSAttributedString? {
        guard let data = self.data(using: String.Encoding.utf16, allowLossyConversion: false) else { return nil }
        guard let html = try? NSMutableAttributedString(
            data: data,
            options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil) else { return nil }
        return html
    }
    
    /* string to date */
    
    func toDate(_ dateFormat:String = "yyyy-MM-dd") -> Date? {
        /*
         yyyy-MM-dd
         yyyy-MM-dd'T'HH:mm:ssZ
         
         yyyy-MM-dd'T'HH:mm:ss.SSSZ
         
         */
        
        // current string is date based on current locale
        // we have to return utc date represents current string with current locale
        
        let curDate = Date()
        let utcDateFormatter = DateFormatter()
        utcDateFormatter.dateFormat = "yyyy-MM-dd_HH:mm:ss"
        utcDateFormatter.timeZone = TimeZone(identifier: "GMT")
        
        
        let utcDate = utcDateFormatter.date(from: curDate.toString("yyyy-MM-dd_HH:mm:ss"))!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        utcDateFormatter.timeZone = TimeZone.current
        
        let date = dateFormatter.date(from: self)
        if date == nil {
            return nil
        }
        
        //return date! - (utcDate.timeIntervalSince(curDate))
        return date
    }
    
}



extension Date {
    
    // set time of date
    func setTime(Hour hour: Int = 0, Minute minute: Int = 0, Second second: Int = 0) -> Date {
        let gregorian = Calendar(identifier: .gregorian)
        
        var components = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        
        components.hour = hour
        components.minute = minute
        components.second = second
        
        let updatedDate = gregorian.date(from: components)!
        return updatedDate
    }
    
    // returns month of date
    
    func year() -> Int {
        let calendar = Calendar.current
        return calendar.component(.year, from: self)
    }
    
    func month() -> Int {
        let calendar = Calendar.current
        return calendar.component(.month, from: self)
    }
    
    func day() -> Int {
        let calendar = Calendar.current
        return calendar.component(.day, from: self)
    }
    
    func weekDay() -> Int {
        let calendar = Calendar.current
        return calendar.component(.weekday, from: self)
    }
    
    func hour() -> Int {
        let calendar = Calendar.current
        return calendar.component(.hour, from: self)
    }
    
    func minute() -> Int {
        let calendar = Calendar.current
        return calendar.component(.minute, from: self)
    }
    
    func second() -> Int {
        let calendar = Calendar.current
        return calendar.component(.second, from: self)
    }
    
    func date(plusMonth month:Int ) -> Date{
        let calendar = Calendar.current
        
        var dateComponents = DateComponents()
        dateComponents.month = month
        let destDate = calendar.date(byAdding: dateComponents, to: self)!
        return destDate
    }
    
    func date(plusYear year:Int ) -> Date{
        let calendar = Calendar.current
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        let destDate = calendar.date(byAdding: dateComponents, to: self)!
        return destDate
    }

    
    func date(plusDay day:Int ) -> Date{
        let calendar = Calendar.current
        
        var dateComponents = DateComponents()
        dateComponents.day = day
        let destDate = calendar.date(byAdding: dateComponents, to: self)!
        return destDate
    }
    
    func toString(_ format: String = "yyyy年MM月dd日") -> String {
        /*
         yyyy.MM.dd
         yyyy年MM月dd日
         yyyy年MM月dd日HH:mm
         yyyy-MM-dd HH:mm:ss
         yyyy/MM/dd
         */
        
        let dateFormatter1 = DateFormatter()
        dateFormatter1.dateFormat = format
        dateFormatter1.timeZone = TimeZone(abbreviation: "UTC")
        
        //let dt = self

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: self)
    }
    
    
    /// Returns the amount of years from another date
    func years(from date: Date) -> Int {
        return Calendar.current.dateComponents([.year], from: date, to: self).year ?? 0
    }
    /// Returns the amount of months from another date
    func months(from date: Date) -> Int {
        return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
    }
    /// Returns the amount of weeks from another date
    func weeks(from date: Date) -> Int {
        return Calendar.current.dateComponents([.weekOfMonth], from: date, to: self).weekOfMonth ?? 0
    }
    /// Returns the amount of days from another date
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    /// Returns the amount of hours from another date
    func hours(from date: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour ?? 0
    }
    /// Returns the amount of minutes from another date
    func minutes(from date: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
    }
    /// Returns the a custom time interval description from another date
    func offset(from date: Date) -> String {
        if years(from: date)   > 0 { return "\(years(from: date))y"   }
        if months(from: date)  > 0 { return "\(months(from: date))M"  }
        if weeks(from: date)   > 0 { return "\(weeks(from: date))w"   }
        if days(from: date)    > 0 { return "\(days(from: date))d"    }
        if hours(from: date)   > 0 { return "\(hours(from: date))h"   }
        if minutes(from: date) > 0 { return "\(minutes(from: date))m" }
        if seconds(from: date) > 0 { return "\(seconds(from: date))s" }
        return ""
    }
}
extension UIImageView {
    func load(_ url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data : data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}
extension UIView {
    func applyGradient(colours: [UIColor]) -> Void {
        self.applyGradient(colours: colours, locations: nil)
    }
    
    func applyGradient(colours: [UIColor], locations: [NSNumber]?) -> Void {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colours.map { $0.cgColor }
        gradient.locations = locations
        self.layer.insertSublayer(gradient, at: 0)
    }
}
extension UIImage {
    func image(withRotation radians: CGFloat) -> UIImage {
        let cgImage = self.cgImage!
        let LARGEST_SIZE = CGFloat(max(self.size.width, self.size.height))
        let context = CGContext.init(data: nil, width:Int(LARGEST_SIZE), height:Int(LARGEST_SIZE), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: cgImage.colorSpace!, bitmapInfo: cgImage.bitmapInfo.rawValue)!
        
        var drawRect = CGRect.zero
        drawRect.size = self.size
        let drawOrigin = CGPoint(x: (LARGEST_SIZE - self.size.width) * 0.5,y: (LARGEST_SIZE - self.size.height) * 0.5)
        drawRect.origin = drawOrigin
        var tf = CGAffineTransform.identity
        tf = tf.translatedBy(x: LARGEST_SIZE * 0.5, y: LARGEST_SIZE * 0.5)
        tf = tf.rotated(by: CGFloat(radians))
        tf = tf.translatedBy(x: LARGEST_SIZE * -0.5, y: LARGEST_SIZE * -0.5)
        context.concatenate(tf)
        context.draw(cgImage, in: drawRect)
        var rotatedImage = context.makeImage()!
        
        drawRect = drawRect.applying(tf)
        
        rotatedImage = rotatedImage.cropping(to: drawRect)!
        let resultImage = UIImage(cgImage: rotatedImage)
        return resultImage
        
        
    }
}



