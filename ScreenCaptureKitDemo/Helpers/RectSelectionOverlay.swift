//
//  RectSelectionOverlay.swift
//  ScreenCaptureKitDemo
//
//  Created by Itsuki on 2025/07/26.
//

import SwiftUI

struct RectSelectionOverlay: View {
    static let id = "FullScreenOverlay"
    
    @State private var overlayManager = RectSelectionOverlayManager.shared
    
    @Environment(\.dismiss) private var dismiss
    @State private var isInitial = true

    var body: some View {
        ZStack {
            if let rect = overlayManager.rect {
                Path(rect)
                    .fill(.white.opacity(0.3), style: .init())
            } else {
                Text("Start dragging to select!")
                    .font(.headline)
            }
        }
        .frame(width: NSScreen.main?.frame.size.width, height: NSScreen.main?.frame.size.height)
        .contentShape(Rectangle())
        .background(.gray.opacity(0.5))
        .onTapGesture {
            self.overlayManager.resetSelection()
            dismiss()
        }
        .highPriorityGesture(
            DragGesture()
                .onChanged({ value in
                    self.overlayManager.rect = .init(value.startLocation, value.location)
                })
                .onEnded({ value in
                    self.overlayManager.rect = .init(value.startLocation, value.location)
                    self.overlayManager.finished = true
                    self.dismiss()
                })
        )
        .onAppear {
            // if isInitial is true, we are opening the window only so that the next time we actually need to use it, we can configure it before opening
            if self.isInitial {
                self.isInitial = false
                dismiss()
                return
            }
            
            self.overlayManager.resetSelection()
        }
    }
}
