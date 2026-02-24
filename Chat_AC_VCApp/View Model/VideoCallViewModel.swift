//
//  VideoCallViewModel.swift
//  Chat_AC_VCApp
//

import Foundation
import Combine
import WebRTC
import SocketIO

final class VideoCallViewModel: ObservableObject {
    
    @Published var isVideoCallActive: Bool = false
    @Published var isInVideoCall: Bool = false
    @Published var videoParticipants: [String] = []
    @Published var isCameraOn: Bool = true
    @Published var isVideoMuted: Bool = false
    
    
    
    let signaling = SignalingService.shared
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
        signaling.$isVideoActive
                .receive(on: DispatchQueue.main)
                .assign(to: &$isVideoCallActive)

          
            signaling.onVideoCallEndedByHost = { [weak self] in
                DispatchQueue.main.async {
                    self?.isVideoCallActive = false
                    self?.isInVideoCall = false
                    
                }
            }
        signaling.onVideoCallStarted = { [weak self] _ in
            DispatchQueue.main.async {
                self?.isVideoCallActive = true
                self?.isInVideoCall = true
            }
        }
        
        
        signaling.onVideoCallEndedByHost = { [weak self] in
            DispatchQueue.main.async {
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
        signaling.UIStateChanged(id: roomId)
        isInVideoCall = true
        print("📤 Sending startMeeting request...")
     
        signaling.startRoom(id: roomId)
        
    }

    
    func joinCall() {
    
        signaling.joinRoom(id: roomId)
        print("yeh mere view model ka room id jo start par jata hai ",roomId )
        self.isInVideoCall = true
        
       
       
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

