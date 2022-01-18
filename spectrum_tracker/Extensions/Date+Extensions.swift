//
//  Date+Extensions.swift
//  spectrum_tracker
//
//  Created by Alex Chang on 2020/10/22.
//  Copyright © 2020 JO. All rights reserved.
//

import Foundation

// Weekday constants
let kWeekdaySunday = 1
let kWeekdayMonday = 2
let kWeekdayTuesday = 3
let kWeekdayWednesday = 4
let kWeekdayThursday = 5
let kWeekdayFriday = 6
let kWeekdaySaturday = 7

extension Date {
    
    func numberOfDaysUntilDateTime(toDateTime: Date, inTimeZone timeZone: TimeZone? = nil) -> Int {
        var calendar = Calendar.current
        if let timeZone = timeZone {
            calendar.timeZone = timeZone
        }
        
        let date1 = calendar.startOfDay(for: self)
        let date2 = calendar.startOfDay(for: toDateTime)
        
        let components = calendar.dateComponents([.day], from: date1, to: date2)
        return components.day!
    }
    
    static func getDateFrom(year: Int, month: Int, day: Int) -> Date {
        let comps = NSDateComponents()
        comps.day = day
        comps.month = month
        comps.year = year
        let newDate = NSCalendar.current.date(from: comps as DateComponents)
        return newDate!
    }

    func getDateAddedBy(minutes: Int) -> Date {
        let dateComponents = NSDateComponents()
        dateComponents.minute = minutes

        let newDate = Calendar.current.date(byAdding: dateComponents as DateComponents, to: self)
        return newDate!
    }

    func getDateAddedBy(hours: Int) -> Date {
        let dateComponents = NSDateComponents()
        dateComponents.hour = hours

        let newDate = Calendar.current.date(byAdding: dateComponents as DateComponents, to: self)
        return newDate!
    }
    
    func getDateAddedBy(days: Int) -> Date {
        let dateComponents = NSDateComponents()
        dateComponents.day = days
        
        let newDate = Calendar.current.date(byAdding: dateComponents as DateComponents, to: self)
        return newDate!
    }
    
    func getDateAddedBy(months: Int) -> Date {
        let dateComponents = NSDateComponents()
        dateComponents.month = months
        
        let newDate = Calendar.current.date(byAdding: dateComponents as DateComponents, to: self)
        return newDate!
    }
    
    static func getCurrentTimeMills() -> Int64 {
        let now = Date()
        let elapsed = now.timeIntervalSince1970
        return Int64(elapsed*1000)
    }

    static func getDateString(timeMills: Int64) -> String {
        let elapsed = Double(timeMills)/1000
        let date = Date(timeIntervalSince1970: elapsed)
        return date.toDateString(format: "yyyy-MM-dd HH:mm:ss") ?? ""
    }

    static func getDate(timeMills: Int64) -> Date {
        let elapsed = Double(timeMills)/1000
        let date = Date(timeIntervalSince1970: elapsed)
        return date
    }

}

// MARK: -extension for project
extension Date {
    
    func toDateString(format: String = "EEE, MMM d, yyyy") -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
    static func fromDateString(dateString: String, format: String = "M/d/yyyy") -> Date? {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: dateString)
    }

    static func fromTimeStamp(timeStamp: Int64) -> Date {
        let elapsed = Double(timeStamp)/1000
        let date = Date(timeIntervalSince1970: elapsed)
        return date
    }

    static func convertDateFormat(dateString: String, fromFormat: String, toFormat: String) -> String {
        if dateString.isEmpty == true {
            return ""
        }
        guard let date = Date.fromDateString(dateString: dateString, format: fromFormat) else {return ""}
        return date.toDateString(format: toFormat) ?? ""
    }

    static func getDaysIn(year: Int, month: Int) -> Int {

        let dateComponents = DateComponents(year: year, month: month)
        let calendar = Calendar.current
        let date = calendar.date(from: dateComponents)!

        let range = calendar.range(of: .day, in: .month, for: date)!
        let numDays = range.count
        return numDays
    }

    func getTimestamp() -> Int64 {
        return Int64(self.timeIntervalSince1970*1000)
    }

    func getJustDay() -> Date {
        let dayString = (self.toDateString(format: "yyyy-MM-dd") ?? "") + "00:00:00"
        let justDay = Date.fromDateString(dateString: dayString, format: "yyyy-MM-ddHH:mm:ss") ?? Date()
        return justDay
    }
    
    func getDateLastTime() -> Date {
        let dayString = (self.toDateString(format: "yyyy-MM-dd") ?? "") + "23:59:59"
        let justDay = Date.fromDateString(dateString: dayString, format: "yyyy-MM-ddHH:mm:ss") ?? Date()
        return justDay
    }
    
    func isMorning() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
            case 6..<12:
                return true
            default:
                return false
        }
    }
}

extension NSDate {
    
    var date: Date {
        return self as Date
    }
}
