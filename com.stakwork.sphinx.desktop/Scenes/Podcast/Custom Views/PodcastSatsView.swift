//
//  PodcastSatsView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 06/11/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class PodcastSatsView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var amountLabel: NSTextField!
    @IBOutlet weak var amountSlider: NSSlider!
    @IBOutlet weak var suggestedAmountOutOfRangeLabel: NSTextField!
    
    let sliderValues = [0,3,3,5,5,8,8,10,10,20,20,40,40,80,80,100]
    
    var chat: Chat! = nil
    
    var sliderTimer : Timer? = nil

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        
        configureSlider()
        
        sliderTimer?.invalidate()
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        
        sliderTimer?.invalidate()
        sliderTimer = nil
    }
    
    func configureWith(chat: Chat) {
        self.chat = chat
        
        if let podcast = chat.getPodcastFeed() {
            if let storedAmount = podcast.satsPerMinute {
                setSliderValue(value: storedAmount)
            } else {
                let suggested = podcast.model?.suggestedSats ?? 0
                setSliderValue(value: suggested)
            }
        }
    }
    
    func setSliderValue(value: Int) {
        let closest = sliderValues.enumerated().min(by:{abs($0.1 - value) < abs($1.1 - value)})!
        amountSlider.doubleValue = Double(closest.offset)
        amountLabel.stringValue = "\(Int(closest.element))"
        
        setOutOfRangeLabel(value: value)
    }
    
    func setOutOfRangeLabel(value: Int) {
        suggestedAmountOutOfRangeLabel.stringValue = ""
        if let max = sliderValues.last, value > max {
            suggestedAmountOutOfRangeLabel.stringValue = String(format: "suggested.out.range".localized, value)
        }
    }
    
    @IBAction func sliderValueChanged(_ sender: NSSlider) {
        sliderTimer?.invalidate()
        
        let sliderValue = Int(ceil(sender.doubleValue))
        let realValue = sliderValues[sliderValue]
        amountLabel.stringValue = "\(realValue)"
        
        if let podcast = chat.getPodcastFeed() {
            podcast.satsPerMinute = realValue
        }

        setOutOfRangeLabel(value: realValue)
        
        sliderTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(didFinishDragging), userInfo: nil, repeats: false)
    }
    
    @objc func didFinishDragging() {
        if let podcast = chat.getPodcastFeed() {
            FeedsManager.sharedInstance.saveContentFeedStatus(for: podcast.feedID)
        }
    }
    
    func configureSlider() {
        amountLabel.stringValue = "sats.per.minute".localized
    }
}
