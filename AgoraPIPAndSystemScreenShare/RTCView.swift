//
//  RTCView.swift
//  AgoraPIPAndSystemScreenShare
//
//  Created by shaun on 1/11/23.
//

import AVKit
import SwiftUI
import AgoraRtcKit
import OSLog

private let logger = Logger(subsystem: "io.agora.AgoraPIPAndSystemScreenShare", category: "RTCView")

struct RTCView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController
    
    @EnvironmentObject private var rtcManager: RTCManager
    let uid: UInt

    func makeUIViewController(context: Context) -> UIViewController {
        if rtcManager.pipUid(uid) {
            let pipvc = RTCPIPViewController()
            pipvc.uid = uid
            pipvc.rtcManager = rtcManager
            return pipvc
        }
        
        let vc = RTCViewController()
        vc.uid = uid
        vc.rtcManager = rtcManager
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // noop
        logger.info("Update controller \(uiViewController) \(uid)")
    }
}

private class RTCViewController: UIViewController {
    var rtcManager: RTCManager? = nil
    var uid: UInt = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rtcManager?.setupCanvasFor(view, uid)
    }
    
}

private class RTCPIPViewController: UIViewController {
    private var pipController: AVPictureInPictureController!
    private var displayView = AgoraSampleBufferRenderer()
    var rtcManager: RTCManager?
    var uid: UInt = 0

    private var didBecomeActiveObserver: NSObjectProtocol?
    private var didBecomeInactiveObserver: NSObjectProtocol?
    
    override func loadView() {
        super.loadView()
        displayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(displayView)
        
        NSLayoutConstraint.activate([
            displayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            displayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            displayView.topAnchor.constraint(equalTo: view.topAnchor),
            displayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        rtcManager?.engine.setVideoFrameDelegate(self)
        
        didBecomeActiveObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.pipController.stopPictureInPicture()
            self?.displayView.reset()
            logger.info("Stoped PIP")
        }
            
        didBecomeInactiveObserver = NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.pipController.startPictureInPicture()
            logger.info("Started PIP")
        }
        
        setupPictureInPicture()
    }

    // from the apple docs https://developer.apple.com/documentation/avkit/adopting_picture_in_picture_in_a_custom_player/
    func setupPictureInPicture() {
        if AVPictureInPictureController.isPictureInPictureSupported() {
            let pipSource = AVPictureInPictureController.ContentSource(sampleBufferDisplayLayer: displayView.displayLayer, playbackDelegate: self)
            pipController = AVPictureInPictureController(contentSource: pipSource)
            // Needed for PIP
            let avSession = AVAudioSession.sharedInstance()
            try? avSession.setCategory(.playback)
        }
    }
}

extension RTCPIPViewController: AgoraVideoFrameDelegate {
    func onCapture(_ videoFrame: AgoraOutputVideoFrame) -> Bool {
        return true
    }
    
    func onRenderVideoFrame(_ videoFrame: AgoraOutputVideoFrame, uid: UInt, channelId: String) -> Bool {
        guard uid == self.uid else { return false }
        displayView.renderVideoPixelBuffer(videoData: videoFrame)
        return true
    }
    
    
    func getVideoFormatPreference() -> AgoraVideoFormat {
        return .cvPixelI420
    }
}

extension RTCPIPViewController: AVPictureInPictureSampleBufferPlaybackDelegate {
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {
    }
    
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime) async {
    }
    
    func pictureInPictureControllerShouldProhibitBackgroundAudioPlayback(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        return false
    }
    
    func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        return false
    }
    
    func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        return CMTimeRange(start: .zero, end: CMTimeMake(value: Int64.max, timescale: 1000))
    }
}

private class AgoraSampleBufferRenderer: UIView {
    // NOTE: change the following if the frame rate changes to for smoother video use in call stats to monitor frame rate and adjust this
    var frameRate: Int32 = 30
    private var frameCount: Int = 0
    private var videoWidth: Int32 = 0
    private var videoHeight: Int32 = 0
    var displayLayer = AVSampleBufferDisplayLayer()
    
    required init?(coder: NSCoder) {
        fatalError("NYI")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(displayLayer)
        self.clipsToBounds = true
        
        var controlTimebase: CMTimebase!
        CMTimebaseCreateWithSourceClock(allocator: kCFAllocatorDefault, sourceClock: CMClockGetHostTimeClock(), timebaseOut: &controlTimebase)
        displayLayer.controlTimebase = controlTimebase
        CMTimebaseSetTime(displayLayer.controlTimebase!, time: .zero)
        CMTimebaseSetRate(displayLayer.controlTimebase!, rate: 1.0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutDisplayLayer()
    }
    
    @MainActor
    private func layoutDisplayLayer() {
        guard videoWidth > 0 && videoHeight > 0 && self.frame.size != .zero else { return }

        let viewWidth = frame.size.width
        let viewHeight = frame.size.height
        
        let videoRatio = CGFloat(videoWidth)/CGFloat(videoHeight)
        let viewRatio = viewWidth/viewHeight
        
        let videoSize: CGSize
        if (videoRatio >= viewRatio) {
            videoSize = CGSize(width: viewHeight * videoRatio, height: viewHeight)
        } else {
            videoSize = CGSize(width: viewWidth, height: viewWidth / videoRatio)
        }
        
        let displayRect = CGRect(
            x: 0.5 * (viewWidth - videoSize.width),
            y: 0.5 * (viewHeight - videoSize.height),
            width: videoSize.width,
            height: videoSize.height
        )
        
        if displayRect != self.displayLayer.frame {
            self.displayLayer.frame = displayRect
        }
    }
    
    
    func reset() {
        self.displayLayer.flushAndRemoveImage()
    }
    
    func renderVideoPixelBuffer(videoData: AgoraOutputVideoFrame) {
        guard let pixelBuffer = videoData.pixelBuffer else { return logger.error("failed to get pixelbuffer from video frame") }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        if width != videoWidth && videoHeight != height {
            Task {
                videoWidth = Int32(width)
                videoHeight = Int32(height)
                layoutDisplayLayer()
            }
        }
        var videoInfo: CMVideoFormatDescription! = nil
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &videoInfo)

        var timingInfo: CMSampleTimingInfo = CMSampleTimingInfo()
        timingInfo.duration = .zero
        timingInfo.decodeTimeStamp = .invalid
        defer { frameCount += 1 }
        timingInfo.presentationTimeStamp = CMTimeAdd(.zero, CMTimeMake(value: Int64(frameCount), timescale: frameRate))
                
        var sampleBuffer: CMSampleBuffer! = nil
        CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescription: videoInfo, sampleTiming: &timingInfo, sampleBufferOut: &sampleBuffer)
        
        displayLayer.enqueue(sampleBuffer)
        
        CMSampleBufferInvalidate(sampleBuffer)
                
    }
}

