import UIKit

protocol SCToggleViewCellDelegate: class {
    func onToggleChanged(_ cell: SCToggleViewCell, enabled: Bool)
}

class SCToggleViewCell: SCTableViewCell {
    weak var delegate: SCToggleViewCellDelegate?

    let toggleSwitch = UISwitch()

    override func awakeFromNib() {
        super.awakeFromNib()

        toggleSwitch.addTarget(
            self,
            action: #selector(SCToggleViewCell.onToggleChanged(_:)),
            for: .valueChanged
        )

        self.synchronizeToggle()

        self.accessoryView = toggleSwitch
    }

    deinit {
        self.toggleSwitch.removeTarget(
            self,
            action: #selector(SCToggleViewCell.onToggleChanged(_:)),
            for: .valueChanged
        )
        self.delegate = nil
    }

    func synchronizeToggle() {
        if let reuseIdentifier = self.reuseIdentifier {
            switch reuseIdentifier {
            case SCConstants.identifier.nightModeToggleViewCell.rawValue:
                toggleSwitch.isOn = SCSettingsManager.instance.isLocalSettingEnabled(.nightMode)
            case SCConstants.identifier.accessibilityToggleViewCell.rawValue:
                toggleSwitch.isOn = SCSettingsManager.instance.isLocalSettingEnabled(.accessibility)
            case SCConstants.identifier.minigameToggleViewCell.rawValue:
                toggleSwitch.isOn = GameMode.instance.getMode() == .miniGame
            default:
                if Player.instance.isHost() {
                    // Retrieve from local data
                    if let category = SCWordBank.getCategoryFromString(string: reuseIdentifier) {
                        toggleSwitch.isOn = ConsolidatedCategories.instance.isCategorySelected(category: category)
                    } else if let category = ConsolidatedCategories.instance.getCustomCategoryFromString(string: reuseIdentifier) {
                        toggleSwitch.isOn = ConsolidatedCategories.instance.isCustomCategorySelected(category: category)
                    }
                } else {
                    // Retrieve from synchronized data
                    let categoryString = reuseIdentifier
                    toggleSwitch.isOn = ConsolidatedCategories.instance.isSynchronizedCategoryStringSelected(string: categoryString)
                }

                break
            }
        }
    }

    func setEnabled(enabled: Bool) {
        toggleSwitch.isEnabled = enabled
        if enabled {
            self.alpha = 1.0
        } else {
            self.alpha = 0.4
        }
    }

    @objc
    fileprivate func onToggleChanged(_ toggleSwitch: UISwitch) {
        let enabled = toggleSwitch.isOn
        delegate?.onToggleChanged(self, enabled: enabled)
    }
}
