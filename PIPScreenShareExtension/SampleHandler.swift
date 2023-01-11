//
//  SampleHandler.swift
//  PIPScreenShareExtension
//
//  Created by shaun on 1/11/23.
//

import Foundation
import CoreMedia
import ReplayKit
import AgoraRtcKit

class SampleHandler: RPBroadcastSampleHandler {

    var bufferCopy: CMSampleBuffer?
    var lastSendTs: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    var timer: Timer?


    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        if let setupInfo = setupInfo, let channel = setupInfo["sigh"] as? String {
            // In-App Screen Capture
            screenSharingAgoraEngine.startScreenSharing(to: channel)
        } else {
            // iOS Screen Record and Broadcast
            // IMPORTANT
            // You have to use App Group to pass information/parameter
            // from main app to extension
            // in this demo we don't introduce app group as it increases complexity
            // this is the reason why channel name is hardcoded to be ScreenShare
            // You may use a dynamic channel name through keychain or userdefaults
            // after enable app group feature
            screenSharingAgoraEngine.startScreenSharing(to: "sigh")
        }
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {[weak self] (timer: Timer) in
                guard let weakSelf = self else {return}
                let elapse = Int64(Date().timeIntervalSince1970 * 1000) - weakSelf.lastSendTs
                print("elapse: \(elapse)")
                // if frame stopped sending for too long time, resend the last frame
                // to avoid stream being frozen when viewed from remote
                if elapse > 300 {
                    if let buffer = weakSelf.bufferCopy {
                        weakSelf.processSampleBuffer(buffer, with: .video)
                    }
                }
            }
        }
    }


     override func broadcastPaused() {
         // User has requested to pause the broadcast. Samples will stop being delivered.
     }

     override func broadcastResumed() {
         // User has requested to resume the broadcast. Samples delivery will resume.
     }

     override func broadcastFinished() {
         timer?.invalidate()
         timer = nil
         screenSharingAgoraEngine.stopScreenSharing()
     }

     override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
         DispatchQueue.main.async {[weak self] in
             switch sampleBufferType {
             case .video:
                 if let weakSelf = self {
                     weakSelf.bufferCopy = sampleBuffer
                     weakSelf.lastSendTs = Int64(Date().timeIntervalSince1970 * 1000)
                 }
                 screenSharingAgoraEngine.sendVideoBuffer(sampleBuffer)
             case .audioApp:
                 screenSharingAgoraEngine.sendAudioAppBuffer(sampleBuffer)
                 break
             case .audioMic:
                 screenSharingAgoraEngine.sendAudioMicBuffer(sampleBuffer)
                 break
             @unknown default:
                 break
             }
         }
     }

}


class screenSharingAgoraEngine {
    private static let appID = API.agoraAppID
    
    private static let  channelName = "test"

    private static let agoraEngine: AgoraRtcEngineKit = {

        let config = AgoraRtcEngineConfig()
        config.appId = appID
        config.channelProfile = .liveBroadcasting
        let agoraEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: nil)

        agoraEngine.enableVideo()
        agoraEngine.setExternalVideoSource(true, useTexture: true, sourceType: .videoFrame)
        let videoConfig = AgoraVideoEncoderConfiguration(size: videoDimension,
                                                         frameRate: .fps10,
                                                         bitrate: AgoraVideoBitrateStandard,
                                                         orientationMode: .adaptative, mirrorMode: .auto)
        agoraEngine.setVideoEncoderConfiguration(videoConfig)

        agoraEngine.setAudioProfile(.default)
        agoraEngine.setExternalAudioSource(true, sampleRate: Int(audioSampleRate), channels: Int(audioChannels))
        agoraEngine.muteAllRemoteVideoStreams(true)
        agoraEngine.muteAllRemoteAudioStreams(true)
        return agoraEngine
    }()


    // Set the audio configuration
    private static let audioSampleRate: UInt = 44100
    private static let audioChannels: UInt = 2


    // Get the screen size and orientation
    private static let videoDimension: CGSize = {
        let screenSize = UIScreen.main.currentMode!.size
        var boundingSize = CGSize(width: 540, height: 980)
        let mW = boundingSize.width / screenSize.width
        let mH = boundingSize.height / screenSize.height
        if mH < mW {
            boundingSize.width = boundingSize.height / screenSize.height * screenSize.width
        } else if mW < mH {
            boundingSize.height = boundingSize.width / screenSize.width * screenSize.height
        }
        return boundingSize
    }()


    //Configure agoraEngine to use custom video with no audio, then join the channel.
    static func startScreenSharing(to channel: String) {

        let channelMediaOptions = AgoraRtcChannelMediaOptions()
        channelMediaOptions.publishMicrophoneTrack = false
        channelMediaOptions.publishCameraTrack = false
        channelMediaOptions.publishCustomVideoTrack = true
        channelMediaOptions.publishCustomAudioTrack = true
        channelMediaOptions.autoSubscribeAudio = false
        channelMediaOptions.autoSubscribeVideo = false
        channelMediaOptions.clientRoleType = .broadcaster

        agoraEngine.joinChannel(byToken: .none, channelId: channelName, uid: UInt(1001), mediaOptions: channelMediaOptions, joinSuccess: nil)
    }


    // Leave the channel
    static func stopScreenSharing() {
        agoraEngine.leaveChannel(nil)
        AgoraRtcEngineKit.destroy()
    }


    //Retrieve the local video frame, figure out the orientation and duration of the buffer and send it to the chnanel.
    static func sendVideoBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer)
        else {
        return
        }

        var rotation: Int32 = 0
        if let orientationAttachment = CMGetAttachment(sampleBuffer, key: RPVideoSampleOrientationKey as CFString, attachmentModeOut: nil) as? NSNumber {
            if let orientation = CGImagePropertyOrientation(rawValue: orientationAttachment.uint32Value) {
                switch orientation {
                case .up,    .upMirrored:    rotation = 0
                case .down,  .downMirrored:  rotation = 180
                case .left,  .leftMirrored:  rotation = 90
                case .right, .rightMirrored: rotation = 270
                default:   break
                }
            }
        }
        let time = CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 1000 * 1000)

        let frame = AgoraVideoFrame()
        frame.format = 12
        frame.time = time
        frame.textureBuf = videoFrame
        frame.rotation = rotation
        agoraEngine.pushExternalVideoFrame(frame)
    }

    // To extend the functionality
    static func sendAudioAppBuffer(_ sampleBuffer: CMSampleBuffer) {

    }

    // Audio is blocked, do nothing
    static func sendAudioMicBuffer(_ sampleBuffer: CMSampleBuffer) {

    }
}
