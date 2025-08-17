//
//  ContentView.swift
//  ScreenCaptureKitDemo
//
//  Created by Itsuki on 2025/07/29.
//

import SwiftUI

struct ContentView: View {
    // - 0: Screenshot
    // - 1: Screen Streaming / Capturing / Recording
    @AppStorage("selectedMode") var selectedMode: Int = 0

    var body: some View {
        NavigationStack {

            Group {
                switch self.selectedMode {
                case 0:
                    ScreenshotView()
                default:
                    ScreenCaptureView()
                }
            }
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction, content: {

                    Picker(selection: $selectedMode, content: {
                        Label("Screenshot", systemImage: "camera")
                            .tag(0)
                        
                        Label("Streaming/Recording", systemImage: "camera.metering.center.weighted")
                            .tag(1)
                        
                    }, label: {})
                    .labelsHidden()
                    .padding(.horizontal, 8)
                })
            })

        }
    }
}
