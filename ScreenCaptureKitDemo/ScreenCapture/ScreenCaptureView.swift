//
//  ScreenCaptureView.swift
//  ScreenCaptureKitDemo
//
//  Created by Itsuki on 2025/07/27.
//

import SwiftUI
// @preconcurrency required to pass SCContentFilter out
@preconcurrency
import ScreenCaptureKit
import UniformTypeIdentifiers


struct ScreenCaptureView: View {
    
    @State private var screenCaptureManager = ScreenCaptureManager()

    var body: some View {
        HSplitView {
            ControlView()
                .environment(self.screenCaptureManager)
            
            Group {

                if let image = screenCaptureManager.previewImage, screenCaptureManager.isCapturing  {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                screenCaptureManager.stopCapture()
                            }, label: {
                                Text("Stop Capture")
                            })
                            
                            if screenCaptureManager.isRecording {
                                Button(action: {
                                    screenCaptureManager.enableFileOutput = false
                                }, label: {
                                    Text("Stop Recording")
                                })
                            }
                        }
                        
                        image
                            .resizable()
                            .scaledToFit()
                            .border(.white.opacity(0.3))
                            .overlay(alignment: .topTrailing, content: {
                                if screenCaptureManager.isRecording {
                                    Image(systemName: "record.circle")
                                        .font(.headline)
                                        .foregroundStyle(.red)
                                        .symbolEffect(.pulse)
                                        .padding(.all, 4)
                                }
                            })

                    }
                } else {
                    ContentUnavailableView("Start Capture for Previewing!", systemImage: "nosign")
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

        }
        .frame(minWidth: 800, minHeight: 520)
        .navigationTitle("Recoding/Streaming")
        .toolbarTitleDisplayMode(.inlineLarge)
    
    }
}


private struct ControlView: View {
    @Environment(ScreenCaptureManager.self) private var screenCaptureManager
    
    @State private var overlayManager = RectSelectionOverlayManager.shared

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        @Bindable var screenCaptureManager = self.screenCaptureManager
        
        VStack(alignment: .leading, spacing: 16) {
            title("⭐ Streaming Configuration")

            Group {
                
                Toggle(isOn: $screenCaptureManager.enableFileOutput, label: {
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("Save To Downloads")
                        Text("(Recording)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                })
                
                Toggle("Gray Scale", isOn: $screenCaptureManager.grayScale)
                
                Toggle("Exclude Current App", isOn: $screenCaptureManager.excludingCurrentApp)
                Toggle("Exclude Current App Audio", isOn: $screenCaptureManager.excludesCurrentProcessAudio)

                Toggle("Capture Audio", isOn: $screenCaptureManager.capturesAudio)
                Toggle("Capture Microphone", isOn: $screenCaptureManager.captureMicrophone)

                Toggle("Show Cursor", isOn: $screenCaptureManager.showsCursor)
                Toggle("Show Mouse Click", isOn: $screenCaptureManager.showMouseClicks)
            }
            
            Spacer()
                .frame(height: 16)
            
            title(!screenCaptureManager.isCapturing ? "⭐ Start Capture!" : "⭐ Configure Contents!")
            
            Group {
                Button(action: {
                    guard let window = NSApplication.shared.windows.first(where: {$0.identifier?.rawValue == RectSelectionOverlay.id}) else {
                        return
                    }
                    overlayManager.configureWindow(window)
                    openWindow(id: RectSelectionOverlay.id)

                }, label: {
                    Text("Rectangular Region")
                })
                .onChange(of: self.overlayManager.finished, {
                    guard self.overlayManager.finished else { return }
                    guard let rect = overlayManager.rect else {
                        return
                    }
                    screenCaptureManager.sourceRect = rect
                    if !screenCaptureManager.isCapturing {
                        screenCaptureManager.startCapture()
                    }
                })
                
                Button(action: {
                    screenCaptureManager.presentPicker()
                }, label: {
                    Text("Select Content Filters")
                })
            }
        }
        .padding()
        .frame(width: 248, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.gray.opacity(0.1))
        .onAppear {
            if NSApplication.shared.windows.first(where: {$0.identifier?.rawValue == RectSelectionOverlay.id}) == nil {
                // window is not created and configured yet
                openWindow(id: RectSelectionOverlay.id)
            }
           
        }
    }
    
    
    private func title(_ string: String) -> some View {
        Text(string)
            .font(.headline)
            .foregroundColor(.secondary)
            .alignmentGuide(.leading) { _ in 16.0 }

    }
}
