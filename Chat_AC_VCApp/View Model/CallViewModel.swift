//
//  CallViewModel.swift
//  Chat_AC_VCApp
//

import Foundation
import Combine
import WebRTC

final class CallViewModel: ObservableObject {
    
    // MARK: - Published UI States
    
    @Published var isCallActive: Bool = false
    @Published var isInCall: Bool = false
    
    
    @Published var participants: [String] = []
    
    @Published var isMuted: Bool = false
    @Published var isSpeakerOn: Bool = true
    
    // MARK: - Dependencies
    
    private let signaling = SignalingService.shared
    private let rtcManager = WebRTCManager.shared
    
    var roomId: String
    @Published var isHost: Bool = false
    
    // MARK: - Init
    
    init(roomId: String, isHost: Bool) {
        self.roomId = roomId
        self.isHost = isHost
        setupCallbacks()
        setupWebRTCListeners()
    }
}


private extension CallViewModel {
    
    func setupCallbacks() {
        
        // Host started call
        signaling.onAudioCallStarted = { [weak self] in
            DispatchQueue.main.async {
                self?.isCallActive = true
            }
        }
        
        // Host ended call
        signaling.onAudioCallEndedByHost = { [weak self] in
            DispatchQueue.main.async {
                self?.resetCallState()
            }
        }
        
        // Someone joined
        SignalingService.shared.onParticipantJoinedAudio = { [weak self] peerId in
             guard let self = self else { return }
             
             DispatchQueue.main.async {
                 
                 if !(self.participants.contains(peerId)) {
                     self.participants.append(peerId)
                 }
                 // 🔥 CREATE PEER
                 WebRTCManager.shared.createPeerConnection(for: peerId)
                 
                 // 🔥 IMPORTANT: EXISTING USER SEND OFFER
                 if self.isInCall {
                     WebRTCManager.shared.createOffer(for: peerId)
                 }
             }
         }
        
        // Someone left
        signaling.onParticipantLeftAudio = { [weak self] peerId in
            DispatchQueue.main.async {
                self?.participants.removeAll { $0 == peerId }
                self?.rtcManager.removePeer(peerId: peerId)
            }
        }
    }
    
    private func setupWebRTCListeners() {
        
        SignalingService.shared.onOfferReceived = { [weak self] from, sdp in
            
            self?.rtcManager.handleOffer(from: from, sdp: sdp)
        }
        
        SignalingService.shared.onAnswerReceived = { [weak self] from, sdp in
            
            self?.rtcManager.handleAnswer(from: from, sdp: sdp)
        }
        
        SignalingService.shared.onCandidateReceived = {  [weak self] from, candidate in
            
            self?.rtcManager.handleCandidate(from: from, candidate: candidate)
        }
    }

}

extension CallViewModel {
    
    func startCall() {
        guard isHost else { return }
        
        isCallActive = true
        isInCall = true
        
        participants = [SignalingService.shared.socketId]
        
        SignalingService.shared.startAudioCall(roomId: roomId)
        if !participants.contains(SignalingService.shared.socketId) {
            participants.append(SignalingService.shared.socketId)
        }
    }
    
    func endCall() {
        
        if isHost {
            // Host ends full room
            signaling.endAudioCall(roomId: roomId)
            rtcManager.endCall()
            resetCallState()
        } else {
            signaling.leaveAudioCall(roomId: roomId)
            rtcManager.endCall(for: signaling.socketId)
            isInCall = false
            participants.removeAll {
                $0 == SignalingService.shared.socketId
            }
        }
    }
    
    func joinCall() {
        guard isCallActive else { return }
        
        SignalingService.shared.joinAudioCall(roomId: roomId)
        
        isInCall = true
        
        if !participants.contains(SignalingService.shared.socketId) {
            participants.append(SignalingService.shared.socketId)
        }
    }
    
    func cleanupIfNeeded() {
        if !isInCall {
            WebRTCManager.shared.endCall()
        }
    }
    
    func resetCallState() {
        isCallActive = false
        isInCall = false
        participants.removeAll()
    }
}

extension CallViewModel {
    
    func toggleMute() {
        
        isMuted.toggle()
        WebRTCManager.shared.setMute(isMuted)
    }
    
    func toggleSpeaker() {
        
        isSpeakerOn.toggle()
        WebRTCManager.shared.setSpeaker(enabled: isSpeakerOn)
    }
}



