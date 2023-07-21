//
//  ShimmeringView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 21/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class ShimmeringView: NSView {
    private var shimmerLayer: CALayer!

    override func awakeFromNib() {
        super.awakeFromNib()

        // Create a shimmering layer and add it as a sublayer
        shimmerLayer = CALayer()
        shimmerLayer.backgroundColor = NSColor.lightGray.cgColor // Set the shimmer color
        layer?.addSublayer(shimmerLayer)

        // Start the shimmering animation
        startShimmerAnimation()
    }

    override func layout() {
        super.layout()

        // Adjust the shimmer layer's frame to match the view's bounds
        shimmerLayer.frame = bounds
    }

    func startShimmerAnimation() {
        // Create a CABasicAnimation for the shimmer animation
        let shimmerAnimation = CABasicAnimation(keyPath: "position")
        shimmerAnimation.fromValue = NSValue(point: CGPoint(x: -bounds.width, y: bounds.midY))
        shimmerAnimation.toValue = NSValue(point: CGPoint(x: bounds.width * 2, y: bounds.midY))
        shimmerAnimation.duration = 1.5
        shimmerAnimation.repeatCount = .infinity

        // Add the shimmer animation to the shimmer layer
        shimmerLayer.add(shimmerAnimation, forKey: "shimmerAnimation")
    }
}
