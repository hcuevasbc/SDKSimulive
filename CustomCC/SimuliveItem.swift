//
//  SimuliveItem.swift
//  CustomCC
//
//  Created by Hector Cuevas on 08/04/22.
//

import Foundation
import BrightcovePlayerSDK

public struct SimuliveItem:  Equatable {
    public static func == (lhs: SimuliveItem, rhs: SimuliveItem) -> Bool {
        return lhs.id == rhs.id && lhs.start == rhs.start
    }
    
    public init(id: String, title: String, start: String, video: BCOVVideo) {
        self.id = id
        self.title = title
        self.start = start
        self.video = video
    }
    
    let id: String
    let title: String
    private let start: String
    var video:BCOVVideo
    
    func startString(date:Date) -> String {
       let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
//        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.timeZone = TimeZone.current

        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        let date = formatter.string(from: date)
        
        return date
    }
    
    var startDate:Date? {
       let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
//        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.timeZone = TimeZone.current

        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        let date = formatter.date(from: start)
        
        return date
    }
    
    var endDate:Date? {
       let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
//        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.timeZone = TimeZone.current

        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let startDate = startDate {
            if let duration = self.video.properties["duration"] as? Int {
            let endDate = startDate.addingTimeInterval(TimeInterval(duration/1000))
            return endDate
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}
