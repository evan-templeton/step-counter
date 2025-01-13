//
//  DailyStepsResult.swift
//  StepCounter
//
//  Created by Evan Templeton on 1/13/25.
//

import Foundation

struct DailyStepsResult: Identifiable, Equatable {
    let id: Int
    let datetime: Date
    let totalSteps: Int
    
    var monthAndDay: String {
        datetime.formatted(.dateTime.month(.defaultDigits).day())
    }
}

extension DailyStepsResult: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case datetime = "steps_datetime"
        case totalSteps = "steps_total_by_day"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        let dateString = try container.decode(String.self, forKey: .datetime)
        datetime = dateFormatter.date(from: dateString)!
        
        totalSteps = try container.decode(Int.self, forKey: .totalSteps)
    }
}
