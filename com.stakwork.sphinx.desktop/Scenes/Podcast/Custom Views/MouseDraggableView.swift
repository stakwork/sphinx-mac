//
//  MouseDraggableView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol MouseDraggableViewDelegate: AnyObject {
    func mouseUpOn(x: CGFloat)
    func mouseDownOn(x: CGFloat)
    func mouseDraggedOn(x: CGFloat)
}

class MouseDraggableView: NSView {
    
    weak var delegate: MouseDraggableViewDelegate?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func mouseDown(with event: NSEvent) {
        mouseDownImpl(with: event)

        while true {
            guard let nextEvent = self.window?.nextEvent(matching: [.leftMouseUp, .leftMouseDragged]) else { continue }

            switch nextEvent.type {
            case .leftMouseDragged:
                mouseDraggedImpl(with: nextEvent)
            case .leftMouseUp:
                mouseUpImpl(with: nextEvent)
                return
            default: break
            }
        }
    }

    func mouseDownImpl(with event: NSEvent) {
        let eventLocation = event.locationInWindow
        let localPoint = self.convert(eventLocation, from: nil)

        delegate?.mouseDownOn(x: localPoint.x)
    }
    
    func mouseDraggedImpl(with event: NSEvent) {
        let eventLocation = event.locationInWindow
        let localPoint = self.convert(eventLocation, from: nil)

        delegate?.mouseDraggedOn(x: localPoint.x)
    }
    
    func mouseUpImpl(with event: NSEvent) {
        let eventLocation = event.locationInWindow
        let localPoint = self.convert(eventLocation, from: nil)

        delegate?.mouseUpOn(x: localPoint.x)
    }
    
}
