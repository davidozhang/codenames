import UIKit

class SCButton: UIButton {
    var alreadyHighlighted = false

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.contentEdgeInsets = UIEdgeInsetsMake(10, 30, 10, 30)
        self.setTitleColor(
            .spycodesGrayColor(),
            for: UIControlState()
        )
        self.setTitleColor(
            .white,
            for: .highlighted
        )
        self.titleLabel?.font = SCFonts.regularSizeFont(.regular)
        self.layer.borderColor = UIColor.spycodesGrayColor().cgColor
        self.layer.borderWidth = 1.5
        self.layer.cornerRadius = 5.0
    }

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                self.backgroundColor = .spycodesGrayColor()
                if !self.alreadyHighlighted {
                    SCAudioManager.playClickSound()
                    self.alreadyHighlighted = true
                }
            } else {
                self.backgroundColor = .clear
                self.alreadyHighlighted = false
            }
        }
    }
}
