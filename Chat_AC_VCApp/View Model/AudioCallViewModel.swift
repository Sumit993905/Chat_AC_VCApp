//
//  CallViewModel.swift
//  Chat_AC_VCApp
//

import Foundation
import Combine
import WebRTC

final class AudioCallViewModel: ObservableObject {
    
    
    //MARK: - For Audio
    @Published var isAudioCallActive: Bool = false
    @Published var isInAudioCall: Bool = false
    @Published var audioParticipants: [String] = []
    @Published var isAudioMuted: Bool = false
    @Published var isSpeakerOn: Bool = true
    
        
    
    private let signaling = SignalingService.shared
    private let rtcManager = WebRTCManager.shared
    
    var roomId: String
    @Published var isHost: Bool = false
    
    
    
    init(roomId: String, isHost: Bool) {
        self.roomId = roomId
        self.isHost = isHost
        setupCallbacks()
        setupWebRTCListeners()
    }
}


private extension AudioCallViewModel {
    
    func setupCallbacks() {
        
        
        signaling.onAudioCallStarted = { [weak self] in
            DispatchQueue.main.async {
                self?.isAudioCallActive = true
            }
        }
        
        
        signaling.onAudioCallEndedByHost = { [weak self] in
            DispatchQueue.main.async {
                self?.resetCallState()
            }
        }
        
        
        SignalingService.shared.onParticipantJoinedAudio = { [weak self] peerId in
             guard let self = self else { return }
             
             DispatchQueue.main.async {
                 
                 if !(self.audioParticipants.contains(peerId)) {
                     self.audioParticipants.append(peerId)
                 }
                 
                 WebRTCManager.shared.createPeerConnection(for: peerId)
                 
                 
                 if self.isInAudioCall {
                     WebRTCManager.shared.createOffer(for: peerId)
                 }
             }
         }
        
        
        signaling.onParticipantLeftAudio = { [weak self] peerId in
            DispatchQueue.main.async {
                self?.audioParticipants.removeAll { $0 == peerId }
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

extension AudioCallViewModel {
    
    func startCall() {
        guard isHost else { return }
        
        isAudioCallActive = true
        isInAudioCall = true
        
        audioParticipants = [SignalingService.shared.socketId]
        
        
        rtcManager.startLocalMedia()
        SignalingService.shared.startAudioCall(roomId: roomId)
        
        if !audioParticipants.contains(SignalingService.shared.socketId) {
            audioParticipants.append(SignalingService.shared.socketId)
        }
    }
    
    func endCall() {
        
        if isHost {
            signaling.endAudioCall(roomId: roomId)
            rtcManager.endCall()
            resetCallState()
        } else {
            signaling.leaveAudioCall(roomId: roomId)
            rtcManager.endCall(for: signaling.socketId)
            isInAudioCall = false
            audioParticipants.removeAll {
                $0 == SignalingService.shared.socketId
            }
        }
    }
    
    func joinCall() {
        guard isAudioCallActive else { return }
        
        rtcManager.startLocalMedia()
        SignalingService.shared.joinAudioCall(roomId: roomId)
        
        isInAudioCall = true
        
        if !audioParticipants.contains(SignalingService.shared.socketId) {
            audioParticipants.append(SignalingService.shared.socketId)
        }
    }
    
    func cleanupIfNeeded() {
        if !isInAudioCall {
            WebRTCManager.shared.endCall()
        }
    }
    
    func resetCallState() {
        isAudioCallActive = false
        isInAudioCall = false
        audioParticipants.removeAll()
    }
}

extension AudioCallViewModel {
    
    func toggleMute() {
        
        isAudioMuted.toggle()
        WebRTCManager.shared.setMute(isAudioMuted)
    }
    
    func toggleSpeaker() {
        
        isSpeakerOn.toggle()
        WebRTCManager.shared.setSpeaker(enabled: isSpeakerOn)
    }
}



