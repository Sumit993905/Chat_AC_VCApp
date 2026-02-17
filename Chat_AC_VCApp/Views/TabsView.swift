//
//  TabsView.swift
//  Chat_AC_VCApp
//

import SwiftUI

struct TabsView: View {
    
    @State private var selection = 0
    
    @EnvironmentObject var roomId: RoomId
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userArray : UserArray
    
    var body: some View {
        
        ZStack {
            
            LinearGradient(
                colors: [
                    Color.black,
                    Color.blue.opacity(0.6),
                    Color.purple.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            TabView(selection: $selection) {
                
                ChatView()
                    .tabItem {
                        Label("Chat", systemImage: "message.fill")
                    }
                    .tag(0)
                
                AudioView(callVM: CallViewModel(roomId: roomId.roomID ?? "Guest", isHost: ((userArray.users.first?.isHost) != nil)))
                    .tabItem {
                        Label("Audio", systemImage: "mic.fill")
                    }
                    .tag(1)
                
                VideoView()
                    .tabItem {
                        Label("Video", systemImage: "video.fill")
                    }
                    .tag(2)
            }
        }
        .navigationTitle(currentTitle)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            
            
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if let id = roomId.roomID {
                    Text("Room: \(id)")
                        .font(.caption.monospaced())
                        .foregroundColor(.black.opacity(0.8))
                }
            }
            
            // Logout
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    logout()
                } label: {
                    Image(systemName: "power")
                        .foregroundColor(.red)
                }
            }
        }
        .onAppear {
            print("Room ID in Tabs:", roomId.roomID ?? "NIL")
        }

    }
}

// MARK: - Computed Title

extension TabsView {
    
    private var currentTitle: String {
        switch selection {
        case 0: return "Chat Room"
        case 1: return "Audio Call"
        case 2: return "Video Call"
        default: return "Chat"
        }
    }
    
    private func logout() {
        
        SignalingService.shared.disconnect()
        
        userArray.users.removeAll()
        roomId.roomID = nil
        appState.isLoggedIn = false
    }

}

#Preview {
    NavigationStack {
        TabsView()
            .environmentObject(RoomId())
            .environmentObject(AppState())
            .environmentObject(UserArray())
    }
}

