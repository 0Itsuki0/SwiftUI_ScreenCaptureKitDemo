//
//  ScreenshotView.swift
//  ScreenCaptureKitDemo
//
//  Created by Itsuki on 2025/07/22.
//

import SwiftUI
// @preconcurrency required to pass SCContentFilter out
@preconcurrency
import ScreenCaptureKit


struct ScreenshotView: View {
    
    @State private var screenshotManager: ScreenshotManager = ScreenshotManager()

    var body: some View {
        HSplitView {
            ControlView()
                .environment(self.screenshotManager)
            
            Group {
                if let cgImage = screenshotManager.cgImage {
                    cgImage.image
                        .resizable()
                        .scaledToFit()
                        .border(.white.opacity(0.3))
                        .overlay(alignment: .topTrailing, content: {
                            if let outputURL = screenshotManager.outputURL {
                                Button(action: {
                                    let dateFormatter = DateFormatter()
                                    dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                                    let currentDateTime = dateFormatter.string(from: Date())
                                    let imageUrl = outputURL.appendingPathComponent("screenshot-\(currentDateTime)", conformingTo: screenshotManager.fileOutputType)
                                    do {
                                        try cgImage.data?.write(to: imageUrl)
                                    } catch (let error) {
                                        print(error)
                                    }
                                    
                                    
                                }, label: {
                                    Image(systemName: "arrow.down.to.line")
                                })
                            }
                        })
                } else {
                    ContentUnavailableView("No Screenshots Yet!", systemImage: "nosign")

                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

        }
        .frame(minWidth: 800, minHeight: 520)
        .navigationTitle("ScreenShot")
        .toolbarTitleDisplayMode(.inlineLarge)
    
    }
}


private struct ControlView: View {
    @Environment(ScreenshotManager.self) private var screenshotManager
    
    @State private var overlayManager = RectSelectionOverlayManager.shared
    
    @State private var showSelectPresetSheet: Bool = false
    
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        @Bindable var screenshotManager = self.screenshotManager
        
        VStack(alignment: .leading, spacing: 16) {
            title("⭐ Screenshot Configuration")

            Group {
                Toggle("Auto Save To Downloads", isOn: $screenshotManager.enableFileOutput)
                
                if screenshotManager.enableFileOutput {
                    Picker("File Format", selection: $screenshotManager.fileOutputType) {
                        ForEach(0..<SCScreenshotConfiguration.supportedContentTypes.count, id: \.self) { index in
                            let utType: UTType = SCScreenshotConfiguration.supportedContentTypes[index]
                            Text(utType.preferredFilenameExtension ?? utType.identifier)
                                .tag(utType)
                        }
                    }
                    .padding(.leading, 16)
                }
                
                Toggle("Ignore Clipping", isOn: $screenshotManager.ignoreClipping)
                Toggle("Ignore Shadows", isOn: $screenshotManager.ignoreShadows)
                Toggle("Include Child Windows", isOn: $screenshotManager.includeChildWindows)
                Toggle("Show Cursor", isOn: $screenshotManager.showsCursor)

            }
            
            Spacer()
                .frame(height: 16)
            
            title("⭐ Take ScreenShot!")
            
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
                    screenshotManager.captureScreenshot(rect)
                })
                
                Button(action: {
                    self.showSelectPresetSheet = true
                }, label: {
                    Text("Preset Content Filters")
                })
                
                Button(action: {
                    screenshotManager.presentPicker()
                }, label: {
                    Text("Select Content Filters")
                })
            }

        }
        .padding()
        .frame(width: 248, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.gray.opacity(0.1))
        .sheet(isPresented: $showSelectPresetSheet, content: {
            VStack(alignment: .center, spacing: 16, content: {
                Text("Preset Filters")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                ForEach(ScreenshotManager.PresetFilterType.allCases, id: \.self) { preset in
                    Button(action: {
                        self.showSelectPresetSheet = false
                        screenshotManager.captureScreenshot(preset)
                    }, label: {
                        Text(preset.displayTitle)
                    })
                }
                
            })
            .padding()
        })
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
