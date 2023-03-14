//
//  PinTimeoutView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 12/01/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol PinTimeoutViewDelegate: AnyObject {
    func shouldEnableSave()
}

class PinTimeoutView: NSView, LoadableNib {
    
    weak var delegate: PinTimeoutViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var hoursLabel: NSTextField!
    @IBOutlet weak var sliderControl: NSSlider!
    
    let userData = UserData.sharedInstance
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        configureView()
    }
    
    func configureView() {
        sliderControl.maxValue = Double(Constants.kMaxPinTimeoutValue)
        
        if userData.getPINNeverOverride() {
            sliderControl.floatValue = Float(sliderControl.maxValue)
            hoursLabel.stringValue = "never.require.pin".localized
        } else {
            let hours = userData.getPINHours()
            sliderControl.floatValue = Float(hours)
            hoursLabel.stringValue = getHoursLabel(hours)
        }
    }
    
    func getHoursLabel(_ hours: Int) -> String {
        if hours == 0 {
            return "always.require.pin".localized
        }
        if hours == 1 {
            return "\(hours) \("hour".localized)"
        }
        if hours == Constants.kMaxPinTimeoutValue{
            return "never.require.pin".localized
        }
        return "\(hours) \("hours".localized)"
    }
    
    @IBAction func sliderValueChanged(_ sender: NSSlider) {
        sender.floatValue = roundf(sender.floatValue)
        
        let intValue = Int(sender.integerValue)
        hoursLabel.stringValue = getHoursLabel(intValue)
        
        delegate?.shouldEnableSave()
    }
    
    func getPinHours() -> Int {
        let intValue = Int(sliderControl.integerValue)
        return intValue
    }
    
}
