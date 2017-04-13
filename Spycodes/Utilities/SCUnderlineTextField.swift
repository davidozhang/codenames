import UIKit

class SCUnderlineTextField: SCTextField {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.font = SCFonts.largeSizeFont(SCFonts.fontType.medium)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let bottomBorder = CALayer()
        bottomBorder.frame = CGRect(
            x: 0.0,
            y: self.frame.size.height - 1.5,
            width: self.frame.size.width,
            height: 1.5
        )
        bottomBorder.backgroundColor = UIColor.spycodesGrayColor().cgColor

        self.layer.addSublayer(bottomBorder)
    }
}
