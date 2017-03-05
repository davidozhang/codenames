import UIKit

protocol SCLobbyRoomViewCellDelegate: class {
    func joinRoomWithUUID(uuid: String)
}

class SCLobbyRoomViewCell: UITableViewCell {
    weak var delegate: SCLobbyRoomViewCellDelegate?
    var roomUUID: String?

    @IBOutlet var joinRoomButton: UIButton!
    @IBOutlet weak var roomNameLabel: UILabel!
    
    override func awakeFromNib() {}
    
    @IBAction func onJoin(sender: AnyObject) {
        if let roomUUID = self.roomUUID {
            delegate?.joinRoomWithUUID(roomUUID)
        }
    }
}
