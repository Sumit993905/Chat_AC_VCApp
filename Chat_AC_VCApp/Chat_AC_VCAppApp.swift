//
//  Chat_AC_VCAppApp.swift
//  Chat_AC_VCApp
//
//  Created by Sumit Raj Chingari on 16/02/26.
//

import SwiftUI

@main
struct Chat_AC_VCApp: App {
    
    @StateObject var appState = AppState()
    @StateObject var userStore = UserStore()
    @StateObject var roomId = RoomId()
    @StateObject var userArray = UserArray()
    @StateObject var messageStore = MessageStore()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(userStore)
                .environmentObject(roomId)
                .environmentObject(userArray)
                .environmentObject(messageStore)
        }
    }
}

