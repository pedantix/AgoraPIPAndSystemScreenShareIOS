//
//  VideoView.swift
//  AgoraPIPAndSystemScreenShare
//
//  Created by shaun on 1/11/23.
//

import SwiftUI

struct VideoView: View {
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    let uid: UInt
    @EnvironmentObject var rtcManager: RTCManager
    
    var body: some View {
        RTCView(uid: uid)
            .background(.cyan)
            .frame(width: screenWidth, height: screenHeight)
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView(uid: 1)
    }
}
