//
//  VideoView.swift
//  Chat_AC_VCApp
//
//  Created by Sumit Raj Chingari on 16/02/26.
//
import SwiftUI

struct VideoView: View {
    
    @EnvironmentObject var userArray: UserArray
    @EnvironmentObject var roomId: RoomId
    @EnvironmentObject var userStore: UserStore
    
    @ObservedObject var viewModel: VideoCallViewModel
    @ObservedObject var signaling = SignalingService.shared
    
    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        
        ZStack {
            
            LinearGradient(
                colors: [.green, .indigo.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                
                Text("Video Lobby")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top)
                
                Spacer()
                
                LazyVGrid(columns: columns, spacing: 20) {
                    
                    ForEach(userArray.users) { user in
                        VideoLobbyCard(
                            name: user.name,
                            isHost: user.isHost
                        )
                    }
                }
                .padding()
                
                Spacer()
                
                actionSection
            }
        }
        .navigationDestination(isPresented: $viewModel.isInVideoCall) {
            VideoGridScreen()
                .environmentObject(userArray)
        }
        .onAppear {
            configureVM()
        }
    }
}
private extension VideoView {
    
    var actionSection: some View {
        
        VStack {
            // Host Logic
            if isCurrentUserHost {
                        // ✅ Host ke liye hamesha 'Start' dikhao agar call active nahi hai
                        // Agar host ne call end kar di, toh ye wapas Start dikhayega
                        if !signaling.isVideoActive {
                            mainButton(title: "Start Video Call", color: .green) {
                                viewModel.startCall()
                            }
                        } else {
                            // Agar meeting live hai, toh host ko "In Call" dikhao ya khali chhod do
                            // Taki host ko pata rahe ki meeting abhi chal rahi hai
                            mainButton(title: "Start Video Call", color: .blue) {
                                viewModel.joinCall() // Taki agar galti se lobby mein aaye toh wapas ja sake
                            }
                        }
                    } else {
                        // ✅ USER Logic: Bina host ke 'Waiting', host aate hi 'Join'
                        if signaling.isVideoActive {
                            mainButton(title: "Join Video Call", color: .blue) {
                                viewModel.joinCall()
                            }
                        } else {
                            mainButton(title: "Waiting for Host...", color: .gray) {}
                                .opacity(0.6)
                                .disabled(true)
                        }
                    }
                }
                .padding(.bottom, 30)
    }
    
    
    func mainButton(title: String,
                    color: Color,
                    action: @escaping () -> Void) -> some View {
        
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(14)
                .padding(.horizontal)
        }
    }
    
    
    var isCurrentUserHost: Bool {
        userArray.users.first(where: {
            $0.name == userStore.user?.name
        })?.isHost ?? false
    }
    
    
    func configureVM() {
        viewModel.roomId = roomId.roomID ?? ""
        viewModel.isHost = isCurrentUserHost
    }
}
struct VideoLobbyCard: View {
    
    let name: String
    let isHost: Bool
    
    var body: some View {
        
        VStack(spacing: 15) {
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                
                Image(systemName: "video.fill")
                    .font(.title)
                    .foregroundColor(.white)
                
                if isHost {
                    Text("👑")
                        .offset(x: 35, y: -35)
                }
            }
            
            Text(name)
                .foregroundColor(.white)
                .font(.headline)
            
            if isHost {
                Text("HOST")
                    .font(.caption)
                    .foregroundColor(.black)
            }
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}
#Preview {
    
    let vm = VideoCallViewModel(roomId: "123", isHost: true)
    
    VideoView(viewModel: vm)
        .environmentObject(UserArray())
        .environmentObject(UserStore())
        .environmentObject(RoomId())
}


