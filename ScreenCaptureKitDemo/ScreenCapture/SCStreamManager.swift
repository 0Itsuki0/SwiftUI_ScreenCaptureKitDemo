//
//  SCStreamManager.swift
//  ScreenCaptureKitDemo
//
//  Created by Itsuki on 2025/07/29.
//

import SwiftUI
// @preconcurrency required to pass SCContentFilter out
@preconcurrency
import ScreenCaptureKit
import UniformTypeIdentifiers


nonisolated
class SCStreamManager: NSObject {

    var onVideoPreviewReceived: ((CIImage) -> Void)?
    var onStreamError: ((any Error) -> Void)?
    var onRecordingError: ((any Error) -> Void)?
    
    // this will only be triggered when the SCStreamConfiguration changed
    var onCurrentRecordingFinish: (() -> Void)?

    private let videoSampleBufferQueue = DispatchQueue(label: "VideoSampleBufferQueue")
    private let audioSampleBufferQueue = DispatchQueue(label: "AudioSampleBufferQueue")
    private let micSampleBufferQueue = DispatchQueue(label: "MicSampleBufferQueue")
    
    var stream: SCStream? = nil
    private var recordingOutput: SCRecordingOutput? = nil
    
    func startCapture(contentFilter: SCContentFilter, streamConfiguration: SCStreamConfiguration, recordingOutputConfiguration: SCRecordingOutputConfiguration?) throws {
        print(#function)
        
        self.stream = SCStream(filter: contentFilter, configuration: streamConfiguration, delegate: self)
        
        // Add a stream output to capture screen content.
        try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: videoSampleBufferQueue)
        
        try stream?.addStreamOutput(self, type: .audio, sampleHandlerQueue: audioSampleBufferQueue)
        
        try stream?.addStreamOutput(self, type: .microphone, sampleHandlerQueue: micSampleBufferQueue)
        
        // add record output before start capture to make sure the first frame is recorded correctly
        if let recordingOutputConfiguration {
            try self.startRecording(recordingOutputConfiguration)
        }
        
        stream?.startCapture()
    }
    
    func stopCapture() async throws {
        try self.stopRecording()
        try await stream?.stopCapture()
        self.stream = nil
    }

    
    // can be called before starting capture stream?.startCapture
    // and is preferred so that the first frame can bes recorded correctly
    func startRecording(_ recordingOutputConfiguration: SCRecordingOutputConfiguration) throws {
        if self.stream == nil {
            return
        }
        guard self.recordingOutput == nil else {
            return
        }
        print(#function)
        let recordingOutput = SCRecordingOutput(configuration: recordingOutputConfiguration, delegate: self)
        try self.stream?.addRecordingOutput(recordingOutput)
        self.recordingOutput = recordingOutput
    }
    
    
    func stopRecording() throws {
        guard let recordingOutput = self.recordingOutput else { return }
        print(#function)
        try self.stream?.removeRecordingOutput(recordingOutput)
        self.recordingOutput = nil
    }
    
    
    func updateStreamConfiguration(_ streamConfiguration: SCStreamConfiguration) async throws {
        print(#function)
        print(self.stream as Any)
        try await self.stream?.updateConfiguration(streamConfiguration)
    }

    func updateContentFilter(_ contentFilter: SCContentFilter) async throws {
        print(#function)
        print(self.stream as Any)

        try await self.stream?.updateContentFilter(contentFilter)
    }
    
}


// MARK: SCStreamOutput
extension SCStreamManager: SCStreamOutput {
    // sample buffer: An object that contains zero or more media samples of a particular type (audio, video, mixed, and so on)
    // https://developer.apple.com/documentation/coremedia/cmsamplebuffer
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard sampleBuffer.isValid else { return }
       
        switch type {
        case .screen:
            // Create a CapturedFrame structure for a video sample buffer.
            guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            self.onVideoPreviewReceived?(ciImage)
        case .audio:
            return
        case .microphone:
            return
        @unknown default:
            return
        }
    }
}


// MARK: SCStreamDelegate
extension SCStreamManager: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: any Error) {
        print(#function)
        print(error)
        self.onStreamError?(error)
    }
    
    func streamDidBecomeActive(_ stream: SCStream) {
        print(#function)
    }
    
    func streamDidBecomeInactive(_ stream: SCStream) {
        print(#function)
    }
    
    func outputVideoEffectDidStop(for stream: SCStream) {
        print(#function)
    }
    
    func outputVideoEffectDidStart(for stream: SCStream) {
        print(#function)
    }
}


// MARK: SCRecordingOutputDelegate
extension SCStreamManager: SCRecordingOutputDelegate {
    func recordingOutputDidStartRecording(_ recordingOutput: SCRecordingOutput) {
        print(#function)
    }

    func recordingOutputDidFinishRecording(_ recordingOutput: SCRecordingOutput) {
        print(#function)
        try? self.stopRecording()
        self.recordingOutput = nil // in case the function above fails
        self.onCurrentRecordingFinish?()
    }
    
    func recordingOutput(_ recordingOutput: SCRecordingOutput, didFailWithError error: any Error) {
        print(#function)
        print(error)
        self.onRecordingError?(error)
    }
}
