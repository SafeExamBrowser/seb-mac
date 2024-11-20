//
//  NSImageView.swift
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 20.11.2024.
//

import Foundation

@objc class SEBNSImageView: NSView {

    var image : NSImage? {
        didSet {
           needsDisplay = true
        }
    }

    @objc init(frame frameRect: NSRect, image : NSImage?) {
        self.image = image
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func draw(_ dirtyRect: NSRect) {
        let imageBounds = bounds
        let width = imageBounds.width
        let height = imageBounds.height
        print(width)
        print(height)
        image?.draw(at: .zero, from: NSZeroRect, operation: .sourceOver, fraction: 1.0)
    }
}
