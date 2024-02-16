//
//  TemplateCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 06/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class TemplateCollectionViewItem: NSCollectionViewItem {

    @IBOutlet weak var templateImageBack: NSBox!
    @IBOutlet weak var templateImageView: AspectFillNSImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.wantsLayer = true
        self.view.layer?.masksToBounds = false
    }
    
    func configureAsMargin() {
        self.view.alphaValue = 0.0
    }
    
    func configure(
        itemIndex: Int,
        imageTemplate: ImageTemplate?
    ) {
        templateImageBack.wantsLayer = true
        templateImageBack.layer?.cornerRadius = templateImageBack.frame.size.width / 2
        templateImageBack.layer?.backgroundColor = NSColor.Sphinx.Body.cgColor
        
        templateImageView.wantsLayer = true
        templateImageView.radius = templateImageView.frame.size.width / 2
        templateImageView.image = nil
        addShadow()
        
        guard let imageTemplate = imageTemplate else {
            return
        }
        
        if let muid = imageTemplate.muid {
            MediaLoader.loadTemplate(row: itemIndex, muid: muid, completion: { (item, _, image) in
                if itemIndex != item {
                    return
                }
                self.templateImageView.image = image
            })
        }
    }
    
    func addShadow() {
        templateImageBack.addShadow(location: .center, color: NSColor.Sphinx.Shadow, opacity: 0.5, radius: 8, cornerRadius: templateImageBack.frame.height / 2)
    }
}
