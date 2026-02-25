import Foundation
import SocketIO
import WebRTC
import Combine

final class SignalingService: ObservableObject {
    
    static let shared = SignalingService()
    
    private let manager: SocketManager
    var socket: SocketIOClient
    
    // MARK: - Chat Callbacks
    
    var onConnect: (() -> Void)?
    var onDisconnect: (() -> Void)?
    var onUserJoined: ((Sender) -> Void)?
    var onUserLeft: ((String) -> Void)?
    var onMessageReceived: ((Sender) -> Void)?
    
    // MARK: - Typing Callbacks

    var onUserTyping:((String,String) -> Void)?
    var onUserStopTyping: ((String) -> Void)?
    
    
    // MARK: - Audio Call Callbacks
    
    var onAudioCallStarted: (() -> Void)?
    var onAudioCallEndedByHost: (() -> Void)?
    var onParticipantJoinedAudio: ((String) -> Void)?
    var onParticipantLeftAudio: ((String) -> Void)?
    
    // MARK: - Video Call Callbacks
    
    var onVideoCallStarted: ((String) -> Void)?
    var onExistingVideoParticipants: (([String]) -> Void)?

    var onVideoCallEndedByHost: (() -> Void)?
    var onParticipantJoinedVideo: ((String) -> Void)?
    var onParticipantJoinedVideoForUI: ((String) -> Void)?
    var onParticipantLeftVideo: ((String) -> Void)?
    
    // MARK: - WebRTC Signaling Callbacks

    var onOfferReceived: ((String, RTCSessionDescription) -> Void)?
    var onAnswerReceived: ((String, RTCSessionDescription) -> Void)?
    var onCandidateReceived: ((String, RTCIceCandidate) -> Void)?
    
    
    @Published var isConnected = false
    @Published var isInVideo = false
    @Published var isVideoActive = false
    @Published var currentPeer: PeerModel?
    @Published var activePeers: [PeerModel] = []
    @Published var showMeetingEndedAlert = false

    private init() {
        
        let url = URL(string: "https://a294-111-92-91-96.ngrok-free.app")!
        
        manager = SocketManager(
            socketURL: url,
            config: [.log(false), .compress]
        )
        
        socket = manager.defaultSocket
        
        setupListeners()
    }
    
    func connect() {
        socket.connect()
    }
    
    func disconnect() {
        socket.disconnect()
    }
    
    var socketId: String {
        socket.sid ?? UUID().uuidString
    }
    
    
    private func setupListeners() {
        
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            print("Socket connected?", self?.socket.status == .connected)
            print("Socket Status : \(self?.socket.status, default: "Mera default hai....")")
            print("Connected........")
            self?.onConnect?()
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            print("Disconnected.......")
            self?.onDisconnect?()
        }
        
        // MARK: USER JOINED
        
        socket.on("user-joined") { [weak self] data, _ in
            guard
                let dict = data.first as? [String: Any],
                let sender = self?.decodeSender(dict)
            else { return }
            
            self?.onUserJoined?(sender)
        }
        
        socket.on("room-users") { [weak self] data, _ in
            guard let arr = data.first as? [[String: Any]] else { return }
            
            for dict in arr {
                if let sender = self?.decodeSender(dict) {
                    self?.onUserJoined?(sender)
                }
            }
        }
        
        // MARK: USER LEFT
        
        socket.on("user-left") { [weak self] data, _ in
            guard
                let dict = data.first as? [String: Any],
                let senderId = dict["senderId"] as? String
            else { return }
            
            self?.onUserLeft?(senderId)
        }
        
        // MARK: CHAT MESSAGE
        
        socket.on("chat-message") { [weak self] data, _ in
            guard
                let dict = data.first as? [String: Any],
                let sender = self?.decodeSender(dict)
            else { return }
            
            self?.onMessageReceived?(sender)
        }
        
        // MARK: - Typing

            socket.on("typing") { [weak self] data, _ in
              guard
                let dict = data.first as? [String: Any],
                let senderId = dict["senderId"] as? String,
                let name = dict["name"] as? String
              else { return }

              self?.onUserTyping?(senderId, name)
            }

            socket.on("stop-typing") { [weak self] data, _ in
              guard
                let dict = data.first as? [String: Any],
                let senderId = dict["senderId"] as? String
              else { return }

              self?.onUserStopTyping?(senderId)
            }
        
            //MARK: - For Audio
        
        socket.on("audio-call-started") { [weak self] _, _ in
            self?.onAudioCallStarted?()
        }
        
        socket.on("audio-call-ended-by-host") { [weak self] _, _ in
            self?.onAudioCallEndedByHost?()
        }
        
        socket.on("participant-joined-audio") { [weak self] data, _ in
            guard
                let dict = data.first as? [String: Any],
                let senderId = dict["senderId"] as? String
            else { return }
            
            self?.onParticipantJoinedAudio?(senderId)
        }
        
        socket.on("participant-left-audio") { [weak self] data, _ in
            guard
                let dict = data.first as? [String: Any],
                let senderId = dict["senderId"] as? String
            else { return }
            
            self?.onParticipantLeftAudio?(senderId)
        }
        
        
        socket.on("video-call-started") { [weak self] data , _ in
            DispatchQueue.main.async {
                self?.isVideoActive = true  // ✅ UI button change karne ke liye
            }
            guard let dict = data.first as? [String: Any],
                  let senderId = dict["senderId"] as? String else { return }
            self?.onVideoCallStarted?(senderId)
        }
        
        socket.on("video-call-ended-by-host") { [weak self] _, _ in
            self?.onVideoCallEndedByHost?()
        }
        
        socket.on("participant-joined-video") { [weak self] data, _ in
            guard
                let dict = data.first as? [String: Any],
                let senderId = dict["senderId"] as? String
            else { return }
            
            self?.onParticipantJoinedVideo?(senderId)
            self?.onParticipantJoinedVideoForUI?(senderId)
            print("New participant:", senderId)

        }
        
        socket.on("existing-video-participants") { [weak self] data, _ in
            
            guard let arr = data.first as? [String] else { return }
            self?.onExistingVideoParticipants?(arr)
            print("Existing participants:", arr)

        }
        
        socket.on("participant-left-video") { [weak self] data, _ in
            guard
                let dict = data.first as? [String: Any],
                let senderId = dict["senderId"] as? String
            else { return }
            
            self?.onParticipantLeftVideo?(senderId)
        }
        
        //MARK: - For WebRtc Signling
        
        socket.on("offer") { [weak self] data, _ in
            guard
                let dict = data.first as? [String: Any],
                let from = dict["from"] as? String,
                let sdpString = dict["sdp"] as? String
            else { return }
            
            let sdp = RTCSessionDescription(type: .offer, sdp: sdpString)
            self?.onOfferReceived?(from, sdp)
        }

        socket.on("answer") { [weak self] data, _ in
            guard
                let dict = data.first as? [String: Any],
                let from = dict["from"] as? String,
                let sdpString = dict["sdp"] as? String
            else { return }
            
            let sdp = RTCSessionDescription(type: .answer, sdp: sdpString)
            self?.onAnswerReceived?(from, sdp)
        }

        socket.on("candidate") { [weak self] data, _ in
            guard
                let dict = data.first as? [String: Any],
                let from = dict["from"] as? String,
                let sdp = dict["candidate"] as? String,
                let sdpMid = dict["sdpMid"] as? String,
                let sdpMLineIndex = dict["sdpMLineIndex"] as? Int
            else { return }
            
            let candidate = RTCIceCandidate(
                sdp: sdp,
                sdpMLineIndex: Int32(sdpMLineIndex),
                sdpMid: sdpMid
            )
            
            self?.onCandidateReceived?(from, candidate)
        }


        socket.on(clientEvent: .connect) { _, _ in self.isConnected = true }
        
        socket.on("videoMembersUpdate") { data, _ in
            guard let members = data[0] as? [[String: Any]] else { return }
            let memberIds = members.compactMap { $0["senderId"] as? String }
                self.onExistingVideoParticipants?(memberIds)
            let peers = members.map { dict in
                PeerModel(
                    name: dict["name"] as? String ?? "",
                    senderId: dict["senderId"] as? String ?? "",
                    isHost: dict["isHost"] as? Bool ?? false,
                    roomId: dict["roomId"] as? String ?? "",
                    content: ""
                )
            }
            DispatchQueue.main.async {
                self.activePeers = peers
                self.checkMeshConnections()
            }
        }
        
        socket.on("receiveOffer") { data, _ in
            guard let dict = data[0] as? [String: Any],
                  let sdp = dict["sdp"] as? String,
                  let sId = dict["senderId"] as? String else { return }
            
            VConnectRTC.shared.handleRemoteOffer(sdp: sdp, from: sId) { answerSdp in
                self.socket.emit("sendAnswer", ["sdp": answerSdp.sdp, "targetId": sId, "senderId": self.currentPeer?.senderId ?? ""])
            }
        }
        
        socket.on("receiveAnswer") { data, _ in
            guard let dict = data[0] as? [String: Any],
                  let sdp = dict["sdp"] as? String,
                  let sId = dict["senderId"] as? String else { return }
            VConnectRTC.shared.handleRemoteAnswer(sdp: sdp, from: sId)
        }
        
        
        
        
        socket.on("receiveIceCandidate") { data, _ in
            guard let dict = data[0] as? [String: Any],
                  let candidate = dict["candidate"] as? [String: Any],
                  let sId = dict["senderId"] as? String else { return }
            VConnectRTC.shared.handleIceCandidate(dict: candidate, from: sId)
        }
        socket.on("peerMuteUpdate") { data, _ in
            print("📥 [SOCKET] Received peerMuteUpdate: \(data)")
            guard let dict = data[0] as? [String: Any],
                  let sId = dict["senderId"] as? String,
                  let mutedStatus = dict["isMuted"] as? Bool else { return }
            
            DispatchQueue.main.async {
                // Peer ki list mein index dhoondo aur update karo
                if let index = self.activePeers.firstIndex(where: { $0.senderId == sId }) {
                    self.activePeers[index].isMuted = mutedStatus
                    
              
                    print("👤 Peer \(sId) is now \(mutedStatus ? "Muted" : "Unmuted")")
                }
            }
        }
        socket.on("peerVideoUpdate") { data, _ in
            guard let dict = data[0] as? [String: Any],
                  let sId = dict["senderId"] as? String,
                  let videoStatus = dict["isVideoOff"] as? Bool else { return }
            
            DispatchQueue.main.async {
                if let index = self.activePeers.firstIndex(where: { $0.senderId == sId }) {
                    var newPeers = self.activePeers
                    newPeers[index].isVideoOff = videoStatus // PeerModel mein isVideoOff hona chahiye
                    self.activePeers = newPeers
                }
            }
        }
      

      
        socket.on("meetingStatusUpdate") { [weak self] data, _ in
            guard let dict = data.first as? [String: Any],
                  let isLive = dict["isLive"] as? Bool else { return }

            DispatchQueue.main.async {
                self?.isVideoActive = isLive

                if !isLive {
                    VConnectRTC.shared.closeAllConnections()
                    self?.activePeers.removeAll()
                    self?.isInVideo = false
                    self?.showMeetingEndedAlert = true
                }
            }
        }

        
        socket.on("meetingEnded") { [weak self] _, _ in
            DispatchQueue.main.async {
                if self?.isInVideo == true {
                    self?.showMeetingEndedAlert = true
                }
            }
        }
    
    

    }
    
  
    private func checkMeshConnections() {
        for peer in activePeers {
            if peer.senderId == currentPeer?.senderId { continue }
            
            // Golden Rule: Choti ID wala Offer bhejega
            if (currentPeer?.senderId ?? "") < peer.senderId {
                if VConnectRTC.shared.clients[peer.senderId] == nil {
                    VConnectRTC.shared.initiateInternalConnection(to: peer)
                }
            }
        }
    }
    
    func startRoom(id: String) {
        currentPeer?.isHost = true
        currentPeer?.roomId = id
        joinRoom(id: id)
    }
    

    
    func joinRoom(id: String) {
     
        
        
        print("yeh mere rooID hai jo ki viewModel se aarhahai ", id)
        currentPeer?.roomId = id
        
        print(self.currentPeer?.roomId ,"yeh mere join room wala join id hai")
 
        guard let peer = self.currentPeer else { return }
       
        print("🚀 Joining Room: \(id) | My ID: \(peer.senderId)")
   
        
        
        socket.emit("joinVideo", [
            "roomId": id,
            "senderId": peer.senderId,
            "name": peer.name,
            "isHost": peer.isHost
        ])
        
        VConnectRTC.shared.prepareLocalMedia()
        self.isInVideo = true
    }
    
    func UIStateChanged(id: String) {
         socket.emit("startMeeting", ["roomId": id])
        
    }
    
    
    func updateMuteStatus(isMuted: Bool) {
  
        guard let peer = currentPeer else {
            print("❌ Error: Current Peer not found")
            return
        }
        
        let data: [String: Any] = [
            "roomId": peer.roomId,
            "senderId": peer.senderId,
            "isMuted": isMuted
        ]
        
        print("📤 Sending Mute Status for \(peer.senderId): \(isMuted)")
        socket.emit("toggleMute", data)
    }
    
    func updateVideoStatus(isVideoOff: Bool) {
        guard let peer = currentPeer, !peer.roomId.isEmpty else { return }
        
        let data: [String: Any] = [
            "roomId": peer.roomId,
            "senderId": peer.senderId,
            "isVideoOff": isVideoOff
        ]
        socket.emit("toggleVideo", data)
    }
    
    func leaveOrEndCall() {
        guard let peer = currentPeer else { return }

        if peer.isHost {
            socket.emit("endMeeting", ["roomId": peer.roomId])
        } else {
            socket.emit("leaveVideo", [
                "roomId": peer.roomId,
                "senderId": peer.senderId
            ])

            VConnectRTC.shared.closeAllConnections()
            activePeers.removeAll()
            isInVideo = false
        }
    }

    func cleanupOnlyVideo() {
        DispatchQueue.main.async {
            VConnectRTC.shared.closeAllConnections()
            self.activePeers.removeAll()
            print("🧹 Hardware Released & Connections Closed")
        }
    }
    
    
    func createRoom(_ sender: Sender) {
        emit(event: "create-room", sender: sender)
    }
    
    func joinRoom(_ sender: Sender) {
        emit(event: "join-room", sender: sender)
    }
    

    
    func sendMessage(_ sender: Sender) {
        emit(event: "chat-message", sender: sender)
    }
    
    func sendTyping(roomId: String, name: String) {
        socket.emit("typing", [
            "roomId": roomId,
            "senderId": socketId,
            "name": name
        ])
    }

    func sendStopTyping(roomId: String) {
        socket.emit("stop-typing", [
            "roomId": roomId,
            "senderId": socketId
        ])
    }
    
    
    
    func startAudioCall(roomId: String) {
        socket.emit("start-audio-call", ["roomId": roomId])
    }
    
    func joinAudioCall(roomId: String) {
        socket.emit("join-audio-call", ["roomId": roomId])
    }
    
    func leaveAudioCall(roomId: String) {
        socket.emit("leave-audio-call", ["roomId": roomId])
    }

    
    func endAudioCall(roomId: String) {
        socket.emit("end-audio-call", ["roomId": roomId])
    }
    

    
    func startVideoCall(roomId: String) {
        print("📤 Emitting start-video-call for:", roomId)
        print("Room ID:", roomId)

        socket.emit("start-video-call", ["roomId": roomId])
    }
    
    func joinVideoCall(roomId: String) {
        
        socket.emit("join-video-call", ["roomId": roomId])
    }
    
    func leaveVideoCall(roomId: String) {
        socket.emit("leave-video-call", ["roomId": roomId])
    }
    
    func endVideoCall(roomId: String) {
        socket.emit("end-video-call", ["roomId": roomId])
    }
    


    func sendOffer(to peerId: String, sdp: RTCSessionDescription) {
        print("📡 EMITTING OFFER TO:", peerId)
        socket.emit("offer", [
            "to": peerId,
            "from": socketId,
            "sdp": sdp.sdp
        ])
    }
    
    func sendAnswer(to peerId: String, sdp: RTCSessionDescription) {
        
        socket.emit("answer", [
            "to": peerId,
            "from": socketId,
            "sdp": sdp.sdp
        ])
    }

    func sendCandidate(to peerId: String, candidate: RTCIceCandidate) {
        
        socket.emit("candidate", [
            "to": peerId,
            "from": socketId,
            "candidate": candidate.sdp,
            "sdpMid": candidate.sdpMid ?? "",
            "sdpMLineIndex": candidate.sdpMLineIndex
        ])
    }

    
  
    
    private func emit(event: String, sender: Sender) {
        
        do {
            let data = try JSONEncoder().encode(sender)
            let json = try JSONSerialization.jsonObject(with: data)
            socket.emit(event, json as! SocketData)
        } catch {
            print(" Encoding Error:", error)
        }
    }
    
    
    private func decodeSender(_ dict: [String: Any]) -> Sender? {
        
        do {
            let data = try JSONSerialization.data(withJSONObject: dict)
            let sender = try JSONDecoder().decode(Sender.self, from: data)
            return sender
        } catch {
            print(" Decoding Error:", error)
            return nil
        }
    }
}
extension Notification.Name {
    static let meetingEnded = Notification.Name("meetingEnded")
}
