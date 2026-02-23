//
//  VideoCallViewModel.swift
//  Chat_AC_VCApp
//

import Foundation
import Combine
import WebRTC

final class VideoCallViewModel: ObservableObject {
    
    @Published var isVideoCallActive: Bool = false
    @Published var isInVideoCall: Bool = false
    @Published var videoParticipants: [String] = []
    @Published var isCameraOn: Bool = true
    @Published var isVideoMuted: Bool = false
    
    
    
    private let signaling = SignalingService.shared
    private let rtcManager = WebRTCManager.shared
    
    var roomId: String
    @Published var isHost: Bool
    
    init(roomId: String, isHost: Bool) {
        self.roomId = roomId
        self.isHost = isHost
        
        setupCallbacks()
    }
}

//MARK: signling and WebRTC handler

private extension VideoCallViewModel {
    
    func setupCallbacks() {
        
        
        signaling.onVideoCallStarted = { [weak self] in
            DispatchQueue.main.async {
                self?.isVideoCallActive = true
            }
        }
        
        
        signaling.onVideoCallEndedByHost = { [weak self] in
            DispatchQueue.main.async {
                self?.rtcManager.endAllConnections()
                self?.resetCallState()
            }
        }
        
        signaling.onParticipantJoinedVideoForUI = { [weak self] peerId in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if !self.videoParticipants.contains(peerId) {
                        self.videoParticipants.append(peerId)
                    }
                }
            }
        
        signaling.onParticipantLeftVideo = { [weak self] peerId in
            DispatchQueue.main.async {
                self?.videoParticipants.removeAll { $0 == peerId }
            }
        }
    }
}

//MARK: Video Functionalities

extension VideoCallViewModel {
    
    func startCall() {
        
        guard isHost else { return }
        
        isVideoCallActive = true
        isInVideoCall = true
        
        let selfId = signaling.socketId
        
        if !videoParticipants.contains(selfId) {
            videoParticipants.append(selfId)
        }
        
        rtcManager.startLocalMedia()
        
        print(" TRYING TO START VIDEO CALL")
        signaling.startVideoCall(roomId: roomId)
    }

    
    func joinCall() {
        guard isVideoCallActive else { return }
        
        isInVideoCall = true
        
        let selfId = signaling.socketId
        
        if !videoParticipants.contains(selfId) {
            videoParticipants.append(selfId)
        }
        
        rtcManager.startLocalMedia()

        print(" Joining video call")
        signaling.joinVideoCall(roomId: roomId)
    }
    
    func endCall() {
        
        if isHost {
            signaling.endVideoCall(roomId: roomId)
            rtcManager.endAllConnections()
            resetCallState()
        } else {
            signaling.leaveVideoCall(roomId: roomId)
            isInVideoCall = false
            rtcManager.endAllConnections()
            videoParticipants.removeAll { $0 == signaling.socketId }
        }
    }
    
    private func resetCallState() {
        isVideoCallActive = false
        isInVideoCall = false
        videoParticipants.removeAll()
    }
    
    func toggleCamera() {
        isCameraOn.toggle()
        rtcManager.setVideoEnabled(isCameraOn)
    }
    
    func toggleVideoMute() {
        isVideoMuted.toggle()
        rtcManager.setMute(isVideoMuted)
    }
}


