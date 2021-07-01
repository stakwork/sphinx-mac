//
//  SettingsTabsView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 24/08/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol SettingsTabsDelegate: AnyObject {
    func didChangeSettingsTab(tag: Int)
}

class SettingsTabsView: NSView, LoadableNib {
    
    weak var delegate: SettingsTabsDelegate?

    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var basicSettingsBox: NSBox!
    @IBOutlet weak var advancedSettingsBox: NSBox!
    @IBOutlet weak var basicSettingsButton: CustomButton!
    @IBOutlet weak var advancedSettingsButton: CustomButton!
    
    enum Tabs: Int {
        case Basic = 0
        case Settings = 1
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        configureView()
        setSelected()
    }
    
    func configureView() {
        basicSettingsButton.cursor = .pointingHand
        advancedSettingsButton.cursor = .pointingHand
    }
    
    func setSelected() {
        toggleAll(selectedTag: 0)
    }
    
    func toggleAll(selectedTag: Int = -1) {
        basicSettingsBox.fillColor = (selectedTag == Tabs.Basic.rawValue) ? NSColor.Sphinx.PrimaryBlue : NSColor.Sphinx.Body
        advancedSettingsBox.fillColor = (selectedTag == Tabs.Basic.rawValue) ? NSColor.Sphinx.Body : NSColor.Sphinx.PrimaryBlue
        
        if #available(OSX 10.14, *) {
            basicSettingsButton.contentTintColor = (selectedTag == Tabs.Basic.rawValue) ? NSColor.white : NSColor.Sphinx.Text
            advancedSettingsButton.contentTintColor = (selectedTag == Tabs.Basic.rawValue) ? NSColor.Sphinx.Text : NSColor.white
        }
    }
    
    @IBAction func buttonClicked(_ sender: NSButton) {
        toggleAll(selectedTag: sender.tag)
        delegate?.didChangeSettingsTab(tag: sender.tag)
    }
}
