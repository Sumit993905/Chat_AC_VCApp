import SwiftUI

struct AudioCallView: View {
    
    @ObservedObject var viewModel: AudioCallViewModel
    @EnvironmentObject var userArray: UserArray
    
    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        
        ZStack{
            
            Color.black
                .ignoresSafeArea()
            
            VStack {
                
                Text("Enjoy Audio Call")
                    .font(.title.bold())
                    .padding(.top)
                    .foregroundStyle(.white)
                
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
            .navigationBarBackButtonHidden(true)
            
        }
        
      
    }
}


private extension AudioCallView {
    
    var controls: some View {
        
        HStack(spacing: 30) {
            
            circleButton(
                icon: self.viewModel.isAudioMuted ? "mic.slash.fill" : "mic.fill",
                color: .gray
            ) {
                self.viewModel.toggleMute()
            }
            
            circleButton(
                icon: "phone.down.fill",
                color: .red
            ) {
                viewModel.endCall()
            }
            
            circleButton(icon: viewModel.isSpeakerOn ? "speaker.wave.2.fill" : "speaker.slash.fill", color: .gray) {
                self.viewModel.toggleSpeaker()
            }
        
           
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .padding(.bottom, 30)
    }
    
    
    func circleButton(icon: String,
                      color: Color,
                      action: @escaping () -> Void) -> some View {
        
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(color)
                .clipShape(Circle())
        }
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
                            .scaleEffect(animate ? 1.6 : 1.0)
                            .opacity(animate ? 0 : 1)
                            .animation(
                                .easeOut(duration: 2)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.4),
                                value: animate
                            )
                            .offset(y:20)
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
    
    let vm = AudioCallViewModel(roomId: "123", isHost: true)
    
    AudioCallView(viewModel: vm)
        .environmentObject(UserArray())
}

