//
//  ScreenCaptureManager.swift
//  ScreenCaptureKitDemo
//
//  Created by Itsuki on 2025/07/29.
//

import SwiftUI
// @preconcurrency required to pass SCContentFilter out
@preconcurrency
import ScreenCaptureKit
import UniformTypeIdentifiers


@Observable
class ScreenCaptureManager {

    var previewImage: Image?

    
    // MARK: filter configurations
    var excludingCurrentApp: Bool = true {
        didSet {
            guard isCapturing else { return }
            Task {
                do {
                    guard let filter = try await self.createFullScreenContentFilter() else {
                        return
                    }
                    self.updateContentFilter(filter)
                } catch (let error) {
                    print(error)
                    self.excludingCurrentApp = oldValue
                }
            }
        }
    }
    
    // MARK: streaming configurations
    var showsCursor: Bool = true {
        didSet {
            self.streamConfiguration.showsCursor = self.showsCursor
            self.updateStreamConfiguration()
        }
    }
    
    var showMouseClicks: Bool = true {
        didSet {
            self.streamConfiguration.showMouseClicks = self.showMouseClicks
            self.updateStreamConfiguration()
        }
    }
    
    var grayScale: Bool = false {
        didSet {
            // empty string for the output buffer uses the same color space as the display
            self.streamConfiguration.colorSpaceName = self.grayScale ? CGColorSpace.linearGray : "" as CFString
            self.updateStreamConfiguration()
        }
    }
    
    var capturesAudio: Bool = false {
        didSet {
            self.streamConfiguration.capturesAudio = self.capturesAudio
            self.updateStreamConfiguration()
        }
    }
    
    var captureMicrophone: Bool = false {
        didSet {
            self.streamConfiguration.captureMicrophone = self.captureMicrophone
            self.updateStreamConfiguration()
        }
    }
    
    var excludesCurrentProcessAudio: Bool = true {
        didSet {
            self.streamConfiguration.excludesCurrentProcessAudio = self.excludesCurrentProcessAudio
            self.updateStreamConfiguration()
        }
    }
    
    // zero for capturing everything specified by the contentFilter
    var sourceRect: CGRect = .zero {
        didSet {
            guard self.sourceRect != oldValue else { return }
            self.streamConfiguration.sourceRect = self.sourceRect
            self.updateStreamConfiguration()
        }
    }
    
    var enableFileOutput = false {
        didSet {
            guard self.isCapturing else {
                return
            }
            guard self.enableFileOutput != oldValue else { return }
            self.enableFileOutput ? self.startRecording() : self.stopRecording()
        }
    }


    // for configuring capturesAudio, excludesCurrentProcessAudio, captureMicrophone, showMouseClicks, showsCursor, includeChildWindows, colorSpaceName and etc
    // width, height will be set based on the content filter to fit the captured content size
    //
    // reason for NOT using this variable directly but have all the individual variables for configuration
    // 1. setting some of the properties such as colorSpaceName, sourceRect will not trigger didSet
    // 2. This class is not observable, ie: will not trigger view updates
    private var streamConfiguration: SCStreamConfiguration = .init()

    
    private(set) var isCapturing: Bool = false

    // separate out isRecording from enableFileOutput
    // reason: even if we are currently not capturing, we still want to allow user to configure whether if they want to enable file output or not
    private(set) var isRecording: Bool = false {
        didSet {
            guard self.isRecording != oldValue else { return }
            self.enableFileOutput = isRecording
        }
    }
    
    private let streamManager = SCStreamManager()
    private let pickerManager = SCContentSharingPickerManager()
    
    private let outputURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first

    init() {
        
        // Set the capture interval at 60 fps.
        self.streamConfiguration.minimumFrameInterval = CMTime(value: 1, timescale: 60)

        // Increase the depth of the frame queue to ensure high fps at the expense of increasing
        // the memory footprint of WindowServer.
        self.streamConfiguration.queueDepth = 5
            
        self.streamManager.onVideoPreviewReceived = self.onVideoPreviewReceived
        self.streamManager.onStreamError = { _ in
            self.isCapturing = false
            self.isRecording = false
        }
        self.streamManager.onRecordingError = { _ in
            self.isRecording = false
        }
        
        // triggered when current recording end due to a change in StreamConfiguration
        // For example: switch from a capture of a specific region to selecting a contentFilter
        // resume the recording and save the output to a new file automatically.
        self.streamManager.onCurrentRecordingFinish = {
            guard self.isCapturing, self.enableFileOutput else { return }
            self.startRecording(isResuming: true)
        }
    }
    
    
    func startCapture() {
        print(#function)
        Task {
            do {
                guard let filter = try await self.createFullScreenContentFilter() else {
                    return
                }
                self.startCapture(filter)
            } catch (let error) {
                print(error)
            }
        }
    }
    
    private func startCapture(_ contentFilter: SCContentFilter) {
        guard !self.isCapturing else { return }
        print(#function)
        
        // update stream output size if preferred.
        // self.updateStreamOutputSize(contentFilter)
        
        do {
            let recordingConfiguration = self.makeRecordingConfiguration()
            try self.streamManager.startCapture(contentFilter: contentFilter, streamConfiguration: self.streamConfiguration, recordingOutputConfiguration: !self.enableFileOutput ? nil : recordingConfiguration)
            
            self.isCapturing = true
            self.isRecording = self.enableFileOutput
        } catch (let error) {
            print(error)
        }
    }
    
    
    func stopCapture() {
        guard self.isCapturing else { return }
        print(#function)
        
        Task {
            do {
                try await self.streamManager.stopCapture()
                self.stopRecording()
                self.isCapturing = false
            } catch(let error) {
                print(error)
            }
        }
    }


    func presentPicker() {
        // present Picker and start capturing
        guard self.isCapturing else {
            self.presentPicker(withRecording: self.enableFileOutput)
            return
        }
        
        // presenting picker after capture started: change the filter for current stream
        self.pickerManager.onFilterSelected = { filter in
            self.updateContentFilter(filter)
        }
        
        self.pickerManager.presentPicker(stream: self.streamManager.stream, excludingCurrentApp: self.excludingCurrentApp)
    }
    
    
    // for presenting picker before capture started
    private func presentPicker(withRecording: Bool) {
        guard !self.isCapturing else { return }
        
        self.pickerManager.onFilterSelected = { filter in
            self.startCapture(filter)
        }
        self.pickerManager.presentPicker(stream: nil, excludingCurrentApp: self.excludingCurrentApp)
    }
        

    // - isResuming: when recording finished due to a change in SCStreamConfiguration
    func startRecording(isResuming: Bool = false) {
        guard self.isCapturing else {
            return
        }
        guard !self.isRecording || isResuming else {
            return
        }
        print(#function)
        
        guard let recordingConfiguration = self.makeRecordingConfiguration() else {
            return
        }
        
        do {
            try self.streamManager.startRecording(recordingConfiguration)
            self.isRecording = true
        } catch (let error) {
            print(error)
            // required because in the case of isResuming is true,
            // self.isRecording is currently true and we want to set it to false to indicate the failure
            self.isRecording = false
        }
    }
    
    
    func stopRecording() {
        guard self.isRecording else { return }
        do {
            try self.streamManager.stopRecording()
            self.openOutputFolder()
            self.isRecording = false
        } catch(let error) {
            print(error)
        }
    }

}



// MARK: other helpers
extension ScreenCaptureManager {
    
    private func createFullScreenContentFilter() async throws -> SCContentFilter? {
        let availableContent = try await SCShareableContent.current
        guard let display = availableContent.displays.first else {
            return nil
        }
        
        let excludedApps: [SCRunningApplication] = self.excludingCurrentApp ? availableContent.applications.filter({$0.bundleIdentifier == Bundle.main.bundleIdentifier}) : []

        let filter = SCContentFilter(display: display, excludingApplications: excludedApps, exceptingWindows: [])
        
        return filter
    }
    
    
    private func makeRecordingConfiguration() -> SCRecordingOutputConfiguration? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let currentDateTime = dateFormatter.string(from: Date())
        let recordingConfiguration = SCRecordingOutputConfiguration()
        
        // mp4 is corrupted sometimes when stopping the recording together with the capture stream.
        recordingConfiguration.outputFileType = recordingConfiguration.availableOutputFileTypes.contains(.mov) ? .mov : .mp4
        
        guard let outputURL = self.outputURL?.appendingPathComponent("Screen Recording \(currentDateTime)", conformingTo: recordingConfiguration.outputFileType.utType ?? .mpeg4Movie) else {
            print("URL creation failed")
            return nil
        }
        
        recordingConfiguration.outputURL = outputURL

        return recordingConfiguration
    }
    
    // update SCStreamConfiguration of a running capture (stream)
    // this will cause any current recording to stop and
    // will be  handled using streamManager.onCurrentRecordingFinish
    private func updateStreamConfiguration() {
        guard self.isCapturing else { return }
        Task {
            do {
                try await self.streamManager.updateStreamConfiguration(self.streamConfiguration)
            } catch(let error) {
                print(error)
            }
        }
    }

    // update SCContentFilter of a running capture (stream)
    private func updateContentFilter(_ contentFilter: SCContentFilter) {
        guard self.isCapturing else { return }

        // not updating the size of the output
        // avoid trigger recordingOutputDidFinishRecording due to update in stream configuration when not necessary
        // self.updateStreamOutputSize(contentFilter)
       
        // resetting the source rect to capture the entire area of the content filter
        self.sourceRect = .zero // self.updateStreamConfiguration() is called automatically

        Task {
            do {
                try await self.streamManager.updateContentFilter(contentFilter)
            } catch(let error) {
                print(error)
            }
        }
    }
    
    
    // set width, height will based on the content filter to fit the captured content size
    // Not used in this demo
    private func updateStreamOutputSize(_ contentFilter: SCContentFilter) {
        let scaleFactor = Int(NSScreen.main?.backingScaleFactor ?? 2)
        self.streamConfiguration.width = Int(contentFilter.contentRect.size.width) * scaleFactor
        self.streamConfiguration.height = Int(contentFilter.contentRect.size.height) * scaleFactor
    }
    
    
    private func onVideoPreviewReceived(_ ciImage: CIImage) {
        guard self.isCapturing else { return }
        self.previewImage = ciImage.image
    }

    private func openOutputFolder() {
        if let outputURL = self.outputURL {
            print("opening output folder")
            NSWorkspace.shared.open(outputURL)
        }
    }

}
