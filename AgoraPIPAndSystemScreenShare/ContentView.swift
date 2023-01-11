//
//  ContentView.swift
//  AgoraPIPAndSystemScreenShare
//
//  Created by shaun on 1/11/23.
//

import SwiftUI
import OSLog
let viewLogger = Logger(subsystem: "io.agora.AgoraPIPAndSystemScreenShare", category: "View")
struct ContentView: View {
    @EnvironmentObject var rtcManager: RTCManager
    
    var body: some View {
        if rtcManager.myUid == 0 {
            Text("Not setup yet")
        } else {
            ZStack {
                videoViews
                ScreenSharerButton().frame(width: 60, height: 60)
            }
        }
    }
        
    private var videoViews: some View {
        List {
            
            ForEach(rtcManager.sortedUids, id: \.self) {
                VideoView(uid: $0)
                    .listRowSeparator(.hidden)
            }
            
            
            VideoView(uid: rtcManager.myUid)
                .listRowSeparator(.hidden)
        }.listStyle(.plain)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
