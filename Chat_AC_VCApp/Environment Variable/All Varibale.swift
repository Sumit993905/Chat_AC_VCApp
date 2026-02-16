//
//  All Varibale.swift
//  Chat_AC_VCApp
//
//  Created by Sumit Raj Chingari on 16/02/26.
//

import Foundation
import Combine
import SwiftUI

final class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
}

final class RoomId: ObservableObject {
    @Published var roomID: String? = nil
}

final class UserStore: ObservableObject {
    @Published var user: UserModel? = nil
}

final class UserArray: ObservableObject {
    @Published var users: [Sender] = []
}

final class MessageStore: ObservableObject {
    @Published var messages: [Sender] = []
}

