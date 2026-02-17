import SwiftUI

struct AudioCallView: View {
    
    @ObservedObject var viewModel: CallViewModel
    @EnvironmentObject var userArray: UserArray
    
    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        
        VStack {
            
            Text("Audio Call")
                .font(.title.bold())
                .padding(.top)
            
            Spacer()
            
            LazyVGrid(columns: columns, spacing: 20) {
                
                ForEach(userArray.users) { user in
                    CallUserCard(name: user.name)
                }
            }
            .padding()
            
            Spacer()
            
            controls
        }
        .onDisappear {
            viewModel.cleanupIfNeeded()
        }
    }
}


private extension AudioCallView {
    
    var controls: some View {
        
        HStack(spacing: 40) {
            
            Button {
                viewModel.toggleMute()
            } label: {
                Image(systemName: viewModel.isMuted ? "mic.slash.fill" : "mic.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.gray)
                    .clipShape(Circle())
            }
            
            Button {
                viewModel.endCall()
            } label: {
                Image(systemName: "phone.down.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 70, height: 70)
                    .background(Color.red)
                    .clipShape(Circle())
            }
            
            Button {
                viewModel.toggleSpeaker()
            } label: {
                Image(systemName: viewModel.isSpeakerOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.gray)
                    .clipShape(Circle())
            }
        }
        .padding(.bottom, 40)
    }
}
struct CallUserCard: View {
    
    let name: String
    @State private var animate = false
    
    var body: some View {
        
        ZStack {
            
            
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 20) {
                
                ZStack {
                    
                    
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(Color.green.opacity(0.4), lineWidth: 3)
                            .frame(width: 110, height: 110)
                            .scaleEffect(animate ? 1.6 : 0.8)
                            .opacity(animate ? 0 : 1)
                            .animation(
                                .easeOut(duration: 2)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.4),
                                value: animate
                            )
                            .offset(y:35)
                    }
                    
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(String(name.prefix(1)).uppercased())
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                        )
                        .shadow(color: .green.opacity(0.6), radius: 10)
                }
                
                Text(name)
                    .font(.headline)
                    .foregroundColor(.black)
            }
            .padding(.vertical, 25)
        }
        .frame(height: 220)
        .padding(8)
        .onAppear {
            animate = true
        }
    }
}


#Preview {
    
    let vm = CallViewModel(roomId: "123", isHost: true)
    
    AudioCallView(viewModel: vm)
        .environmentObject(UserArray())
}

