import UIKit

class CreateGameViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var roomNameTextField: SpycodesTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.roomNameTextField.delegate = self
        self.roomNameTextField.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        guard let text = self.roomNameTextField.text else { return true }
        
        let length = text.characters.count + string.characters.count - range.length
        return length <= 8
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let name = self.roomNameTextField.text where name.characters.count >= 1 {
            Player.instance.setHost()
            Room.instance.setRoomName(name)
            Room.instance.addPlayer(Player.instance)
            
            performSegueWithIdentifier("join-game", sender: self)
            return true
        }
        else {
            return false
        }
    }
}
