import UIKit

class SCNavigationBarBoldLabel: UILabel {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.font = SCFonts.regularSizeFont(SCFonts.FontType.Medium)
    }
}
