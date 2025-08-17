//
//  ScreenCaptureKitDemoApp.swift
//  ScreenCaptureKitDemo
//
//  Created by Itsuki on 2025/07/22.
//

import SwiftUI

@main
struct ScreenCaptureKitDemoApp: App {
    var body: some Scene {

        WindowGroup {
            ContentView()
//            ScreenCaptureView()
//            MinimumScreenCaptureDemo()
//            ObservableTestView()
        }
        
        // For selecting a region on the screen to capture
        // (either screenshot, or streaming/recording)
        Window("", id: RectSelectionOverlay.id, content: {
            RectSelectionOverlay()
        })

    }
}
