//
//  UTType+Extensions.swift
//  ScreenCaptureKitDemo
//
//  Created by Itsuki on 2025/07/29.
//

import SwiftUI
import UniformTypeIdentifiers
@preconcurrency
import ScreenCaptureKit


extension UTType {
    var utTypeReference: UTTypeReference? {
        return UTTypeReference(self.identifier)
    }
    
    var avFileType: AVFileType? {
        return AVFileType(self.identifier)
    }
}

extension UTTypeReference {
    var utType: UTType? {
        return UTType(self.identifier)
    }
}


extension AVFileType {
    var utType: UTType? {
        return UTType(self.rawValue)
    }
}

