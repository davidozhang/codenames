import UIKit

class SCGameRoomViewCell: UICollectionViewCell {

    @IBOutlet weak var wordLabel: UILabel!

    override func awakeFromNib() {
        self.wordLabel.font = UIFont(name: "HelveticaNeue-Medium", size: 16)
        self.contentView.layer.borderWidth = 1.0
        self.contentView.layer.borderColor = UIColor.darkGrayColor().CGColor
        self.contentView.layer.cornerRadius = 5.0
        self.contentView.layer.masksToBounds = true

        self.layer.masksToBounds = false
    }
}
