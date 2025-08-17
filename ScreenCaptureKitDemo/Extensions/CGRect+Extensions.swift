//
//  CGRect+Extensions.swift
//  ScreenCaptureKitDemo
//
//  Created by Itsuki on 2025/07/29.
//

import SwiftUI

extension CGRect {
    init(_ p1: CGPoint, _ p2: CGPoint) {
        let originX = min(p1.x, p2.x)
        let originY = min(p1.y, p2.y)
        let width = abs(p1.x - p2.x)
        let height = abs(p1.y - p2.y)
        self.init(origin: .init(x: originX, y: originY), size: .init(width: width, height: height))
    }
}
