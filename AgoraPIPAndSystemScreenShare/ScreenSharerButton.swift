//
//  ScreenSharerButton.swift
//  AgoraPIPAndSystemScreenShare
//
//  Created by shaun on 1/11/23.
//
import SwiftUI
import ReplayKit

struct ScreenSharerButton: UIViewRepresentable {
    typealias UIViewType = UIView
    
    func makeUIView(context: Context) -> UIView {
        let view = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        
        view.autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin]
        
        if let url = Bundle.main.url(forResource: "PIPScreenShareExtension", withExtension: "appex", subdirectory: "PlugIns") {
            if let bundle = Bundle(url: url) {
                view.preferredExtension = bundle.bundleIdentifier
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // noop
    }
}
