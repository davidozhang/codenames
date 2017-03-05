import UIKit

class SCPlayerNameViewController: SCViewController, UITextFieldDelegate {
    @IBOutlet weak var userNameTextField: SCTextField!
    @IBOutlet weak var headerLabelTopMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var userNameTextFieldVerticalCenterConstraint: NSLayoutConstraint!
    
    // MARK: Actions
    @IBAction func unwindToPlayerName(sender: UIStoryboardSegue) {
        super.unwindedToSelf(sender)
    }
    
    @IBAction func onBackButtonTapped(sender: AnyObject) {
        super.performUnwindSegue(true, completionHandler: nil)
    }
    
    deinit {
        print("[DEINIT] " + NSStringFromClass(self.dynamicType))
    }
    
    // MARK: Lifecycle
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Unwindable view controller identifier
        self.unwindableIdentifier = "player-name"
        
        if let name = Player.instance.name where name.characters.count > 0 {
            self.userNameTextField.text = name
        }
        
        self.userNameTextField.delegate = self
        self.userNameTextField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.userNameTextField.delegate = nil
        self.userNameTextField.resignFirstResponder()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.userNameTextFieldVerticalCenterConstraint.constant = 0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super._prepareForSegue(segue, sender: sender)
    }
    
    override func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo, let frame = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let rect = frame.CGRectValue()
            self.userNameTextFieldVerticalCenterConstraint.constant = -(rect.height / 2 - self.headerLabelTopMarginConstraint.constant)
        }
    }
    
    // MARK: UITextFieldDelegate
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let name = self.userNameTextField.text where name.characters.count >= 1 {
            Player.instance.name = name
            
            if Room.instance.getPlayerWithUUID(Player.instance.getUUID()) == nil {
                Room.instance.addPlayer(Player.instance)
            }
            
            if Player.instance.isHost() {
                self.performSegueWithIdentifier("pregame-room", sender: self)
            } else {
                self.performSegueWithIdentifier("access-code", sender: self)
            }
            return true
        }
        else {
            return false
        }
    }
}
