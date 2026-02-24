//
//  ConnectPage.swift
//  Chat_AC_VCApp
//
//  Created by Sumit Raj Chingari on 16/02/26.
//
import SwiftUI

struct ConnectPage: View {
    
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var roomId: RoomId
    @EnvironmentObject var appState : AppState
    @EnvironmentObject var userArray: UserArray
    
    @State private var isConnected = false
    @State private var isLoading = false
    @State private var showJoinAlert = false
    @State private var joinRoomCode = ""
    @State private var navigateToNext = false
    @State private var showRoomOptions = false
    
    private var name: String {
        userStore.user?.name ?? ""
    }
    
    var body: some View {
        
        ZStack {
            
            LinearGradient(
                colors: [Color.blue.opacity(0.7),
                         Color.purple.opacity(0.6),
                         Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                
                Spacer()
                
                Text("Welcome, \(name)")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                // MARK: CONNECT BUTTON
                
                if !isConnected {
                    
                    ZStack {
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        }
                        
                        Button {
                            connectWithDelay()
                        } label: {
                            Text(isLoading ? "" : "Connect")
                                .fontWeight(.bold)
                                .frame(width: 200, height: 55)
                                .background(.ultraThinMaterial)
                                .cornerRadius(15)
                                .foregroundColor(.white)
                        }
                        .disabled(isLoading)
                    }
                    
                } else {
                    
                    Button {
                        disconnect()
                    } label: {
                        Text("Disconnect")
                            .fontWeight(.bold)
                            .frame(width: 200, height: 55)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(15)
                            .foregroundColor(.white)
                    }
                }
                
                // MARK: ROOM OPTIONS
                
                if showRoomOptions {
                    
                    VStack(spacing: 20) {
                        
                        Button {
                            createRoom()
                        } label: {
                            Text("Create Room")
                                .frame(width: 200, height: 50)
                                .background(Color.green.opacity(0.8))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }
                        
                        Button {
                            showJoinAlert = true
                        } label: {
                            Text("Join Room")
                                .frame(width: 200, height: 50)
                                .background(Color.orange.opacity(0.8))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
                
            }
            .padding()
        }
        .navigationTitle("Connect")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.4), value: showRoomOptions)
        
        .alert("Join Room", isPresented: $showJoinAlert) {
            
            TextField("Enter Room ID", text: $joinRoomCode)
            
            Button("Join") {
                joinRoom()
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .navigationDestination(isPresented: $navigateToNext) {
            TabsView() 
        }
    }
}

// MARK: - FUNCTIONS

extension ConnectPage {
    
    private func connectWithDelay() {
        
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            
            SignalingService.shared.connect()
            
            isLoading = false
            isConnected = true
            
            withAnimation {
                showRoomOptions = true
            }
        }
    }
    
    private func disconnect() {
        
        SignalingService.shared.disconnect()
        
        withAnimation {
            isConnected = false
            showRoomOptions = false
        }
    }
    
    private func createRoom() {
        
        let randomRoom = String(Int.random(in: 100...999))
        roomId.roomID = randomRoom
        
        let sender = Sender(
            name: name,
            senderId: SignalingService.shared.socketId,
            content: nil,
            time: Date(),
            roomId: randomRoom,
            isHost: true
        )
        let myPeer = PeerModel(
            name: name,
            senderId: SignalingService.shared.socketId,
            isHost: true,
            roomId: "",
            content: ""
        )
        
        // ✅ 3. Socket mein current user set karo
        
        userArray.users.removeAll()
        userArray.users.append(sender)
        
        SignalingService.shared.createRoom(sender)
        SignalingService.shared.currentPeer = myPeer
        
        navigateToNext = true
    }
    
    private func joinRoom() {
        
        roomId.roomID = joinRoomCode
        
        let sender = Sender(
            name: name,
            senderId: SignalingService.shared.socketId,
            content: nil,
            time: Date(),
            roomId: joinRoomCode,
            isHost: false
        )
        
        let myPeer = PeerModel(
             name: name,
             senderId:  SignalingService.shared.socketId,
             isHost: false,
             roomId: joinRoomCode,
             content: ""
         )
        
        SignalingService.shared.currentPeer = myPeer
        
        userArray.users.removeAll()
        userArray.users.append(sender)
        
        SignalingService.shared.joinRoom(sender)
        
        navigateToNext = true
        
    }
}

#Preview {
    NavigationStack {
        ConnectPage()
            .environmentObject(UserStore())
            .environmentObject(RoomId())
            .environmentObject(AppState())
            .environmentObject(UserArray())
    }
}

