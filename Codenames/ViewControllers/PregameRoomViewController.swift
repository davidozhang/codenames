import MultipeerConnectivity
import UIKit

class PregameRoomViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, MultipeerManagerDelegate, PregameRoomViewCellDelegate {
    private let identifier = "pregame-room-view-cell"
    private let hostDisconnectedString = "Host player has been disconnected."
    private let removedFromRoomString = "You have been removed from the room."
    private let cannotStartGameString = "Check the following:\n1. Tap on a player's name to select as clue giver. There must be 1 clue giver on each team.\n2. 4 or more players are required with at least 2 players on each team."
    
    var cardCollection = CardCollection.instance
    var round = Round.instance
    
    var player = Player.instance
    var room = Room.instance
    var multipeerManager = MultipeerManager.instance
    
    private var broadcastTimer: NSTimer?
    private var refreshTimer: NSTimer?
    private var connectedPeers = [MCPeerID: String]()  // Mapping between Peer ID to UUID String
    
    private var editNameTextField: UITextField?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var startGame: SpycodeButton!
    
    @IBAction func onStartGame(sender: AnyObject) {
        if self.room.canStartGame() {
            self.goToGame()
        } else {
            let alertController = UIAlertController(title: "Cannot Start Game", message: self.cannotStartGameString, preferredStyle: .Alert)
            let confirmAction = UIAlertAction(title: "OK", style: .Default, handler: { (action: UIAlertAction) in })
            alertController.addAction(confirmAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.multipeerManager.delegate = self
        
        if player.isHost() {
            self.multipeerManager.initPeerID(room.getRoomName())
            self.multipeerManager.initDiscoveryInfo(["isHost": "yes"])
            self.multipeerManager.initSession()
            self.multipeerManager.initAdvertiser()
            self.multipeerManager.initBrowser()
            
            self.multipeerManager.startAdvertiser()
            self.multipeerManager.startBrowser()
            
            self.startGame.hidden = false
            
            if let peerID = self.multipeerManager.getPeerID() {
                // Host should add itself to the connected peers
                self.connectedPeers[peerID] = self.player.getPlayerUUID()
            }
            
            self.broadcastTimer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: #selector(PregameRoomViewController.broadcastData), userInfo: nil, repeats: true)      // Broadcast host's room every 2 seconds
        }
        else {
            self.startGame.hidden = true
        }
        
        self.refreshTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(PregameRoomViewController.refreshView), userInfo: nil, repeats: true)     // Refresh room every second
        
        roomNameLabel.text = self.room.getRoomName()
    }
    
    override func viewWillDisappear(animated: Bool) {
        if self.player.isHost() {
            self.broadcastTimer?.invalidate()
        }
        self.refreshTimer?.invalidate()
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
    
    @objc
    private func broadcastData() {
        var data = NSKeyedArchiver.archivedDataWithRootObject(self.room)
        self.multipeerManager.broadcastData(data)
        
        data = NSKeyedArchiver.archivedDataWithRootObject(self.connectedPeers)
        self.multipeerManager.broadcastData(data)
    }
    
    private func goToGame() {
        dispatch_async(dispatch_get_main_queue(), {
            self.performSegueWithIdentifier("game-room", sender: self)
        })
    }
    
    private func returnToLobby(reason reason: String) {
        let alertController = UIAlertController(title: "Returning To Lobby", message: reason, preferredStyle: .Alert)
        let confirmAction = UIAlertAction(title: "OK", style: .Default, handler: { (action: UIAlertAction) in
            dispatch_async(dispatch_get_main_queue(), {
                self.performSegueWithIdentifier("lobby-room", sender: self)
            })
        })
        alertController.addAction(confirmAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "lobby-room" {
            if let lobbyRoomViewController = segue.destinationViewController as? LobbyRoomViewController {
                if self.player.isHost() {
                    self.broadcastTimer?.invalidate()
                }
                self.refreshTimer?.invalidate()
                self.multipeerManager.terminate()
                self.connectedPeers.removeAll()
                lobbyRoomViewController.lobby = Lobby()
                lobbyRoomViewController.room = Room()
                lobbyRoomViewController.multipeerManager = self.multipeerManager
            }
        } else if segue.identifier == "game-room" {
            if let gameRoomViewController = segue.destinationViewController as? GameRoomViewController {
                if let player = self.room.getPlayerWithUUID(self.player.uuid) {
                    gameRoomViewController.player = player
                    gameRoomViewController.round = self.round
                    gameRoomViewController.cardCollection = self.cardCollection
                    gameRoomViewController.multipeerManager = self.multipeerManager
                    gameRoomViewController.room = self.room
                    gameRoomViewController.connectedPeers = self.connectedPeers
                }
            }
        }
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier) as! PregameRoomViewCell
        let playerAtIndex = room.getPlayers()[indexPath.row]
        cell.nameLabel.text = String(indexPath.row + 1) + ". " + playerAtIndex.getPlayerName()
        
        // Determine team switch color
        if playerAtIndex.getTeam() == Team.Red {
            cell.teamSwitch.on = true
        } else {
            cell.teamSwitch.on = false
        }
        
        // Only host player can remove players
        if player.isHost() {
            cell.removeButton.hidden = false
        } else {
            cell.removeButton.hidden = true
        }
        
        if player == playerAtIndex {
            cell.removeButton.hidden = true
            cell.editButton.hidden = false
            cell.teamSwitch.enabled = true
        } else {
            cell.editButton.hidden = true
            cell.teamSwitch.enabled = false
        }
        
        if playerAtIndex.isClueGiver() {
            if playerAtIndex.getTeam() == Team.Red {
                cell.contentView.backgroundColor = UIColor.spycodeLightRedColor()
            }
            else {
                cell.contentView.backgroundColor = UIColor.spycodeLightBlueColor()
            }
            cell.nameLabel.font = UIFont(name: "HelveticaNeue-Light", size: 32)
        } else {
            cell.contentView.backgroundColor = UIColor.clearColor()
            cell.nameLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 32)
        }
        
        cell.index = indexPath.row
        
        cell.delegate = self
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let playerAtIndex = self.room.getPlayers()[indexPath.row]
        let team = playerAtIndex.getTeam()
        if let clueGiverUUID = self.room.getClueGiverUUIDForTeam(team) {
            self.room.getPlayerWithUUID(clueGiverUUID)?.setIsClueGiver(false)
        }
        self.room.getPlayers()[indexPath.row].setIsClueGiver(!playerAtIndex.isClueGiver())
        self.broadcastData()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.room.getNumberOfPlayers()
    }
    
    // MARK: MultipeerManagerDelegate
    func foundPeer(peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        if let info = info where info["joinRoom"] == room.getRoomName() {
            // Invite peer that explicitly advertised discovery info containing joinRoom entry that has the name of the host room
            self.multipeerManager.invitePeerToSession(peerID)
        }
    }
    
    func lostPeer(peerID: MCPeerID) {}
    
    func didReceiveData(data: NSData, fromPeer peerID: MCPeerID) {
        if let player = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Player {
            self.connectedPeers[peerID] = player.getPlayerUUID()
            if self.player.isHost() {
                self.room.addPlayer(player)
            }
        }
        else if let room = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Room {
            self.room = room
            
            // Room has been terminated or local player has been removed from room
            if self.room.getNumberOfPlayers() == 0 {
                self.returnToLobby(reason: self.hostDisconnectedString)
            }
            else if !self.room.playerWithUUIDInRoom(self.player.getPlayerUUID()) {
                self.returnToLobby(reason: self.removedFromRoomString)
            }
        }
        else if let connectedPeers = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [MCPeerID: String] {
            self.connectedPeers = connectedPeers
        }
        else if let cardCollection = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? CardCollection {
            self.cardCollection = cardCollection
        }
        else if let round = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Round {
            self.round = round
            self.goToGame()
        }
    }
    
    func newPeerAddedToSession(peerID: MCPeerID) {}
    
    func peerDisconnectedFromSession(peerID: MCPeerID) {
        if let playerUUID = self.connectedPeers[peerID] {
            if let player = self.room.getPlayerWithUUID(playerUUID) {
                // Room has been terminated if host player is disconnected
                if player.isHost() {
                    self.room.removeAllPlayers()
                    self.returnToLobby(reason: self.hostDisconnectedString)
                    return
                }
            }
            
            self.room.removePlayerWithUUID(playerUUID)
            self.connectedPeers.removeValueForKey(peerID)
        }
    }
    
    // MARK: PregameRoomViewCellDelegate
    func removePlayerAtIndex(index: Int) {
        self.room.removePlayerAtIndex(index)
    }
    
    func editPlayerAtIndex(index: Int) {
        let alertController = UIAlertController(title: "Edit Name", message: "Enter a different name", preferredStyle: .Alert)
        alertController.addTextFieldWithConfigurationHandler { (textField: UITextField) in
            self.editNameTextField = textField
            textField.delegate = self
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (alertAction: UIAlertAction) in }
        let confirmAction = UIAlertAction(title: "OK", style: .Default) { (alertAction: UIAlertAction) in
            if let newName = self.editNameTextField?.text {
                self.room.setNameOfPlayerAtIndex(index, name: newName)
                if (!self.player.isHost()) {
                    self.broadcastData()
                }
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func teamDidChange(redTeam: Bool) {
        if redTeam {
            self.room.getPlayerWithUUID(self.player.getPlayerUUID())?.setTeam(Team.Red)
        } else {
            self.room.getPlayerWithUUID(self.player.getPlayerUUID())?.setTeam(Team.Blue)
        }
        self.room.getPlayerWithUUID(self.player.getPlayerUUID())?.setIsClueGiver(false)
        self.broadcastData()
    }
    
    // MARK: UITextFieldDelegate
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        guard let text = self.editNameTextField?.text else { return true }
        
        let length = text.characters.count + string.characters.count - range.length
        return length <= 8
    }
}
