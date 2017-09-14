import UIKit

class SCMainViewController: SCViewController {
    @IBOutlet weak var logoLabel: SCLogoLabel!
    @IBOutlet weak var createGameButton: SCButton!
    @IBOutlet weak var joinGameButton: SCButton!

    // MARK: Actions
    @IBAction func unwindToMainMenu(_ sender: UIStoryboardSegue) {
        super.unwindedToSelf(sender)
    }

    @IBAction func onCreateGame(_ sender: AnyObject) {
        Player.instance.setIsHost(true)
        self.performSegue(
            withIdentifier: SCConstants.identifier.playerNameViewController.rawValue,
            sender: self
        )
    }

    @IBAction func onJoinGame(_ sender: AnyObject) {
        self.performSegue(
            withIdentifier: SCConstants.identifier.playerNameViewController.rawValue,
            sender: self
        )
    }

    deinit {
        print("[DEINIT] " + NSStringFromClass(type(of: self)))
    }

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Currently this view is the root view controller for unwinding logic
        self.viewControllerIdentifier = SCConstants.identifier.mainMenu.rawValue
        self.isRootViewController = true

        SCAppInfoManager.checkLatestAppVersion {
            // If not on latest app version
            DispatchQueue.main.async {
                self.showUpdateAppAlert()
            }
        }

        self.logoLabel.text = SCStrings.appName.localized

        self.createGameButton.setTitle(
            SCStrings.button.createGame.rawValue.localized,
            for: .normal
        )

        self.joinGameButton.setTitle(
            SCStrings.button.joinGame.rawValue.localized,
            for: .normal
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        ConsolidatedCategories.instance.reset()
        Player.instance.reset()
        GameMode.instance.reset()
        Statistics.instance.reset()
        Room.instance.reset()
        Timer.instance.reset()
        SCStates.resetAll()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super._prepareForSegue(segue, sender: sender)

        // All segues identified here should be forward direction only
        if let vc = segue.destination as? SCMainSettingsViewController {
            vc.delegate = self
        }
    }

    override func swipeUp() {
        self.performSegue(
            withIdentifier: SCConstants.identifier.mainMenuModal.rawValue,
            sender: self
        )
    }

    // MARK: Private
    fileprivate func showUpdateAppAlert() {
        let alertController = UIAlertController(
            title: SCStrings.header.updateApp.rawValue,
            message: SCStrings.message.updatePrompt.rawValue,
            preferredStyle: .alert
        )
        let confirmAction = UIAlertAction(
            title: "Download",
            style: .default,
            handler: { (action: UIAlertAction) in
                if let appStoreURL = URL(string: SCConstants.url.appStore.rawValue) {
                    UIApplication.shared.openURL(appStoreURL)
                }
            }
        )
        alertController.addAction(confirmAction)
        self.present(
            alertController,
            animated: true,
            completion: nil
        )
    }
}

//   _____      _                 _
//  | ____|_  _| |_ ___ _ __  ___(_) ___  _ __  ___
//  |  _| \ \/ / __/ _ \ '_ \/ __| |/ _ \| '_ \/ __|
//  | |___ >  <| ||  __/ | | \__ \ | (_) | | | \__ \
//  |_____/_/\_\\__\___|_| |_|___/_|\___/|_| |_|___/

// MARK: SCMainSettingsViewControllerDelegate
extension SCMainViewController: SCMainSettingsViewControllerDelegate {
    func mainSettings(onToggleViewCellChanged toggleViewCell: SCToggleViewCell,
                      settingType: SCLocalStorageManager.LocalSettingType) {
        if settingType == .nightMode {
            DispatchQueue.main.async {
                super.updateAppearance()
            }
        }
    }
}
