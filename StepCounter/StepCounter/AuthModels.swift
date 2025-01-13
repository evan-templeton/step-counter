//
//  AuthModels.swift
//  StepCounter
//
//  Created by Evan Templeton on 1/13/25.
//

import Foundation

struct AuthRequest: Encodable {
    let identifier: String
    let password: String
}

struct AuthResponse: Decodable {
    let jwt: String
    }
