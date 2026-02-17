import SwiftUI

struct ChatView: View {
    
    @EnvironmentObject var userArray: UserArray
    @EnvironmentObject var messageStore: MessageStore
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var roomId: RoomId
    
    @State private var goToMessage = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private let maxUsers = 4
    
    var body: some View {
        
        VStack(spacing: 25) {
            
            Text("Room Members")
                .font(.title.bold())
                .padding(.top)
            
            Spacer()
            
            LazyVGrid(columns: columns, spacing: 20) {
                
                ForEach(0..<maxUsers, id: \.self) { index in
                    
                    if index < userArray.users.count {
                        UserCardView(
                            name: userArray.users[index].name,
                            isHost: userArray.users[index].isHost
                        )
                    } else {
                        UserCardView(name: "Guest User", isHost: false)
                            .opacity(0.3)
                    }
                }
            }
            .padding()
            
            
            Spacer()
            
            Button {
                goToMessage = true
            } label: {
                Text("Start Chat")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .navigationDestination(isPresented: $goToMessage) {
            MessageView()
        }
        .onAppear {
            setupSocketListeners()
        }
    }
}

// MARK: - Socket Setup

extension ChatView {
    
    private func setupSocketListeners() {
        
        
        SignalingService.shared.onUserJoined = { sender in
            DispatchQueue.main.async {
                
                if !userArray.users.contains(where: { $0.senderId == sender.senderId }) {
                    userArray.users.append(sender)
                }
            }
        }
        
        
        SignalingService.shared.onUserLeft = { senderId in
            DispatchQueue.main.async {
                userArray.users.removeAll { $0.senderId == senderId }
            }
        }
    }
}




struct UserCardView: View {
    
    let name: String
    var isHost: Bool = false
    
    var body: some View {
        
        VStack(spacing: 10) {
            
            ZStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                
                if isHost {
                    Text("👑")
                        .offset(x: 25, y: -25)
                }
            }
            
            Text(name.isEmpty ? "Guest User" : name)
                .font(.headline)
            
            if isHost {
                Text("HOST")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .frame(height: 130)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.blue.opacity(0.15))
        )
    }
}



#Preview {
    ChatView()
        .environmentObject(UserArray())
        .environmentObject(MessageStore())
        .environmentObject(UserStore())
        .environmentObject(RoomId())
}
