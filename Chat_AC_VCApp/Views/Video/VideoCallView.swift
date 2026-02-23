//
//  VideoCallView.swift
//  Chat_AC_VCApp
//
//  Created by Sumit Raj Chingari on 18/02/26.
//

import SwiftUI
import WebRTC


struct VideoCallView: View {
    
    @ObservedObject var viewModel: VideoCallViewModel
    @ObservedObject var rtcManager = WebRTCManager.shared
    @EnvironmentObject var userArray: UserArray
    
    var body: some View {
        
        ZStack {
            
            Color.black.ignoresSafeArea()
            
            VStack {
                
                LazyVGrid(columns: gridLayout, spacing: 8) {
                    
                    // Local Video
                    if rtcManager.localVideoTrack != nil {
                        VideoTileView(
                            peerId: SignalingService.shared.socketId,
                            isLocal: true
                        )
                        .id("local-video")
                    }
                    
                    //  Remote Videos (Sorted for stability)
                    ForEach(rtcManager.remoteTracks.keys.sorted(), id: \.self) { peerId in
                        
                        VideoTileView(
                            peerId: peerId,
                            isLocal: false
                        )
                        .id(peerId)
                    }
                }
                .padding(8)
                
                Spacer()
                
                controls
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    var gridLayout: [GridItem] {
        
        let total = 1 + rtcManager.remoteTracks.count
        print("Remote track count : \(rtcManager.remoteTracks.count)")
        
        let columns = total <= 1 ? 1 : 2
        
        return Array(
            repeating: GridItem(.flexible(), spacing: 8),
            count: columns
        )
    }
}


private extension VideoCallView {
    
    var controls: some View {
        
        HStack(spacing: 30) {
            
            circleButton(
                icon: viewModel.isVideoMuted ? "mic.slash.fill" : "mic.fill",
                color: .gray
            ) {
                self.viewModel.toggleVideoMute()
            }
            
            circleButton(
                icon: "phone.down.fill",
                color: .red
            ) {
                viewModel.endCall()
            }

            
            circleButton(
                icon: viewModel.isCameraOn ? "video.fill" : "video.slash.fill",
                color: .gray
            ) {
                viewModel.toggleCamera()
            }
        
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .padding(.bottom, 30)
    }
    
    
    func circleButton(icon: String,
                      color: Color,
                      action: @escaping () -> Void) -> some View {
        
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(color)
                .clipShape(Circle())
        }
    }
}


struct VideoTileView: View {

    let peerId: String
    let isLocal: Bool

    var body: some View {

        ZStack(alignment: .bottomLeading) {

            if isLocal {
                if let track = WebRTCManager.shared.localVideoTrack {
                    VideoRendererView(track: track)
                        .id("local")
                }
            } else {
                if let track = WebRTCManager.shared.remoteTracks[peerId] {
                    VideoRendererView(track: track)
                        .id(peerId)
                }
            }

            Text(displayName)
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.black.opacity(0.6))
                .foregroundColor(.white)
                .clipShape(Capsule())
                .padding(8)
        }
        .aspectRatio(1, contentMode: .fill)
        .background(Color.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var displayName: String {
        isLocal ? "You" : peerId.prefix(6) + "..."
    }
}




