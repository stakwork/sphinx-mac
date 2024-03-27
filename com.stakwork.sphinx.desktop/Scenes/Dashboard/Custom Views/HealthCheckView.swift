//
//  HealthCheckView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 16/07/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol HealthCheckDelegate: AnyObject {
    func shouldShowBubbleWith(_ message: String)
}

class HealthCheckView: NSView, LoadableNib {
    
    weak var delegate: HealthCheckDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var healthCheckButton: CustomButton!
    
    public static let kConnectingColor = NSColor.Sphinx.SecondaryText
    public static let kConnectedColor = NSColor.Sphinx.PrimaryGreen
    public static let kNotConnectedColor = NSColor.Sphinx.SphinxOrange
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .onConnectionStatusChanged, object: nil)
    }
    
    func listenForEvents() {
        NotificationCenter.default.addObserver(forName: .onConnectionStatusChanged, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            self?.updateConnectionSign()
        }
    }
    
    func updateConnectionSign() {
        let connected = SphinxOnionManager.sharedInstance.isConnected
        
        if #available(OSX 10.14, *) {
            healthCheckButton.contentTintColor = connected ? HealthCheckView.kConnectedColor : HealthCheckView.kNotConnectedColor
        }
    }
    
    @IBAction func healthCheckButtonClicked(_ sender: Any) {
        let status = API.sharedInstance.connectionStatus
        let socketConnected = SphinxSocketManager.sharedInstance.isConnected()
        var message: String? = nil
        
        switch(status) {
        case API.ConnectionStatus.Connecting:
            break
        case API.ConnectionStatus.Connected:
            if socketConnected {
                message = "connected.to.node".localized
            } else {
                message = "socket.disconnected".localized
            }
            break
        case API.ConnectionStatus.NotConnected:
            message = "unable.to.connect".localized
            break
        case API.ConnectionStatus.Unauthorize:
            message = "unauthorized.error.message".localized
            break
        default:
            message = "network.connection.lost".localized
            break
        }
        
        if let message = message {
            delegate?.shouldShowBubbleWith(message)
        }
    }
}
