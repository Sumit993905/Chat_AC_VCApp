//
//  WebRTCManager.swift
//  Chat_AC_VCApp
//
//  Created by Sumit Raj Chingari on 17/02/26.
//

import Foundation
import WebRTC
import Combine



final class WebRTCManager:ObservableObject {
    
    static let shared = WebRTCManager()

    private var peers: [String: WebRTCClient] = [:]
    
    private var localClient: WebRTCClient?
      var localVideoTrack: RTCVideoTrack?
      var localAudioTrack: RTCAudioTrack?
    @Published var remoteTracks: [String: RTCVideoTrack] = [:]
    
    
    
    private init() {
        setupSignaling()
    }
    

    
    private func setupSignaling() {
        
        let signaling = SignalingService.shared
        
        signaling.onOfferReceived = { [weak self] from, sdp in
            self?.handleOffer(from: from, sdp: sdp)
        }
        
        signaling.onAnswerReceived = { [weak self] from, sdp in
            self?.handleAnswer(from: from, sdp: sdp)
        }
        
        signaling.onCandidateReceived = { [weak self] from, candidate in
            self?.handleCandidate(from: from, candidate: candidate)
        }
        
        signaling.onVideoCallStarted = { [weak self] peerId in
            print("🔥 Video call started by the host side")
            
            self?.createPeerConnection(for: peerId)
            
            print("Peer connection created for host....")
            
        }
        
        signaling.onParticipantJoinedVideo = { [weak self] peerId in
            guard let self = self else { return }
            
            let myId = SignalingService.shared.socketId
            
            print("🔥 onParticipantJoinedVideo fired")
            print("My ID:", myId)
            print("Incoming peerId:", peerId)

            if peerId == myId {
                print("⚠️ Skipping because peerId == myId")
                return
            }

            print("📤 Creating offer for:", peerId)

            self.createPeerConnection(for: peerId)
            self.createOffer(for: peerId)
        }
        
        signaling.onExistingVideoParticipants = { [weak self] peers in
            
            guard let self = self else { return }
            
            let myId = SignalingService.shared.socketId
            
            for peerId in peers {
                if peerId == myId { continue }
                
                self.createPeerConnection(for: peerId)
            }
        }


        
        signaling.onParticipantLeftVideo = { [weak self] peerId in
            self?.removePeer(peerId: peerId)
        }
    }
    
    // MARK: - Local Media
    
    func startLocalMedia() {

      
        if localClient != nil { return }

        let client = WebRTCClient(peerId: "local")

        client.startLocalAudio()
        client.startLocalVideo()

        localVideoTrack = client.getLocalVideoTrack()
        localAudioTrack = client.getLocalAudioTrack()

        localClient = client   // 🔥 MUST retain

        print("🎥 Local media started once")
    }
    

    
    func createPeerConnection(for peerId: String) {

        if peers[peerId] != nil { return }
        
        guard let videoTrack = localVideoTrack,
              let audioTrack = localAudioTrack else {
            print("❌ Local tracks not ready yet")
            return
        }

        let client = WebRTCClient(peerId: peerId)
        client.delegate = self

        client.attachLocalVideoTrack(videoTrack)
        client.attachLocalAudioTrack(audioTrack)
        

        peers[peerId] = client

        print("✅ Peer created:", peerId)
        print("Local video track at peer creation:", localVideoTrack != nil)
        print("Local audio track at peer creation:", localAudioTrack != nil)
    }
    
    func removePeer(peerId: String) {
        peers[peerId]?.endCall()
        peers.removeValue(forKey: peerId)
        remoteTracks.removeValue(forKey: peerId)
        print("❌ Peer removed:", peerId)
    }
    
    func endAllConnections() {
        peers.values.forEach { $0.endCall() }
        peers.removeAll()
        remoteTracks.removeAll()
        localClient?.endCall()
        localClient = nil
        localVideoTrack = nil
    }
}



extension WebRTCManager {
    
    func createOffer(for peerId: String) {

        guard let client = peers[peerId] else {
            print("❌ No client for peer:", peerId)
            return
        }

        print("📤 Creating offer to:", peerId)

        client.createOffer { sdp in
            
            print("📤 Sending offer to:", peerId)
            
            SignalingService.shared.sendOffer(
                to: peerId,
                sdp: sdp
            )
        }
    }

    
    func handleOffer(from peerId: String, sdp: RTCSessionDescription) {
        
        createPeerConnection(for: peerId)
        
        guard let client = peers[peerId] else { return }
        
        client.setRemoteDescription(sdp)
        
        client.createAnswer { answer in
            
            SignalingService.shared.sendAnswer(
                to: peerId,
                sdp: answer
            )
        }
        
        print("📩 OFFER RECEIVED FROM:", peerId)

    }
    
    func handleAnswer(from peerId: String, sdp: RTCSessionDescription) {
        
        guard let client = peers[peerId] else { return }
        
        client.setRemoteDescription(sdp)
        
        print("📨 ANSWER RECEIVED FROM:", peerId)

    }
    
    func handleCandidate(from peerId: String, candidate: RTCIceCandidate) {
        peers[peerId]?.addIceCandidate(candidate)
    }
    
    func endCall(for peerId: String? = nil) {
        
        if let id = peerId {
            removePeer(peerId: id)
        } else {
            // Host ending full room
            peers.values.forEach { $0.endCall() }
            peers.removeAll()
            remoteTracks.removeAll()
        }
    }
    
    func setMute(_ isMuted: Bool) {
        
        peers.values.forEach { client in
            client.setMute(isMuted)
        }
    }

    func setSpeaker(enabled: Bool) {
        
        peers.values.forEach { client in
            client.setSpeaker(enabled: enabled)
        }
    }
    
    func storeRemoteTrack(_ track: RTCVideoTrack, for peerId: String) {
        remoteTracks[peerId] = track
    }

    func remoteVideoTrack(for peerId: String) -> RTCVideoTrack? {
        remoteTracks[peerId]
    }
    
    func setVideoEnabled(_ enabled: Bool) {
        peers.values.forEach { $0.setVideoEnabled(enabled) }
    }
    
//    func prepareLocalMedia() {
//
//        if localVideoTrack != nil { return }
//
//        let dummyClient = WebRTCClient(peerId: "local")
//        dummyClient.startLocalAudio()
//        dummyClient.startLocalVideo()
//
//        localVideoTrack = dummyClient.getLocalVideoTrack()
//    }

    
}


extension WebRTCManager: WebRTCClientDelegate {
    
    func webRTCClient(_ client: WebRTCClient,
                      didDiscoverLocalCandidate candidate: RTCIceCandidate,
                      for peerId: String) {
        
        SignalingService.shared.sendCandidate(
            to: peerId,
            candidate: candidate
        )
    }
    
    func webRTCClient(_ client: WebRTCClient,
                      didReceiveRemoteVideoTrack track: RTCVideoTrack,
                      for peerId: String) {
        
        DispatchQueue.main.async {
            self.remoteTracks[peerId] = track
        }
        print("📹 Remote track from:", peerId)
        
    }
    
    func webRTCClient(_ client: WebRTCClient,
                      didChangeConnectionState state: RTCIceConnectionState,
                      for peerId: String) {
        
        print("🔌 Connection:", state.rawValue)
    }
}
