//
//  RootView.swift
//  Chat_AC_VCApp
//
//  Created by Sumit Raj Chingari on 16/02/26.
//

import SwiftUI

struct RootView: View {
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userStore: UserStore
    
    
    var body: some View {
        
        if appState.isLoggedIn {
            
            NavigationStack {
                ConnectPage()
            }
            
        } else {
            NavigationStack {
                Login()
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
        .environmentObject(UserStore())
        .environmentObject(RoomId())
        .environmentObject(UserArray())
        .environmentObject(MessageStore())
}
