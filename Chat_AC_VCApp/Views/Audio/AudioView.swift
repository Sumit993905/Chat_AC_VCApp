import SwiftUI

struct AudioView: View {
    
    @EnvironmentObject var userArray: UserArray
    @EnvironmentObject var roomId: RoomId
    @EnvironmentObject var userStore: UserStore
    
    @ObservedObject var callVM: AudioCallViewModel
    @State private var navigateToCall = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        
        ZStack {
            
            LinearGradient(
                colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                
                Text("Audio Lobby")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top)
                
                Spacer()
                
                LazyVGrid(columns: columns, spacing: 20) {
                    
                    ForEach(userArray.users) { user in
                        AudioCard(
                            name: user.name,
                            isHost: user.isHost
                        )
                    }
                }
                .padding()
                
                Spacer()
                
                actionButton
            }
        }
        .navigationDestination(isPresented: $callVM.isInAudioCall) {
            AudioCallView(viewModel: callVM)
                .environmentObject(userArray)
        }

        .onAppear {
            configureVM()
        }
    }
}

private extension AudioView {
    
    var actionButton: some View {
        
        VStack{
            if callVM.isAudioCallActive == false {
                    
                    if isCurrentUserHost {
                        button(title: "Start Audio Call", color: .green) {
                            handleAction()
                        }
                    } else {
                        button(title: "Waiting for Host...", color: .gray) {}
                            .disabled(true)
                    }
                    
            } else {
                
                if !callVM.isInAudioCall {
                    button(title: "Join Audio Call", color: .blue) {
                        handleAction()
                    }
                }
            }
        }
        .padding(.bottom, 30)
    }
    
    func button(title: String, color: Color, action: @escaping () -> Void) -> some View {
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
    
    func handleAction() {
        
        guard let id = roomId.roomID else { return }
        
        callVM.roomId = id
        callVM.isHost = isCurrentUserHost
        
        if isCurrentUserHost {
            callVM.startCall()
        } else {
            callVM.joinCall()
        }
        
        navigateToCall = true
    }
    
    var isCurrentUserHost: Bool {
        userArray.users.first(where: {
            $0.name == userStore.user?.name
        })?.isHost ?? false
    }
    
    func configureVM() {
        callVM.roomId = roomId.roomID ?? ""
        callVM.isHost = isCurrentUserHost
    }
}


struct AudioCard: View {
    
    let name: String
    let isHost: Bool
    
    var body: some View {
        
        VStack(spacing: 12) {
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                
                Text(String(name.prefix(1)).uppercased())
                    .font(.largeTitle.bold())
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
        .frame(height: 170)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

#Preview {
    
    let vm = AudioCallViewModel(roomId: "123", isHost: true)
    
    AudioView(callVM: vm)
        .environmentObject(UserArray())
        .environmentObject(UserStore())
        .environmentObject(RoomId())
}

