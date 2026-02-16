import Foundation
import SocketIO

final class SignalingService {
    
    static let shared = SignalingService()
    
    private let manager: SocketManager
    private let socket: SocketIOClient
    
    // MARK: - Callbacks
    
    var onConnect: (() -> Void)?
    var onDisconnect: (() -> Void)?
    var onUserJoined: ((Sender) -> Void)?
    var onUserLeft: ((String) -> Void)?
    var onMessageReceived: ((Sender) -> Void)?
    
    // MARK: - Init
    
    private init() {
        
        let url = URL(string: "https://maneuverable-cognatic-jaydon.ngrok-free.dev")! // change if needed
        
        manager = SocketManager(
            socketURL: url,
            config: [.log(true), .compress]
        )
        
        socket = manager.defaultSocket
        
        setupListeners()
    }
    
    // MARK: - Connection
    
    func connect() {
        socket.connect()
    }
    
    func disconnect() {
        socket.disconnect()
    }
    
    var socketId: String {
        socket.sid ?? UUID().uuidString
    }
    
    // MARK: - Setup Listeners
    
    private func setupListeners() {
        
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            print("✅ Connected")
            self?.onConnect?()
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            print("❌ Disconnected")
            self?.onDisconnect?()
        }
        
        // MARK: User Joined
        
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
            
            print("ROOM USERS RECEIVED:", data)
        }

        
        // MARK: User Left
        
        socket.on("user-left") { [weak self] data, _ in
            guard
                let dict = data.first as? [String: Any],
                let senderId = dict["senderId"] as? String
            else { return }
            
            self?.onUserLeft?(senderId)
        }
        
        // MARK: Message Received
        
        socket.on("chat-message") { [weak self] data, _ in
            guard
                let dict = data.first as? [String: Any],
                let sender = self?.decodeSender(dict)
            else { return }
            
            self?.onMessageReceived?(sender)
        }
    }
    
    // MARK: - Room
    
    func createRoom(_ sender: Sender) {
        emit(event: "create-room", sender: sender)
    }
    
    func joinRoom(_ sender: Sender) {
        emit(event: "join-room", sender: sender)
    }
    
    // MARK: - Send Message
    
    func sendMessage(_ sender: Sender) {
        emit(event: "chat-message", sender: sender)
    }
    
    // MARK: - Emit Helper
    
    private func emit(event: String, sender: Sender) {
        
        do {
            let data = try JSONEncoder().encode(sender)
            let json = try JSONSerialization.jsonObject(with: data)
            socket.emit(event, json as! SocketData)
        } catch {
            print("❌ Encoding Error:", error)
        }
    }
    
    // MARK: - Decode Helper
    
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
