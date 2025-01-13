//
//  StepsRequest.swift
//  StepCounter
//
//  Created by Evan Templeton on 1/13/25.
//

import Foundation

struct StepsRequest: Encodable {
        let username: String
        let date: Date
        let time: Date
        let totalByDay: Int
        let count: Int
        
        enum CodingKeys: String, CodingKey {
            case username
            case date = "steps_date"
            case time = "steps_datetime"
            case count = "steps_count"
            case totalByDay = "steps_total_by_day"
        }
    }
