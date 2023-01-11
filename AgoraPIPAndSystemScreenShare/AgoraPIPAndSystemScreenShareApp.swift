//
//  AgoraPIPAndSystemScreenShareApp.swift
//  AgoraPIPAndSystemScreenShare
//
//  Created by shaun on 1/11/23.
//

import SwiftUI

@main
struct AgoraPIPAndSystemScreenShareApp: App {
    @StateObject var rtcManager = RTCManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(rtcManager)
        }
    }
}
