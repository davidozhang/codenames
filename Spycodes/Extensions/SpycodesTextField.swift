import UIKit

class SpycodesTextField: UITextField {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layer.borderColor = UIColor.darkGrayColor().CGColor
        self.layer.borderWidth = 1.0
        self.font = UIFont(name: "HelveticaNeue-UltraLight", size: 32)
        
        self.autocorrectionType = UITextAutocorrectionType.No
        
    }
    
    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        if action == #selector(NSObject.copy(_:)) || action == #selector(NSObject.select(_:)) || action == #selector(NSObject.selectAll(_:)) || action == #selector(NSObject.paste(_:)) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
}
