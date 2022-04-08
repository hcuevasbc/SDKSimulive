//
//  SimuliveConf.swift
//  
//
//  Created by Hector Cuevas on 07/04/22.
//

import Foundation

public struct SimuliveConf: Codable {
    public init(customStartFieldName:String = "simulive_start",
                tagValue:String  = "simulive",
                playlistInSuccession: Bool = false,
                modalAfterEvent: Int = 0,
                labels:Labels
    ) {
        self.customStartFieldName = customStartFieldName
        self.tagValue = tagValue
        self.modalAfterEvent = modalAfterEvent
        self.playlistInSuccession = playlistInSuccession
        self.labels = labels
    }
    
    public init(jsonString:String) {
        
        let decoder = JSONDecoder()
        if let data = jsonString.data(using: .utf8), let simuliveConf = try? decoder.decode(SimuliveConf.self, from: data) {
            self = simuliveConf
        } else {
            self.init(labels: Labels())
        }
    }
    
    var customStartFieldName:String = ""
    var tagValue:String = ""
    var playlistInSuccession: Bool = false
    var modalAfterEvent: Int = 0
    var labels: Labels?
}

public struct Labels:Codable {
    
    public init(ended:String = "Live event has ended.") {
        self.ended = ended
    }
    var ended: String? = ""
    var countdown: CountdownLabels?
}

public struct CountdownLabels: Codable {
    
    public init(live:String, day:String, days:String, hour:String, hours:String, minute:String, minutes:String, second:String, seconds:String) {
        self.live = live
        self.day = day
        self.days = days
        self.second = second
        self.seconds = seconds
        self.minute = minute
        self.minutes = minutes
        self.hour = hour
        self.hours = hours
    }
    
    var live: String? = ""
    var day: String? = ""
    var days: String? = ""
    var hour: String? = ""
    var hours: String? = ""
    var minute: String? = ""
    var minutes: String? = ""
    var second: String? = ""
    var seconds: String? = ""
}

