import SwiftUI
import WebRTC

struct VideoRendererView: UIViewRepresentable {

    let track: RTCVideoTrack

    func makeUIView(context: Context) -> RTCMTLVideoView {
        let view = RTCMTLVideoView()
        view.videoContentMode = .scaleAspectFill
        view.backgroundColor = .black

        track.add(view)   
        return view
    }

    func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {
        // do nothing
    }

    static func dismantleUIView(_ uiView: RTCMTLVideoView, coordinator: ()) {
        // cleanup
    }
}
