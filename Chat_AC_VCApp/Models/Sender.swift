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
    let content: String?   
    let time: Date
    let roomId: String
    let isHost: Bool
}

