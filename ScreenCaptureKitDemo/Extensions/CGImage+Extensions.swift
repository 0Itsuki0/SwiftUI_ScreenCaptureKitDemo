//
//  CGImage+Extensions.swift
//  ScreenCaptureKitDemo
//
//  Created by Itsuki on 2025/07/29.
//

import SwiftUI

extension CGImage {
    var image: Image {
        return Image(decorative: self, scale: 1, orientation: .up)
    }
    
    var data: Data? {
        let rep = NSBitmapImageRep(cgImage: self)
        rep.size = .init(width: self.width, height: self.height)
        return rep.representation(using: .png, properties: [:])
    }
}
