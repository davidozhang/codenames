import MultipeerConnectivity
import UIKit

class LobbyRoomViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MultipeerManagerDelegate, LobbyRoomViewCellDelegate {
    private let identifier = "lobby-room-view-cell"
    private var refreshTimer: NSTimer?
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MultipeerManager.instance.delegate = self
        MultipeerManager.instance.initPeerID(Player.instance.getPlayerName())
        MultipeerManager.instance.initBrowser()
        MultipeerManager.instance.initSession()
        MultipeerManager.instance.startBrowser()
        
        self.refreshTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(LobbyRoomViewController.refreshView), userInfo: nil, repeats: true)     // Refresh lobby every second
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Private
    @objc
    private func refreshView() {
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
        })
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier) as! LobbyRoomViewCell
        let roomAtIndex = Lobby.instance.getRooms()[indexPath.row]
        cell.roomName = roomAtIndex.getRoomName()
        cell.roomNameLabel.text = String(indexPath.row + 1) + ". " + roomAtIndex.getRoomName()
        
        cell.delegate = self
        
        return cell
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Lobby.instance.getNumberOfRooms()
    }
    
    // MARK: LobbyRoomViewCellDelegate
    func joinGameWithName(name: String) {
        // Start advertising to allow host room to invite into session
        MultipeerManager.instance.initDiscoveryInfo(["joinRoom": name])
        MultipeerManager.instance.initAdvertiser()
        MultipeerManager.instance.startAdvertiser()
    }
    
    // MARK: MultipeerManagerDelegate
    func foundPeer(peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        if let info = info where info["isHost"] == "yes" && !Lobby.instance.hasRoomWithName(peerID.displayName) {
            Lobby.instance.addRoomWithName(peerID.displayName)
        }
    }
    
    func lostPeer(peerID: MCPeerID) {
        Lobby.instance.removeRoomWithName(peerID.displayName)
    }
    
    // Navigate to pregame room only when preliminary sync data from host is received
    func didReceiveData(data: NSData, fromPeer peerID: MCPeerID) {
        if let room = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Room {
            Room.instance = room     // TODO: Sync room locally without the need for prepareForSegue
            
            // Inform the room host of local player info
            let data = NSKeyedArchiver.archivedDataWithRootObject(Player.instance)
            MultipeerManager.instance.broadcastData(data)
            
            self.refreshTimer?.invalidate()
            
            dispatch_async(dispatch_get_main_queue(), {
                self.performSegueWithIdentifier("pregame-room", sender: self)
            })
        }
    }
    
    func newPeerAddedToSession(peerID: MCPeerID) {}
    
    func peerDisconnectedFromSession(peerID: MCPeerID) {}
}
