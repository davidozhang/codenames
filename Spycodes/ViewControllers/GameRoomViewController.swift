import MultipeerConnectivity
import UIKit

class GameRoomViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, MultipeerManagerDelegate, UITextFieldDelegate {
    private let reuseIdentifier = "game-room-view-cell"
    private let edgeInset: CGFloat = 12
    private let playerDisconnectedString = "A player from your team has disconnected."
    
    private var broadcastTimer: NSTimer?
    private var refreshTimer: NSTimer?
    
    private var playerRoundStarted = false
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var clueTextField: UITextField!
    @IBOutlet weak var numberOfWordsTextField: UITextField!
    @IBOutlet weak var cardsRemainingLabel: UILabel!
    @IBOutlet weak var teamLabel: UILabel!
    
    @IBOutlet weak var endRoundButton: SpycodesButton!
    @IBOutlet weak var confirmButton: UIButton!
    
    @IBAction func onConfirmPressed(sender: AnyObject) {
        self.didConfirm()
    }
    
    @IBAction func onEndRoundPressed(sender: AnyObject) {
        self.didEndRound()
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        MultipeerManager.instance.delegate = self
        
        Round.instance.setStartingTeam(CardCollection.instance.startingTeam)
        
        if Player.instance.isHost() {
            self.broadcastTimer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: #selector(GameRoomViewController.broadcastData), userInfo: nil, repeats: true)  // Broadcast host's card collection every 2 seconds
        }
        
        if Player.instance.isClueGiver() {
            self.endRoundButton.hidden = false
        } else {
            self.endRoundButton.hidden = true
        }
        
        self.refreshTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(GameRoomViewController.refreshView), userInfo: nil, repeats: true)    // Refresh room every second
        
        self.teamLabel.text = Player.instance.team == Team.Red ? "Red" : "Blue"
        self.confirmButton.hidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        if Player.instance.isHost() {
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
            self.updateDashboard()
            self.updateEndRoundButton()
            self.updateConfirmButton()
            self.collectionView.reloadData()
        })
    }
    
    @objc
    private func broadcastData() {
        var data = NSKeyedArchiver.archivedDataWithRootObject(CardCollection.instance)
        MultipeerManager.instance.broadcastData(data)
        
        data = NSKeyedArchiver.archivedDataWithRootObject(Round.instance)
        MultipeerManager.instance.broadcastData(data)
        
        data = NSKeyedArchiver.archivedDataWithRootObject(Statistics.instance)
        MultipeerManager.instance.broadcastData(data)
    }
    
    private func updateDashboard() {
        self.cardsRemainingLabel.text = String(CardCollection.instance.getCardsRemainingForTeam(Player.instance.team))
        
        if Round.instance.currentTeam == Player.instance.team {
            if self.clueTextField.isFirstResponder() || self.numberOfWordsTextField.isFirstResponder() {
                return  // Cluegiver is editing the clue/number of words
            }
            
            if Round.instance.isClueSet() {
                self.clueTextField.text = Round.instance.clue
            }
            else {
                if Player.instance.isClueGiver() {
                    self.clueTextField.text = Round.defaultClueGiverClue
                    self.confirmButton.hidden = false
                    if Round.instance.isClueSet() && Round.instance.isNumberOfWordsSet() {
                        self.clueTextField.enabled = false
                        self.numberOfWordsTextField.enabled = false
                    } else {
                        self.clueTextField.enabled = true
                        self.numberOfWordsTextField.enabled = true
                    }
                }
                else {
                   self.clueTextField.text = Round.defaultIsTurnClue
                }
            }
            
            if Round.instance.isNumberOfWordsSet() {
                self.numberOfWordsTextField.text = Round.instance.numberOfWords
            }
            else {
                self.numberOfWordsTextField.text = Round.defaultNumberOfWords
            }
        } else {
            self.clueTextField.text = Round.defaultNonTurnClue
            self.numberOfWordsTextField.text = Round.defaultNumberOfWords
        }
    }
    
    private func updateEndRoundButton() {
        if !Player.instance.isClueGiver() {
            return
        }
        
        if Round.instance.currentTeam == Player.instance.team {
            self.endRoundButton.alpha = 1.0
            self.endRoundButton.enabled = true
        }
        else {
            self.endRoundButton.alpha = 0.3
            self.endRoundButton.enabled = false
        }
    }
    
    private func updateConfirmButton() {
        if !Player.instance.isClueGiver() || Round.instance.currentTeam != Player.instance.team {
            return
        }
        
        if self.clueTextField.text?.characters.count > 0 && self.clueTextField.text != Round.defaultClueGiverClue && self.numberOfWordsTextField.text?.characters.count > 0 && self.numberOfWordsTextField.text != Round.defaultNumberOfWords {
            self.confirmButton.alpha = 1.0
            self.confirmButton.enabled = true
        } else {
            self.confirmButton.alpha = 0.3
            self.confirmButton.enabled = false
        }
    }
    
    private func didConfirm() {
        Round.instance.clue = self.clueTextField.text
        Round.instance.numberOfWords = self.numberOfWordsTextField.text
        self.clueTextField.enabled = false
        self.numberOfWordsTextField.enabled = false
        self.confirmButton.hidden = true
        self.broadcastData()
    }
    
    private func didEndRound() {
        Round.instance.endRound(Player.instance.team)
        self.broadcastData()
    }
    
    private func didEndGame(reason reason: String) {
        if Player.instance.isHost() {
            self.broadcastTimer?.invalidate()
        }
        self.refreshTimer?.invalidate()
        
        let alertController = UIAlertController(title: "Game Over", message: reason, preferredStyle: .Alert)
        let confirmAction = UIAlertAction(title: "OK", style: .Default, handler: { (action: UIAlertAction) in
            self.performSegueWithIdentifier("pregame-room", sender: self)
        })
        alertController.addAction(confirmAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: MultipeerManagerDelegate
    func foundPeer(peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {}
    
    func lostPeer(peerID: MCPeerID) {}
    
    func didReceiveData(data: NSData, fromPeer peerID: MCPeerID) {
        if let cardCollection = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? CardCollection {
            CardCollection.instance = cardCollection
        }
        else if let round = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Round {
            Round.instance = round
            if Round.instance.winningTeam == Player.instance.team {
                self.didEndGame(reason: Round.defaultWinString)
                return
            }
            else if Round.instance.winningTeam == Team(rawValue: Player.instance.team.rawValue ^ 1) {
                self.didEndGame(reason: Round.defaultLoseString)
                return
            }
            
            if Round.instance.currentTeam == Player.instance.team {
                if !playerRoundStarted {
                    AudioToolboxManager.instance.vibrate()
                    playerRoundStarted = true
                }
            } else {
                playerRoundStarted = false
            }
        }
        else if let statistics = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Statistics {
            Statistics.instance = statistics
        }
    }
    
    func newPeerAddedToSession(peerID: MCPeerID) {}
    
    func peerDisconnectedFromSession(peerID: MCPeerID) {
        if let peer = Room.instance.connectedPeers[peerID], player = Room.instance.getPlayerWithUUID(peer) where player.team == Player.instance.team {
            let alertController = UIAlertController(title: "Oops", message: self.playerDisconnectedString, preferredStyle: .Alert)
            let confirmAction = UIAlertAction(title: "OK", style: .Default, handler: { (action: UIAlertAction) in })
            alertController.addAction(confirmAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: UICollectionViewDelegate
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 25
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.reuseIdentifier, forIndexPath: indexPath) as! GameRoomViewCell
        let cardAtIndex = CardCollection.instance.cards[indexPath.row]
        
        cell.wordLabel.text = cardAtIndex.getWord()
        
        cell.contentView.backgroundColor = UIColor.clearColor()
        
        if Player.instance.isClueGiver() {
            cell.contentView.backgroundColor = UIColor.colorForTeam(cardAtIndex.getTeam())
            var attributedString: NSMutableAttributedString =  NSMutableAttributedString(string: cardAtIndex.getWord())
            if cardAtIndex.getTeam() == Player.instance.team {
                attributedString = NSMutableAttributedString(string: cardAtIndex.getWord(), attributes: [NSFontAttributeName : UIFont(name: "HelveticaNeue-Light", size: 20)!])
            }
            if cardAtIndex.isSelected() {
                attributedString.addAttribute(NSStrikethroughStyleAttributeName, value: 1, range: NSMakeRange(0, attributedString.length))
            }
            cell.wordLabel.attributedText = attributedString
            return cell
        }
        
        if cardAtIndex.isSelected() {
            cell.contentView.backgroundColor = UIColor.colorForTeam(cardAtIndex.getTeam())
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if Player.instance.isClueGiver() || Round.instance.currentTeam != Player.instance.team {
            return
        }
        
        CardCollection.instance.cards[indexPath.row].setSelected()
        self.broadcastData()
        
        let cardAtIndex = CardCollection.instance.cards[indexPath.row]
        let cardAtIndexTeam = cardAtIndex.getTeam()
        let playerTeam = Player.instance.team
        let opponentTeam = Team(rawValue: playerTeam.rawValue ^ 1)
        
        if cardAtIndexTeam == Team.Neutral || cardAtIndexTeam == opponentTeam {
            self.didEndRound()
        }
        
        if cardAtIndexTeam == Team.Assassin || CardCollection.instance.getCardsRemainingForTeam(opponentTeam!) == 0 {
            Round.instance.winningTeam = opponentTeam
            Statistics.instance.recordWinForTeam(opponentTeam!)
            self.broadcastData()
            self.didEndGame(reason: Round.defaultLoseString)
        }
        else if CardCollection.instance.getCardsRemainingForTeam(playerTeam) == 0 {
            Round.instance.winningTeam = playerTeam
            Statistics.instance.recordWinForTeam(playerTeam)
            self.broadcastData()
            self.didEndGame(reason: Round.defaultWinString)
        }
    }
    
    // Cell Size
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: 150, height: 50)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(edgeInset, edgeInset, edgeInset, edgeInset)
    }
    
    // MARK: UITextFieldDelegate
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if Player.instance.isClueGiver() && Round.instance.currentTeam == Player.instance.team {
            return true
        } else {
            return false
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == self.clueTextField && textField.text?.characters.count >= 1 {
            self.numberOfWordsTextField.becomeFirstResponder()
        } else if textField == self.numberOfWordsTextField {
            self.numberOfWordsTextField.resignFirstResponder()
            self.didConfirm()
        }
        
        return true
    }
}
