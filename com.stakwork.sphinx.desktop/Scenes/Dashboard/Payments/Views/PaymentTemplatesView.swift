//
//  PaymentTemplatesView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 06/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class PaymentTemplatesView: NSView, LoadableNib {
    
    weak var delegate: CommonPaymentViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var amountLabel: NSTextField!
    @IBOutlet weak var messageLabel: NSTextField!
    
    @IBOutlet weak var selectedImageContainer: NSView!
    @IBOutlet weak var selectedImage: NSImageView!
    @IBOutlet weak var selectedCircleView: NSView!
    
    @IBOutlet weak var templatesScrollView: CustomScrollView!
    @IBOutlet weak var templatesCollectionViewContainer: NSView!
    @IBOutlet weak var templatesCollectionView: NSCollectionView!
    
    @IBOutlet weak var templatesLoadingContainer: NSView!
    @IBOutlet weak var templatesLoadingWheel: NSProgressIndicator!
    
    @IBOutlet weak var confirmButtonContainer: NSBox!
    @IBOutlet weak var confirmButton: NSButton!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    
    var dataSource : PaymentTemplatesDataSource? = nil
    var paymentViewModel : PaymentViewModel!
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.white, controls: [confirmButton])
        }
    }
    
    var loadingTemplates = false {
        didSet {
            selectedImageContainer.alphaValue = loadingTemplates ? 0.0 : 1.0
            templatesCollectionViewContainer.alphaValue = loadingTemplates ? 0.0 : 1.0
            templatesLoadingContainer.alphaValue = loadingTemplates ? 1.0 : 0.0
            
            LoadingWheelHelper.toggleLoadingWheel(loading: loadingTemplates, loadingWheel: templatesLoadingWheel, color: NSColor.Sphinx.Text, controls: [confirmButton])
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let sideInset = self.bounds.width / 2 - PaymentTemplatesDataSource.kCellWidth / 2
        templatesScrollView.automaticallyAdjustsContentInsets = false
//        templatesScrollView.contentInsets = NSEdgeInsets(top: 0, left: sideInset, bottom: 0, right: sideInset)
        templatesScrollView.horizontalScroller?.alphaValue = 0.0
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        
        selectedCircleView.wantsLayer = true
        selectedCircleView.layer?.cornerRadius = selectedCircleView.frame.height / 2
        selectedCircleView.layer?.borderWidth = 3
        selectedCircleView.layer?.borderColor = NSColor.white.cgColor

        confirmButtonContainer.wantsLayer = true
        confirmButtonContainer.layer?.cornerRadius = confirmButtonContainer.frame.height / 2
    }
    
    func configureView(delegate: CommonPaymentViewDelegate, paymentViewModel: PaymentViewModel) {
        self.delegate = delegate
        self.paymentViewModel = paymentViewModel
        
        templatesScrollView.touchEndedCallback = {
            self.dataSource?.didFinishScrolling()
        }
        
        loadTemplates()
    }
    
    func loadTemplates() {
        loadingTemplates = true
        
        API.sharedInstance.getPaymentTemplates(token: UserDefaults.Keys.attachmentsToken.get(defaultValue: ""), callback: { templates in
            self.configureCollectionView(images: templates)
        }, errorCallback: {
            NewMessageBubbleHelper().showGenericMessageView(text: "generic.error.message".localized, in: self)
            self.loadingTemplates = false
        })
    }
    
    func configureCollectionView(images: [ImageTemplate]) {
        dataSource = PaymentTemplatesDataSource(collectionView: templatesCollectionView, delegate: self, images: images)

        templatesCollectionView.wantsLayer = true
        templatesCollectionView.layer?.masksToBounds = false
        templatesCollectionView.delegate = dataSource
        templatesCollectionView.dataSource = dataSource
        templatesCollectionView.reloadData()
        
        if images.count > 0 {
            setSelectedImage(image: images[0])
        }
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
            self.templatesCollectionView.scrollToItems(at: [IndexPath(item: 1, section: 0)], scrollPosition: .centeredHorizontally)
            self.loadingTemplates = false
        })
    }
    
    func set(message: String, amount: Int) {
        messageLabel.stringValue = message
        amountLabel.stringValue = "\(amount)"
    }
    
    @IBAction func confirmButtonClicked(_ sender: Any) {
        loading = true
        delegate?.didConfirm()
    }
    
    @IBAction func backButtonClicked(_ sender: Any) {
        delegate?.shouldGoBack()
    }
    
    @IBAction func closeButtonClicked(_ sender: Any) {
        delegate?.shouldClose()
    }
}

extension PaymentTemplatesView : PaymentTemplatesDSDelegate {
    func didSelectImage(image: ImageTemplate?) {
        setSelectedImage(image: image)
    }
    
    func setSelectedImage(image: ImageTemplate?) {
        paymentViewModel.currentPayment.muid = image?.muid
        
        if let width = image?.width, let height = image?.height {
            paymentViewModel.currentPayment.dim = "\(width)x\(height)"
        } else {
            paymentViewModel.currentPayment.dim = nil
        }
        
        if let muid = image?.muid {
            setImage(image: nil, contentMode: .resizeAspect)
            
            MediaLoader.loadTemplate(row: 0, muid: muid, completion: { (_, muid, image) in
                if muid != self.paymentViewModel.currentPayment.muid {
                    return
                }
                self.setImage(image: image, contentMode: .resizeAspect)
            })
        } else {
            selectedImage.layer?.contents = nil
            selectedImage.image = NSImage(named: "noTemplate")
            if #available(OSX 10.14, *) {
                selectedImage.contentTintColor = NSColor.Sphinx.WashedOutReceivedText
            }
            selectedImage.imageScaling = .scaleNone
        }
    }
    
    func setImage(image: NSImage?, contentMode: CALayerContentsGravity) {
        selectedImage.wantsLayer = true
        selectedImage.image = nil
        selectedImage.layer?.contentsGravity = contentMode
        selectedImage.layer?.contents = image
    }
}
