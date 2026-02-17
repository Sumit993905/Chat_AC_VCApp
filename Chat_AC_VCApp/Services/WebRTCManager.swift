//
//  WebRTCManager.swift
//  Chat_AC_VCApp
//
//  Created by Sumit Raj Chingari on 17/02/26.
//

import Foundation
import WebRTC
import Combine

final class WebRTCManager: ObservableObject {
    
    static let shared = WebRTCManager()
    
    // multiple connection ke liye jarurui hai yeah
    private var peers: [String: WebRTCClient] = [:]
    
    
    private var isAudioEnabled = true
    private var isVideoEnabled = true
    
    private init() {
        setupSignaling()
    }
    
    
    private func setupSignaling() {

        SignalingService.shared.onOfferReceived = { [weak self] from, sdp in
            self?.handleOffer(from: from, sdp: sdp)
        }

        SignalingService.shared.onAnswerReceived = { [weak self] from, sdp in
            self?.handleAnswer(from: from, sdp: sdp)
        }

        SignalingService.shared.onCandidateReceived = { [weak self] from, candidate in
            self?.handleCandidate(from: from, candidate: candidate)
        }

        // When someone joins audio/video
        SignalingService.shared.onParticipantJoinedAudio = { [weak self] peerId in
            self?.createPeerConnection(for: peerId)
            self?.createOffer(for: peerId)
        }

        SignalingService.shared.onParticipantJoinedVideo = { [weak self] peerId in
            self?.createPeerConnection(for: peerId)
            self?.createOffer(for: peerId)
        }

        // When someone leaves
        SignalingService.shared.onParticipantLeftAudio = { [weak self] peerId in
            self?.removePeer(peerId: peerId)
        }

        SignalingService.shared.onParticipantLeftVideo = { [weak self] peerId in
            self?.removePeer(peerId: peerId)
        }
    }

    
    
    func createPeerConnection(for peerId: String) {
        
        if peers[peerId] != nil { return }
        
        let client = WebRTCClient(peerId: peerId)
        client.delegate = self
        
        client.startLocalAudio()
        
        if isVideoEnabled {
            client.startLocalVideo()
        }
        
        peers[peerId] = client
        
        print("✅ Peer created:", peerId)
    }
    
    func removePeer(peerId: String) {
        peers[peerId]?.endCall()
        peers.removeValue(forKey: peerId)
        
        print("❌ Peer removed:", peerId)
    }

}

extension WebRTCManager {
    
    func createOffer(for peerId: String) {
        
        guard let client = peers[peerId] else { return }
        
        client.createOffer { sdp in
            
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
    }
    
    func handleAnswer(from peerId: String, sdp: RTCSessionDescription) {
        
        guard let client = peers[peerId] else { return }
        
        client.setRemoteDescription(sdp)
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
        
        print("--->Remote video track from:", peerId)
    }
    
    func webRTCClient(_ client: WebRTCClient,
                      didChangeConnectionState state: RTCIceConnectionState,
                      for peerId: String) {
        
        print("-->Connection state:", state.rawValue)
    }
}



