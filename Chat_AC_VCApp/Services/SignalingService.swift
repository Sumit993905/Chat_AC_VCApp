import Foundation
import SocketIO
import WebRTC

final class SignalingService {
    
    static let shared = SignalingService()
    
    private let manager: SocketManager
    private let socket: SocketIOClient
    
    // MARK: - Chat Callbacks
    
    var onConnect: (() -> Void)?
    var onDisconnect: (() -> Void)?
    var onUserJoined: ((Sender) -> Void)?
    var onUserLeft: ((String) -> Void)?
    var onMessageReceived: ((Sender) -> Void)?
    
    // MARK: - Audio Call Callbacks
    
    var onAudioCallStarted: (() -> Void)?
    var onAudioCallEndedByHost: (() -> Void)?
    var onParticipantJoinedAudio: ((String) -> Void)?
    var onParticipantLeftAudio: ((String) -> Void)?
    
    // MARK: - Video Call Callbacks
    
    var onVideoCallStarted: (() -> Void)?
    var onExistingVideoParticipants: (([String]) -> Void)?

    var onVideoCallEndedByHost: (() -> Void)?
    var onParticipantJoinedVideo: ((String) -> Void)?
    var onParticipantJoinedVideoForUI: ((String) -> Void)?
    var onParticipantLeftVideo: ((String) -> Void)?
    
    // MARK: - WebRTC Signaling Callbacks

    var onOfferReceived: ((String, RTCSessionDescription) -> Void)?
    var onAnswerReceived: ((String, RTCSessionDescription) -> Void)?
    var onCandidateReceived: ((String, RTCIceCandidate) -> Void)?

    private init() {
        
        let url = URL(string: "https://maneuverable-cognatic-jaydon.ngrok-free.dev")!
        
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
        
        //MARK: - For Video
        
        socket.on("video-call-started") { [weak self] _ , _ in
            self?.onVideoCallStarted?()
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
    
    // MARK: - AUDIO
    
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
    
    // MARK: - VIDEO
    
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
    
    // MARK: - WebRTC

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

    
    // MARK: -  Helper Method
    
    private func emit(event: String, sender: Sender) {
        
        do {
            let data = try JSONEncoder().encode(sender)
            let json = try JSONSerialization.jsonObject(with: data)
            socket.emit(event, json as! SocketData)
        } catch {
            print("❌ Encoding Error:", error)
        }
    }
    
    
    private func decodeSender(_ dict: [String: Any]) -> Sender? {
        
        do {
            let data = try JSONSerialization.data(withJSONObject: dict)
            let sender = try JSONDecoder().decode(Sender.self, from: data)
            return sender
        } catch {
            print("❌ Decoding Error:", error)
            return nil
        }
    }
}
