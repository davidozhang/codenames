import MultipeerConnectivity
import UIKit

class LobbyRoomViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MultipeerManagerDelegate, LobbyRoomViewCellDelegate {
    private let identifier = "lobby-room-view-cell"
    
    private var refreshTimer: NSTimer?
    private var joinGameAlertController: UIAlertController?
    
    private var emptyStateLabel: UILabel?
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func onBackPressed(sender: AnyObject) {
        Player.instance.setIsHost(false)
        Player.instance.setIsClueGiver(false)
        self.performSegueWithIdentifier("main-menu", sender: self)
    }
    
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MultipeerManager.instance.initPeerID(Player.instance.name)
        MultipeerManager.instance.initBrowser()
        MultipeerManager.instance.initSession()
        
        self.refreshTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(LobbyRoomViewController.refreshView), userInfo: nil, repeats: true)     // Refresh lobby every second
        
        self.joinGameAlertController = UIAlertController(title: "Joining Room", message: SpycodesMessage.joiningRoomString, preferredStyle: .Alert)
        
        self.emptyStateLabel = UILabel(frame: self.tableView.frame)
        self.emptyStateLabel?.text = "Rooms created will show here.\nMake sure Wifi is enabled."
        self.emptyStateLabel?.font = UIFont(name: "HelveticaNeue-UltraLight", size: 24)
        self.emptyStateLabel?.textAlignment = .Center
        self.emptyStateLabel?.numberOfLines = 0
        self.emptyStateLabel?.center = self.view.center
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        MultipeerManager.instance.delegate = self
        MultipeerManager.instance.startBrowser()
    }
    
    override func viewWillDisappear(animated: Bool) {
        MultipeerManager.instance.stopBrowser()
        self.refreshTimer?.invalidate()
        Lobby.instance = Lobby()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Private
    @objc
    private func refreshView() {
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
            if self.tableView.numberOfRowsInSection(0) == 0 {
                self.tableView.backgroundView = self.emptyStateLabel
            }
            else {
                self.tableView.backgroundView = nil
            }
        })
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier) as! LobbyRoomViewCell
        let roomAtIndex = Lobby.instance.rooms[indexPath.row]
        cell.roomName = roomAtIndex.name
        cell.roomNameLabel.text = String(indexPath.row + 1) + ". " + roomAtIndex.name
        
        cell.delegate = self
        
        return cell
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Lobby.instance.rooms.count
    }
    
    // MARK: LobbyRoomViewCellDelegate
    func joinGameWithName(name: String) {
        // Start advertising to allow host room to invite into session
        MultipeerManager.instance.initDiscoveryInfo(["joinRoom": name])
        MultipeerManager.instance.initAdvertiser()
        MultipeerManager.instance.startAdvertiser()
        
        self.presentViewController(self.joinGameAlertController!, animated: true, completion: nil)
    }
    
    // MARK: MultipeerManagerDelegate
    func foundPeer(peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        if let name = info?["room-name"], uuid = info?["room-uuid"] where !Lobby.instance.hasRoomWithUUID(uuid) {
            Lobby.instance.addRoomWithNameAndUUID(name, uuid: uuid)
        }
    }
    
    func lostPeer(peerID: MCPeerID) {
        Lobby.instance.removeRoomWithUUID(peerID.displayName)
    }
    
    // Navigate to pregame room only when preliminary sync data from host is received
    func didReceiveData(data: NSData, fromPeer peerID: MCPeerID) {
        if let room = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Room {
            Room.instance = room
            
            // Inform the room host of local player info
            let data = NSKeyedArchiver.archivedDataWithRootObject(Player.instance)
            MultipeerManager.instance.broadcastData(data)
            
            self.joinGameAlertController?.dismissViewControllerAnimated(true, completion: {
                dispatch_async(dispatch_get_main_queue(), {
                    self.performSegueWithIdentifier("pregame-room", sender: self)
                })
            })
        }
    }
    
    func newPeerAddedToSession(peerID: MCPeerID) {}
    
    func peerDisconnectedFromSession(peerID: MCPeerID) {}
}
