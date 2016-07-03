import UIKit

class PregameRoomViewCell: UITableViewCell {
    private let room = Room.instance
    var index: Int?
    
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var removeButton: UIButton!
    
    @IBAction func onRemove(sender: AnyObject) {
        if let index = index {
            room.removePlayerAtIndex(index)
        }
    }
    
    @IBAction func onEdit(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName(CodenamesNotificationKeys.editName, object: self)
    }
    
    override func awakeFromNib() {}
}