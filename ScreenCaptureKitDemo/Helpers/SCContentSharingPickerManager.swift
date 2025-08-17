//
//  SCContentSharingPickerManager.swift
//  ScreenCaptureKitDemo
//
//  Created by Itsuki on 2025/07/28.
//

import SwiftUI
@preconcurrency
import ScreenCaptureKit


nonisolated
class SCContentSharingPickerManager: NSObject {
    
    var onFilterSelected: ((SCContentFilter) -> Void)?

    private var pickerConfiguration: SCContentSharingPickerConfiguration {
        var config = SCContentSharingPickerConfiguration()
        config.allowedPickerModes = [.singleDisplay, .singleWindow, .singleApplication, .multipleWindows, .multipleApplications]
        config.excludedWindowIDs = []
        config.excludedBundleIDs = []
        config.allowsChangingSelectedContent = true
        return config
    }

    func presentPicker(stream: SCStream?, excludingCurrentApp: Bool = false) {
        let picker = SCContentSharingPicker.shared
        var config = self.pickerConfiguration
        if excludingCurrentApp, let bundleId = Bundle.main.bundleIdentifier {
            config.excludedBundleIDs = [bundleId]
        }
        picker.configuration = self.pickerConfiguration
        picker.add(self)

        // When this value is true, the capture stream picker is active, available for managing capture. The default value is false.
        picker.isActive = true
        if let stream {
            picker.present(for: stream)
        } else {
            picker.present()
        }
        // to only allow user to pick a specific type, for example: windows
        // picker.present(using: .window)
    }
    
    
    // clean up the picker after capturing or cancelling
    // so that we don't get the icon on the menu bar saying screen is being shared
    private func cleanUpPicker(_ picker: SCContentSharingPicker) {
        picker.isActive = false
        picker.remove(self)
    }

}


// MARK: SCContentSharingPickerObserver
extension SCContentSharingPickerManager: SCContentSharingPickerObserver {
    
    // either marked the class as non isolated or the observer function as nonisolated individually
    // otherwise app will crash
    func contentSharingPicker(_ picker: SCContentSharingPicker, didCancelFor stream: SCStream?) {
        print(#function)
        self.cleanUpPicker(picker)
    }
    
     func contentSharingPicker(_ picker: SCContentSharingPicker, didUpdateWith filter: SCContentFilter, for stream: SCStream?) {
        print(#function)
        // we don't need the picker anymore
        self.cleanUpPicker(picker)
        self.onFilterSelected?(filter)
    }

     func contentSharingPickerStartDidFailWithError(_ error: any Error) {
        print(#function)
        print(error)
    }
}
