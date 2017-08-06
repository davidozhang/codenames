import UIKit

class SCPregameModalSecondaryViewController: SCViewController {
    fileprivate var refreshTimer: Foundation.Timer?

    enum Section: Int {
        case categories = 0
    }

    fileprivate let sectionLabels: [Section: String] = [
        .categories: SCStrings.section.categories.rawValue,
    ]

    fileprivate var scrolled = false

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewLeadingSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewTrailingSpaceConstraint: NSLayoutConstraint!

    deinit {
        print("[DEINIT] " + NSStringFromClass(type(of: self)))
    }

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 87.0

        self.tableViewBottomSpaceConstraint.constant = 0
        self.tableViewLeadingSpaceConstraint.constant = SCViewController.tableViewMargin
        self.tableViewTrailingSpaceConstraint.constant = SCViewController.tableViewMargin
        self.tableView.layoutIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        SCStates.pregameModalPageState = .secondary

        self.tableView.dataSource = self
        self.tableView.delegate = self

        self.view.isOpaque = false
        self.view.backgroundColor = .clear

        self.refreshTimer = Foundation.Timer.scheduledTimer(
            timeInterval: 2.0,
            target: self,
            selector: #selector(SCPregameModalSecondaryViewController.refreshView),
            userInfo: nil,
            repeats: true
        )

        let multilineToggleNib = UINib(nibName: SCConstants.nibs.multilineToggle.rawValue, bundle: nil)

        if Player.instance.isHost() {
            for categoryTuple in ConsolidatedCategories.instance.getConsolidatedCategoryInfo() {
                self.tableView.register(
                    multilineToggleNib,
                    forCellReuseIdentifier: categoryTuple.name
                )
            }
        } else {
            for categoryString in ConsolidatedCategories.instance.getSynchronizedCategories() {
                self.tableView.register(
                    multilineToggleNib,
                    forCellReuseIdentifier: categoryString
                )
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.tableView.dataSource = nil
        self.tableView.delegate = nil

        self.refreshTimer?.invalidate()
    }

    // MARK: Private
    @objc
    fileprivate func refreshView() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    fileprivate func showAlert(title: String, reason: String, completionHandler: ((Void) -> Void)?) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(
                title: title,
                message: reason,
                preferredStyle: .alert
            )
            let confirmAction = UIAlertAction(
                title: SCStrings.button.ok.rawValue,
                style: .default,
                handler: nil
            )
            alertController.addAction(confirmAction)
            self.present(
                alertController,
                animated: true,
                completion: completionHandler
            )
        }
    }

    fileprivate func checkWordCount(failureHandler: ((Void) -> Void)?) {
        if ConsolidatedCategories.instance.getTotalWords() < SCConstants.constant.cardCount.rawValue {
            self.showAlert(
                title: SCStrings.header.minimumWords.rawValue,
                reason: String(format: SCStrings.message.minimumWords.rawValue, SCConstants.constant.cardCount.rawValue),
                completionHandler: {
                    if let failureHandler = failureHandler {
                        failureHandler()
                    }
                }
            )
        }
    }
}

//   _____      _                 _
//  | ____|_  _| |_ ___ _ __  ___(_) ___  _ __  ___
//  |  _| \ \/ / __/ _ \ '_ \/ __| |/ _ \| '_ \/ __|
//  | |___ >  <| ||  __/ | | \__ \ | (_) | | | \__ \
//  |_____/_/\_\\__\___|_| |_|___/_|\___/|_| |_|___/

// MARK: SCSectionHeaderViewCellDelegate
extension SCPregameModalSecondaryViewController: SCSectionHeaderViewCellDelegate {
    func onSectionHeaderButtonTapped() {
        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: SCConstants.notificationKey.dismissModal.rawValue),
            object: self,
            userInfo: [
                SCConstants.notificationKey.intent.rawValue: SCConstants.notificationKey.customCategory.rawValue
            ]
        )
    }
}

// MARK: SCToggleViewCellDelegate
extension SCPregameModalSecondaryViewController: SCToggleViewCellDelegate {
    func onToggleChanged(_ cell: SCToggleViewCell, enabled: Bool) {
        guard let reuseIdentifier = cell.reuseIdentifier else {
            return
        }

        if let category = SCWordBank.getCategoryFromString(string: reuseIdentifier) {       // Default categories
            if enabled {
                ConsolidatedCategories.instance.addCategory(category: category)
            } else {
                ConsolidatedCategories.instance.removeCategory(category: category)
            }

            self.checkWordCount(
                failureHandler: {
                    // Revert setting if total word count is less than minimum allowed
                    cell.toggleSwitch.isOn = !enabled
                    ConsolidatedCategories.instance.addCategory(category: category)
                }
            )
        } else if let category = ConsolidatedCategories.instance.getCustomCategoryFromString(string: reuseIdentifier) {     // Custom categories
            if enabled {
                ConsolidatedCategories.instance.addCustomCategory(category: category)
            } else {
                ConsolidatedCategories.instance.removeCustomCategory(category: category)
            }

            self.checkWordCount(
                failureHandler: {
                    // Revert setting if total word count is less than minimum allowed
                    cell.toggleSwitch.isOn = !enabled
                    ConsolidatedCategories.instance.addCustomCategory(category: category)
                }
            )
        }
    }
}

// MARK: UITableViewDelegate, UITableViewDataSource
extension SCPregameModalSecondaryViewController: UITableViewDataSource, UITableViewDelegate {
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

        sectionHeader.delegate = self

        if !Player.instance.isHost() {
            sectionHeader.hideButton()
        }

        if let section = Section(rawValue: section) {
            sectionHeader.primaryLabel.text = self.sectionLabels[section]
        }

        if self.scrolled {
            sectionHeader.showBlurBackground()
        } else {
            sectionHeader.hideBlurBackground()
        }

        return sectionHeader
    }

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.categories.rawValue:
            if Player.instance.isHost() {
                return ConsolidatedCategories.instance.getConsolidatedCategoriesCount()
            } else {
                return ConsolidatedCategories.instance.getSynchronizedCategoriesCount()
            }
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Section.categories.rawValue:
            if Player.instance.isHost() {
                let categoryTuple = ConsolidatedCategories.instance.getConsolidatedCategoryInfo()[indexPath.row]

                guard let cell = self.tableView.dequeueReusableCell(
                    withIdentifier: categoryTuple.name
                ) as? SCToggleViewCell else {
                    return SCTableViewCell()
                }

                if let emoji = categoryTuple.emoji {
                    cell.primaryLabel.text = String(
                        format: SCStrings.primaryLabel.category.rawValue,
                        categoryTuple.name,
                        emoji
                    )
                }

                if categoryTuple.type == .customCategory {
                    // Custom label in place of emoji
                    cell.primaryLabel.text = String(
                        format: SCStrings.primaryLabel.category.rawValue,
                        categoryTuple.name,
                        SCStrings.primaryLabel.custom.rawValue
                    )
                }

                let wordCount = categoryTuple.wordCount
                cell.secondaryLabel.text = String(
                    format: SCStrings.secondaryLabel.numberOfWords.rawValue,
                    wordCount,
                    wordCount == 1 ?
                        SCStrings.secondaryLabel.word.rawValue :
                        SCStrings.secondaryLabel.words.rawValue
                )

                cell.setEnabled(enabled: true)

                cell.synchronizeToggle()
                cell.delegate = self

                return cell
            } else {
                // Non-host
                let categoryString = ConsolidatedCategories.instance.getSynchronizedCategories()[indexPath.row]

                guard let cell = self.tableView.dequeueReusableCell(
                    withIdentifier: categoryString
                ) as? SCToggleViewCell else {
                    return SCTableViewCell()
                }

                if let emoji = ConsolidatedCategories.instance.getSynchronizedEmojiForCategoryString(string: categoryString) {
                    cell.primaryLabel.text = String(
                        format: SCStrings.primaryLabel.category.rawValue,
                        categoryString,
                        emoji
                    )
                }

                if let type = ConsolidatedCategories.instance.getSynchronizedCategoryTypeForCategoryString(string: categoryString),
                   type == ConsolidatedCategories.CategoryType.customCategory {
                    cell.primaryLabel.text = String(
                        format: SCStrings.primaryLabel.category.rawValue,
                        categoryString,
                        SCStrings.primaryLabel.custom.rawValue
                    )
                }

                let wordCount = ConsolidatedCategories.instance.getSynchronizedWordCountForCategoryString(string: categoryString)
                cell.secondaryLabel.text = String(
                    format: SCStrings.secondaryLabel.numberOfWords.rawValue,
                    wordCount,
                    wordCount == 1 ?
                        SCStrings.secondaryLabel.word.rawValue :
                        SCStrings.secondaryLabel.words.rawValue
                )

                cell.setEnabled(enabled: false)

                cell.synchronizeToggle()
                cell.delegate = self

                return cell
            }
        default:
            return SCTableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !Player.instance.isHost() {
            self.showAlert(
                title: SCStrings.header.hostOnly.rawValue,
                reason: SCStrings.message.categorySetting.rawValue,
                completionHandler: nil
            )
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.tableView.contentOffset.y > 0 {
            if self.scrolled {
                return
            }
            self.scrolled = true

            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name(rawValue: SCConstants.notificationKey.disableSwipeGestureRecognizer.rawValue),
                    object: self,
                    userInfo: nil
                )
            }
        } else {
            if !self.scrolled {
                return
            }
            self.scrolled = false

            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name(rawValue: SCConstants.notificationKey.enableSwipeGestureRecognizer.rawValue),
                    object: self,
                    userInfo: nil
                )
            }
        }

        self.tableView.reloadData()
    }
}
