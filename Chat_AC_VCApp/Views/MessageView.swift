//
//  MessageView.swift
//  Chat_AC_VCApp
//
//  Created by Sumit Raj Chingari on 16/02/26.
//

import SwiftUI

struct MessageBubble: View {
    
    let text: String
    let senderName: String
    let isCurrentUser: Bool
    
    var body: some View {
        
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
            
            // 🔥 Show name only for other users
            if !isCurrentUser {
                Text(senderName)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(text)
                .padding()
                .background(isCurrentUser ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(isCurrentUser ? .white : .black)
                .cornerRadius(15)
        }
        .frame(maxWidth: 250, alignment: isCurrentUser ? .trailing : .leading)
    }
}





struct MessageView: View {
    
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var messageStore: MessageStore
    @EnvironmentObject var roomId: RoomId
    
    @State private var messageText = ""
    
    var body: some View {
        
        VStack {
            
            ScrollView {
                VStack(spacing: 12) {
                    
                    ForEach(messageStore.messages) { message in
                        
                        HStack {
                            
                            if message.senderId == SignalingService.shared.socketId {
                                Spacer()
                                
                                MessageBubble(
                                    text: message.content ?? "",
                                    senderName: message.name,
                                    isCurrentUser: true
                                )
                                
                            } else {
                                
                                MessageBubble(
                                    text: message.content ?? "",
                                    senderName: message.name,
                                    isCurrentUser: false
                                )
                                
                                Spacer()
                            }
                        }
                    }

                }
                .padding()
            }
            
            Divider()
            
            HStack {
                
                TextField("Enter message...", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .navigationTitle("Chatting")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            
            // ✅ Receive real-time messages
            SignalingService.shared.onMessageReceived = { sender in
                DispatchQueue.main.async {
                    messageStore.messages.append(sender)
                }
            }
        }
    }
}


// MARK: - Send Message

extension MessageView {
    
    private func sendMessage() {
        
        guard !messageText.isEmpty else { return }
        
        let newMessage = Sender(
            name: userStore.user?.name ?? "Guest",
            senderId: SignalingService.shared.socketId,
            content: messageText,
            time: Date(),
            roomId: roomId.roomID ?? "",
            isHost: false
        )
        
        SignalingService.shared.sendMessage(newMessage)
        
        messageText = ""
    }
}


#Preview {
    MessageView()
        .environmentObject(MessageStore())
        .environmentObject(UserStore())
        .environmentObject(RoomId())
}
