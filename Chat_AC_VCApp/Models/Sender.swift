//
//  Sender.swift
//  Chat_AC_VCApp
//
//  Created by Sumit Raj Chingari on 16/02/26.
//

import Foundation

struct Sender: Codable, Identifiable {
    var id: UUID = UUID()
    let name: String
    let senderId: String
    let content: String?   // chat ke time use hoga
    let time: Date
    let roomId: String
    let isHost: Bool
}

