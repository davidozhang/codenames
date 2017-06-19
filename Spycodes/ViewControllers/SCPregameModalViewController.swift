import UIKit

protocol SCPregameModalViewControllerDelegate: class {
    func onNightModeToggleChanged()
}

class SCPregameModalViewController: SCModalViewController {
    weak var delegate: SCPregameModalViewControllerDelegate?
    fileprivate var refreshTimer: Foundation.Timer?

    enum Section: Int {
        case info = 0
        case gameSettings = 1
    }

    enum GameSetting: Int {
        case minigame = 0
        case timer = 1
    }

    fileprivate let sectionLabels: [Section: String] = [
        .info: SCStrings.section.info.rawValue,
        .gameSettings: SCStrings.section.gameSettings.rawValue,
    ]

    fileprivate let settingsLabels: [GameSetting: String] = [
        .minigame: SCStrings.primaryLabel.minigame.rawValue,
        .timer: SCStrings.primaryLabel.timer.rawValue,
    ]

    fileprivate var scrolled = false

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewLeadingSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewTrailingSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var upArrowView: UIImageView!

    deinit {
        print("[DEINIT] " + NSStringFromClass(type(of: self)))
    }

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 87.0
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableViewBottomSpaceConstraint.constant = SCViewController.tableViewMargin
        self.tableViewLeadingSpaceConstraint.constant = SCViewController.tableViewMargin
        self.tableViewTrailingSpaceConstraint.constant = SCViewController.tableViewMargin
        self.tableView.layoutIfNeeded()

        self.refreshTimer = Foundation.Timer.scheduledTimer(
            timeInterval: 2.0,
            target: self,
            selector: #selector(SCPregameModalViewController.refreshView),
            userInfo: nil,
            repeats: true
        )

        if self.tableView.contentSize.height <= self.tableView.bounds.height {
            self.upArrowView.isHidden = true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.tableView.dataSource = nil
        self.tableView.delegate = nil

        self.refreshTimer?.invalidate()
    }

    // MARK: SCModalViewController Overrides
    override func onDismissal() {
        if self.tableView.contentOffset.y > 0 {
            return
        }

        super.onDismissal()
    }

    // MARK: Private
    @objc
    fileprivate func refreshView() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    fileprivate func getChecklistItems() -> [String] {
        var result = [String]()

        // Team size check
        if Room.instance.teamSizesValid() {
            result.append(SCStrings.emoji.completed.rawValue)

            if GameMode.instance.getMode() == .miniGame {
                result.append(SCStrings.info.minigameTeamSizeSatisfied.rawValue)
            } else {
                result.append(SCStrings.info.regularGameTeamSizeSatisfied.rawValue)
            }
        } else {
            result.append(SCStrings.emoji.incomplete.rawValue)

            if GameMode.instance.getMode() == .miniGame {
                result.append(SCStrings.info.minigameTeamSizeUnsatisfied.rawValue)
            } else {
                result.append(SCStrings.info.regularGameTeamSizeUnsatisfied.rawValue)
            }
        }
        
        return result
    }
}

//   _____      _                 _
//  | ____|_  _| |_ ___ _ __  ___(_) ___  _ __  ___
//  |  _| \ \/ / __/ _ \ '_ \/ __| |/ _ \| '_ \/ __|
//  | |___ >  <| ||  __/ | | \__ \ | (_) | | | \__ \
//  |_____/_/\_\\__\___|_| |_|___/_|\___/|_| |_|___/

// MARK: UITableViewDelegate, UITableViewDataSource
extension SCPregameModalViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionLabels.count
    }

    func tableView(_ tableView: UITableView,
                   heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0
    }

    func tableView(_ tableView: UITableView,
                   viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionHeader = self.tableView.dequeueReusableCell(
            withIdentifier: SCConstants.identifier.sectionHeaderCell.rawValue
            ) as? SCSectionHeaderViewCell else {
                return nil
        }

        if let section = Section(rawValue: section) {
            sectionHeader.primaryLabel.text = self.sectionLabels[section]
        }

        if self.tableView.contentOffset.y > 0 {
            sectionHeader.showBlurBackground()
        } else {
            sectionHeader.hideBlurBackground()
        }

        return sectionHeader
    }

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.info.rawValue:
            return 2
        case Section.gameSettings.rawValue:
            return settingsLabels.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Section.info.rawValue:
            guard let cell = self.tableView.dequeueReusableCell(
                withIdentifier: SCConstants.identifier.infoViewCell.rawValue
                ) as? SCTableViewCell else {
                    return SCTableViewCell()
            }

            cell.primaryLabel.font = SCFonts.regularSizeFont(.regular)
            cell.primaryLabel.numberOfLines = 2

            switch indexPath.row {
            case 0: // Start game checklist
                let checkListItems = self.getChecklistItems()
                cell.leftLabel.text = checkListItems[0]
                cell.primaryLabel.text = checkListItems[1]
            case 1: // Leader nomination info
                cell.leftLabel.text = SCStrings.emoji.info.rawValue
                cell.primaryLabel.text = SCStrings.info.leaderNomination.rawValue
            default:
                break
            }

            return cell
        case Section.gameSettings.rawValue:
            switch indexPath.row {
            case GameSetting.minigame.rawValue:
                guard let cell = self.tableView.dequeueReusableCell(
                    withIdentifier: SCConstants.identifier.minigameToggleViewCell.rawValue
                    ) as? SCToggleViewCell else {
                        return SCTableViewCell()
                }

                cell.synchronizeToggle()
                cell.primaryLabel.text = self.settingsLabels[.minigame]
                cell.secondaryLabel.text = SCStrings.secondaryLabel.minigame.rawValue
                cell.delegate = self
                
                return cell
            case GameSetting.timer.rawValue:
                guard let cell = self.tableView.dequeueReusableCell(
                    withIdentifier: SCConstants.identifier.timerToggleViewCell.rawValue
                    ) as? SCToggleViewCell else {
                        return SCTableViewCell()
                }

                cell.synchronizeToggle()
                cell.primaryLabel.text = self.settingsLabels[.timer]
                cell.secondaryLabel.text = SCStrings.secondaryLabel.timer.rawValue
                cell.delegate = self

                return cell
            default:
                return SCTableViewCell()
            }
        default:
            return SCTableViewCell()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.tableView.contentOffset.y <= 0 {
            self.upArrowView.isHidden = false
        } else {
            self.upArrowView.isHidden = true
        }

        if self.tableView.contentOffset.y > 0 {
            if self.scrolled {
                return
            }
            self.scrolled = true
        } else {
            if !self.scrolled {
                return
            }
            self.scrolled = false
        }

        self.tableView.reloadData()
    }
}

// MARK: SCToggleViewCellDelegate
extension SCPregameModalViewController: SCToggleViewCellDelegate {
    func onToggleChanged(_ cell: SCToggleViewCell, enabled: Bool) {
        if let reuseIdentifier = cell.reuseIdentifier {
            switch reuseIdentifier {
            case SCConstants.identifier.minigameToggleViewCell.rawValue:
                if enabled {
                    GameMode.instance.setMode(mode: .miniGame)
                } else {
                    GameMode.instance.setMode(mode: .regularGame)
                }

                self.tableView.reloadData()

                Room.instance.resetPlayers()

                if GameMode.instance.getMode() == .miniGame {
                    Room.instance.addCPUPlayer()
                } else {
                    Room.instance.removeCPUPlayer()
                }

                SCMultipeerManager.instance.broadcast(GameMode.instance)
                SCMultipeerManager.instance.broadcast(Room.instance)
            case SCConstants.identifier.accessibilityToggleViewCell.rawValue:
                SCSettingsManager.instance.enableLocalSetting(.accessibility, enabled: enabled)
            case SCConstants.identifier.timerToggleViewCell.rawValue:
                Timer.instance.setEnabled(enabled)

                SCMultipeerManager.instance.broadcast(Timer.instance)
            case SCConstants.identifier.nightModeToggleViewCell.rawValue:
                SCSettingsManager.instance.enableLocalSetting(.nightMode, enabled: enabled)
                super.updateModalAppearance()
                self.tableView.reloadData()
                self.delegate?.onNightModeToggleChanged()
            default:
                break
            }
        }
    }
}
