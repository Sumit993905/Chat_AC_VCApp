//
//  WebRTCClient.swift
//  Chat_AC_VCApp
//
//  Created by Sumit Raj Chingari on 17/02/26.
//

import Foundation
import WebRTC
import AVFoundation

// MARK: - Delegate

protocol WebRTCClientDelegate: AnyObject {
    
    func webRTCClient(_ client: WebRTCClient,
                      didDiscoverLocalCandidate candidate: RTCIceCandidate,
                      for peerId: String)

    func webRTCClient(_ client: WebRTCClient,
                      didReceiveRemoteVideoTrack track: RTCVideoTrack,
                      for peerId: String)

    func webRTCClient(_ client: WebRTCClient,
                      didChangeConnectionState state: RTCIceConnectionState,
                      for peerId: String)
}

// MARK: - WebRTCClient

final class WebRTCClient: NSObject {

    weak var delegate: WebRTCClientDelegate?

    private let peerId: String

    private let factory: RTCPeerConnectionFactory
    private var peerConnection: RTCPeerConnection!

    private var localAudioTrack: RTCAudioTrack?
    private var localVideoTrack: RTCVideoTrack?
    private var capturer: RTCCameraVideoCapturer?

    

    init(peerId: String) {

        self.peerId = peerId

        RTCInitializeSSL()
        self.factory = RTCPeerConnectionFactory()

        super.init()

        self.createPeerConnection()
    }

    // MARK: - Peer Connection Setup

    private func createPeerConnection() {

        let config = RTCConfiguration()
        config.sdpSemantics = .unifiedPlan
        config.iceServers = [
            RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
        ]
        config.continualGatheringPolicy = .gatherContinually

        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: [
                "DtlsSrtpKeyAgreement": "true",
                "RtpDataChannels": "true"
            ]
        )

        peerConnection = factory.peerConnection(
            with: config,
            constraints: constraints,
            delegate: self
        )
    }
}


// MARK: - For Audio

extension WebRTCClient {

    func startLocalAudio() {

        let audioConstraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: [
                "googEchoCancellation": "true",
                "googAutoGainControl": "true",
                "googNoiseSuppression": "true",
                "googHighpassFilter": "true"
            ]
        )

        let audioSource = factory.audioSource(with: audioConstraints)

        localAudioTrack = factory.audioTrack(
            with: audioSource,
            trackId: "audio0"
        )

        if let audioTrack = localAudioTrack {
            peerConnection.add(audioTrack, streamIds: ["stream0"])
        }
        configureAudioSession()
    }
    
 

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord,
                                 options: [AVAudioSession.CategoryOptions.allowBluetoothHFP, .defaultToSpeaker])
        try? session.setMode(.voiceChat)
        try? session.setActive(true)
    }

    func setMute(_ isMuted: Bool) {
        localAudioTrack?.isEnabled = !isMuted
    }

    func setSpeaker(enabled: Bool) {
        let session = AVAudioSession.sharedInstance()
        try? session.overrideOutputAudioPort(enabled ? .speaker : .none)
    }
}

// MARK: - For Video

extension WebRTCClient {

    func startLocalVideo() {

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }
        
        let videoSource = factory.videoSource()
        self.capturer = RTCCameraVideoCapturer(delegate: videoSource)
        
        localVideoTrack = factory.videoTrack(with: videoSource, trackId: "video0")
        
        if let track = localVideoTrack {
            peerConnection.add(track, streamIds: ["stream0"])
        }
        
        let formats = RTCCameraVideoCapturer.supportedFormats(for: device)
        
        let targetWidth = 640
        let targetHeight = 480
        
        var selectedFormat: AVCaptureDevice.Format? = nil
        var currentDiff = Int.max
        
        for format in formats {
            let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let diff = abs(Int(dimension.width) - targetWidth) + abs(Int(dimension.height) - targetHeight)
            if diff < currentDiff {
                selectedFormat = format
                currentDiff = diff
            }
        }
        
        if let format = selectedFormat {
            let fps = 30
            print("✅ Starting Camera: \(CMVideoFormatDescriptionGetDimensions(format.formatDescription)) at \(fps)fps")
            self.capturer?.startCapture(with: device, format: format, fps: fps)
        } else {
            print("❌ Could not find a suitable camera format.")
        }
    }
    
    func getLocalVideoTrack() -> RTCVideoTrack? {
        return localVideoTrack
    }
    
    
    func setVideoEnabled(_ enabled: Bool) {
        localVideoTrack?.isEnabled = enabled
    }
}

// MARK: - For Delegate

extension WebRTCClient {

    func createOffer(completion: @escaping (RTCSessionDescription) -> Void) {

        let constraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "OfferToReceiveAudio": "true",
                "OfferToReceiveVideo": "true"
            ],
            optionalConstraints: nil
        )

        peerConnection.offer(for: constraints) { sdp, _ in
            guard let sdp = sdp else { return }
            self.peerConnection.setLocalDescription(sdp) { _ in }
            completion(sdp)
        }
    }

    func createAnswer(completion: @escaping (RTCSessionDescription) -> Void) {

        peerConnection.answer(
            for: RTCMediaConstraints(mandatoryConstraints: nil,
                                     optionalConstraints: nil)
        ) { sdp, _ in
            guard let sdp = sdp else { return }
            self.peerConnection.setLocalDescription(sdp) { _ in }
            completion(sdp)
        }
    }

    func setRemoteDescription(_ sdp: RTCSessionDescription) {
        peerConnection.setRemoteDescription(sdp) { _ in }
    }

    func addIceCandidate(_ candidate: RTCIceCandidate) {
        peerConnection.add(candidate){ error in
            if let error = error {
                print("Error adding candidate: \(error)")
            }
        }
    }

    func endCall() {
        capturer?.stopCapture()
        peerConnection.close()
    }
}


extension WebRTCClient: RTCPeerConnectionDelegate {

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didGenerate candidate: RTCIceCandidate) {

        delegate?.webRTCClient(self,
                               didDiscoverLocalCandidate: candidate,
                               for: peerId)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didAdd rtpReceiver: RTCRtpReceiver,
                        streams: [RTCMediaStream]) {

        if let track = rtpReceiver.track as? RTCVideoTrack {
            delegate?.webRTCClient(self,
                                   didReceiveRemoteVideoTrack: track,
                                   for: peerId)
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange stateChanged: RTCIceConnectionState) {

        delegate?.webRTCClient(self,
                               didChangeConnectionState: stateChanged,
                               for: peerId)
    }

    // Required Empty Methods

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange newState: RTCSignalingState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didAdd stream: RTCMediaStream) {}
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didOpen dataChannel: RTCDataChannel) {}
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didRemove stream: RTCMediaStream) {}
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange newState: RTCIceGatheringState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didRemove candidates: [RTCIceCandidate]) {}
}


