//
//  ScreenshotManager.swift
//  ScreenCaptureKitDemo
//
//  Created by Itsuki on 2025/07/29.
//

import SwiftUI
// @preconcurrency required to pass SCContentFilter out
@preconcurrency
import ScreenCaptureKit
import UniformTypeIdentifiers

extension ScreenshotManager {
    enum PresetFilterType: CaseIterable {
        case fullScreen
        case fullScreenExcludingCurrent
        case xcode
         
        var displayTitle: String {
            switch self {
            case .fullScreen:
                "Everything On Screen"
            case .fullScreenExcludingCurrent:
                "Everything But Current App"
            case .xcode:
                "Xcode"
            }
        }

        func createFilter(_ availableContent: SCShareableContent) -> SCContentFilter? {
            guard let display = availableContent.displays.first else {
                return nil
            }
            switch self {
            case .fullScreen:
                return SCContentFilter(display: display, including: availableContent.windows)
            case .fullScreenExcludingCurrent:
                return SCContentFilter(display: display, including: availableContent.applications.filter({$0.bundleIdentifier != Bundle.main.bundleIdentifier }), exceptingWindows: [])
            case .xcode:
                return SCContentFilter(display: display, including: availableContent.applications.filter({$0.applicationName.localizedCaseInsensitiveContains("xcode")}), exceptingWindows: [])
            }
        }
    }
}


@Observable
class ScreenshotManager {
    let outputURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
    
    var cgImage: CGImage? = nil
    
    var enableFileOutput: Bool = false {
        didSet {
            self.screenshotConfiguration.fileURL = self.enableFileOutput ? self.outputURL : nil
        }
    }
    
    var fileOutputType: UTType = .png {
        didSet {
            if let utTypeReference = self.fileOutputType.utTypeReference {
                self.screenshotConfiguration.contentType = utTypeReference
            }
        }
    }
    
    var ignoreClipping: Bool = false {
        didSet {
            self.screenshotConfiguration.ignoreClipping = self.ignoreClipping
        }
    }
    
    var ignoreShadows: Bool = false {
        didSet {
            self.screenshotConfiguration.ignoreShadows = self.ignoreShadows
        }
    }
    
    var includeChildWindows: Bool = false {
        didSet {
            self.screenshotConfiguration.includeChildWindows = self.includeChildWindows
        }
    }
    
    var showsCursor: Bool = true {
        didSet {
            self.screenshotConfiguration.showsCursor = self.showsCursor
        }
    }
    
    
    // SCScreenshotConfiguration is not observable and will not trigger view updates
    private var screenshotConfiguration: SCScreenshotConfiguration = .init()
    
    private let pickerManager = SCContentSharingPickerManager()
    
    private var pickerConfiguration: SCContentSharingPickerConfiguration {
        var config = SCContentSharingPickerConfiguration()
        config.allowedPickerModes = [.singleDisplay, .singleWindow, .singleApplication, .multipleWindows, .multipleApplications]
        config.excludedWindowIDs = []
        config.excludedBundleIDs = []
        config.allowsChangingSelectedContent = true
        return config
    }
    
    init() {
        pickerManager.onFilterSelected = self.captureScreenshot
    }
    
    func presentPicker() {
        self.pickerManager.presentPicker(stream: nil)
    }

    func captureScreenshot(_ preset: PresetFilterType) {
        Task {
            do {
                let availableContent = try await SCShareableContent.current
                guard let filter = preset.createFilter(availableContent) else {
                    print("filter creation failed")
                    return
                }

                let output: SCScreenshotOutput = try await SCScreenshotManager.captureScreenshot(contentFilter: filter, configuration: self.screenshotConfiguration)
                processOutput(output)
            } catch(let error) {
                print(error)
            }
        }
    }

    
    func captureScreenshot(_ filter: SCContentFilter) {
        Task {
            do {
                let output: SCScreenshotOutput = try await SCScreenshotManager.captureScreenshot(contentFilter: filter, configuration: self.screenshotConfiguration)
                processOutput(output)
            } catch(let error) {
                print(error)
            }
        }
    }
    
    func captureScreenshot(_ rect: CGRect) {
        Task {
            do {
                let output: SCScreenshotOutput = try await SCScreenshotManager.captureScreenshot(rect: rect, configuration: self.screenshotConfiguration)
                processOutput(output)
            } catch(let error) {
                print(error)
            }
        }
    }
}


// MARK: private helpers
extension ScreenshotManager {
    private func processOutput(_ output: SCScreenshotOutput) {
        self.cgImage = output.hdrImage ?? output.sdrImage
        self.openOutputFolderIfNecessary()
    }
    
    private func openOutputFolderIfNecessary() {
        if self.screenshotConfiguration.fileURL != nil, let outputURL = self.outputURL {
            NSWorkspace.shared.open(outputURL)
        }
    }
}
