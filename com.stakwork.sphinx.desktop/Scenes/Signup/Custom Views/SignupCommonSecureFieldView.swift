import Cocoa


class SignupCommonSecureFieldView: NSView, LoadableNib {
    
    weak var delegate: SignupFieldViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var topLabel: NSTextField!
    @IBOutlet weak var fieldBox: NSBox!
    @IBOutlet weak var textField: CCSecureTextField!
    
    var field: NamePinView.Fields = .Name
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    func getFieldValue() -> String {
        return textField.stringValue
    }
    
    func getTextField() -> NSTextField {
        return textField
    }
    
    func set(fieldValue: String) {
        textField.stringValue = fieldValue
        topLabel.alphaValue = textField.stringValue.isEmpty ? 0.0 : 1.0
    }
}

extension SignupCommonSecureFieldView : NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) { }
    
    func controlTextDidBeginEditing(_ obj: Notification) {
        toggleActiveState(true)
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        toggleActiveState(false)
    }
    
    func toggleActiveState(_ active: Bool) {
        fieldBox.borderWidth = active ? 2 : 0
        fieldBox.borderColor = active ? NSColor.Sphinx.ReceivedIcon : NSColor.clear
        
        topLabel.textColor = active ? NSColor.Sphinx.ReceivedIcon : NSColor.Sphinx.SecondaryText
    }
}
