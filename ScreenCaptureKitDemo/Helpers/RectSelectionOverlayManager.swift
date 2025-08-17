//
//  RectSelectionOverlayManager.swift
//  ScreenCaptureKitDemo
//
//  Created by Itsuki on 2025/07/29.
//

import SwiftUI

@Observable
class RectSelectionOverlayManager {
    static let shared = RectSelectionOverlayManager()

    var rect: CGRect?
    var finished: Bool = false
    
    var windowSize: CGSize = .zero
    
    func resetSelection() {
        self.rect = nil
        self.finished = false
    }
    
    func configureWindow(_ window: NSWindow) {
        window.level = .popUpMenu // popUpMenu will also work
        
        // set the position of the window
        window.setFrameOrigin(NSPoint(x: 0, y: 0))

        // remove title and buttons
        window.styleMask.remove(.titled)
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        // so that the window can follow the virtual desktop
        window.collectionBehavior.insert(.canJoinAllSpaces)
        
        // set it clear here so the configuration in UtilityWindowView will be reflected as it is
        window.backgroundColor = .clear
        
        self.windowSize = window.frame.size
        
    }
}
