//
// MessageView.swift
// Chat_AC_VCApp
//
// Created by Sumit Raj Chingari on 16/02/26.
//

import SwiftUI

struct MessageBubble: View {

  let text: String
  let senderName: String
  let isCurrentUser: Bool

  var body: some View {

    VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {

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

  @State private var typingUsers: [String: String] = [:] // senderId : name
  @State private var typingTimer: Timer?

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

      if !typingUsers.isEmpty {
        HStack {
          Text("\(typingUsers.values.joined(separator: ", ")) typing...")
            .font(.caption)
            .foregroundColor(.black)
          Spacer()
        }
        .padding(.horizontal)
      }

      Divider()

      HStack {

        TextField("Enter message...", text: $messageText)
          .padding(20)
          .overlay(
            RoundedRectangle(cornerRadius: 20)
              .stroke(Color.gray.opacity(0.3), lineWidth: 1)
          )
          .onChange(of: messageText) {
            handleTyping()
          }
        Button {
          sendMessage()
        } label: {
          Image(systemName: "paperplane.fill")
            .padding(15)
            .background(.green)
            .clipShape(Circle())
            .foregroundColor(.black)
            .rotationEffect(Angle(degrees: 45))
            .font(.title)
            .overlay(
              RoundedRectangle(cornerRadius: 30)
                .stroke(Color.gray.opacity(0.7), lineWidth: 1)
            )
        }
      }
      .padding()
    }
    .navigationTitle("Chatting")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {

      SignalingService.shared.onUserTyping = { senderId, name in
        DispatchQueue.main.async {
          if senderId != SignalingService.shared.socketId {
            typingUsers[senderId] = name
          }
        }
      }

      SignalingService.shared.onUserStopTyping = { senderId in
        DispatchQueue.main.async {
          typingUsers.removeValue(forKey: senderId)
        }
      }

      SignalingService.shared.onMessageReceived = { sender in
        DispatchQueue.main.async {
          messageStore.messages.append(sender)
        }
      }
    }
  }

  private func handleTyping() {

    guard let room = roomId.roomID else { return }

    // Send typing
    SignalingService.shared.sendTyping(
      roomId: room,
      name: userStore.user?.name ?? "Guest"
    )

    // Reset timer
    typingTimer?.invalidate()

    typingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
      SignalingService.shared.sendStopTyping(roomId: room)
    }
  }
}

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
