import UIKit

class SCTimelineModalViewController: SCModalViewController {
    fileprivate var emptyStateLabel: UILabel?
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.refreshView()

        self.tableView.dataSource = self
        self.tableView.delegate = self

        self.tableViewBottomSpaceConstraint.constant = SCViewController.tableViewMargin
        self.tableViewLeadingSpaceConstraint.constant = SCViewController.tableViewMargin
        self.tableViewTrailingSpaceConstraint.constant = SCViewController.tableViewMargin
        self.tableView.layoutIfNeeded()

        self.emptyStateLabel = UILabel(frame: self.tableView.frame)
        self.emptyStateLabel?.text = SCStrings.timeline.emptyState.rawValue
        self.emptyStateLabel?.font = SCFonts.intermediateSizeFont(.regular)
        self.emptyStateLabel?.textColor = .spycodesGrayColor()
        self.emptyStateLabel?.textAlignment = .center
        self.emptyStateLabel?.numberOfLines = 0
        self.emptyStateLabel?.center = self.view.center

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(SCTimelineModalViewController.refreshView),
            name: NSNotification.Name(
                rawValue: SCConstants.notificationKey.timelineUpdated.rawValue
            ),
            object: nil
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.tableView.dataSource = nil
        self.tableView.delegate = nil

        Timeline.instance.markAllAsRead()

        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name(
                rawValue: SCConstants.notificationKey.timelineUpdated.rawValue
            ),
            object: nil
        )
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
            if Timeline.instance.getEvents().count == 0 {
                self.tableView.backgroundView = self.emptyStateLabel
            } else {
                self.tableView.backgroundView = nil
            }

            self.tableView.reloadData()
        }
    }
}

//   _____      _                 _
//  | ____|_  _| |_ ___ _ __  ___(_) ___  _ __  ___
//  |  _| \ \/ / __/ _ \ '_ \/ __| |/ _ \| '_ \/ __|
//  | |___ >  <| ||  __/ | | \__ \ | (_) | | | \__ \
//  |_____/_/\_\\__\___|_| |_|___/_|\___/|_| |_|___/

// MARK: UITableViewDelegate, UITableViewDataSource
extension SCTimelineModalViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if Timeline.instance.getEvents().count == 0 {
            return nil
        }

        guard let sectionHeader = self.tableView.dequeueReusableCell(
            withIdentifier: SCConstants.identifier.sectionHeaderCell.rawValue
            ) as? SCSectionHeaderViewCell else {
                return nil
        }

        sectionHeader.primaryLabel.font = SCFonts.regularSizeFont(.regular)
        sectionHeader.primaryLabel.text = SCStrings.section.timeline.rawValue

        if self.tableView.contentOffset.y > 0 {
            sectionHeader.showBlurBackground()
        } else {
            sectionHeader.hideBlurBackground()
        }

        return sectionHeader
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Timeline.instance.getEvents().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = self.tableView.dequeueReusableCell(
            withIdentifier: SCConstants.identifier.timelineViewCell.rawValue
            ) as? SCTimelineViewCell else {
                return SCTableViewCell()
        }

        let event = Timeline.instance.getEvents()[indexPath.row]

        guard let parameters = event.getParameters() else {
            return SCTableViewCell()
        }

        if event.getType() == .confirm {
            if let name = parameters[SCConstants.coding.name.rawValue] as? String,
               let clue = parameters[SCConstants.coding.clue.rawValue] as? String,
               let numberOfWords = parameters[SCConstants.coding.numberOfWords.rawValue] as? String {
                var baseString = String(
                    format: SCStrings.timeline.clueSetTo.rawValue,
                    name,
                    clue,
                    numberOfWords
                )
                var length = name.characters.count

                if let _ = parameters[SCConstants.coding.localPlayer.rawValue] {
                    baseString = String(
                        format: SCStrings.timeline.clueSetTo.rawValue,
                        SCStrings.player.localPlayer.rawValue,
                        clue,
                        numberOfWords
                    )
                    length = 3
                }

                let attributedString = NSMutableAttributedString(
                    string: baseString
                )
                attributedString.addAttribute(
                    NSFontAttributeName,
                    value: SCFonts.intermediateSizeFont(.bold) ?? 0,
                    range: NSMakeRange(0, length)
                )
                cell.primaryLabel.attributedText = attributedString
            }
        } else if event.getType() == .selectCard {
            if let name = parameters[SCConstants.coding.name.rawValue] as? String,
               let word = parameters[SCConstants.coding.word.rawValue] as? String,
               let correct = parameters[SCConstants.coding.correct.rawValue] as? Bool {
                var baseString = String(
                    format: SCStrings.timeline.selected.rawValue,
                    name,
                    word,
                    correct ? SCStrings.timeline.correct.rawValue : SCStrings.timeline.incorrect.rawValue
                )
                var length = name.characters.count

                // CPU player
                if name == SCStrings.player.cpu.rawValue {
                    baseString = String(format: SCStrings.timeline.cpuSelected.rawValue, word)
                }

                if let _ = parameters[SCConstants.coding.localPlayer.rawValue],
                   let name = parameters[SCConstants.coding.name.rawValue] as? String,
                   name != SCStrings.player.cpu.rawValue {
                    // Local player (You)
                    baseString = String(
                        format: SCStrings.timeline.selected.rawValue,
                        SCStrings.player.localPlayer.rawValue,
                        word,
                        correct ? SCStrings.timeline.correct.rawValue : SCStrings.timeline.incorrect.rawValue
                    )
                    length = 3
                }

                let attributedString = NSMutableAttributedString(
                    string: baseString
                )
                attributedString.addAttribute(
                    NSFontAttributeName,
                    value: SCFonts.intermediateSizeFont(.bold) ?? 0,
                    range: NSMakeRange(0, length)
                )
                cell.primaryLabel.attributedText = attributedString
            }
        } else if event.getType() == .endRound {
            if let name = parameters[SCConstants.coding.name.rawValue] as? String {
                var baseString = String(
                    format: SCStrings.timeline.roundEnded.rawValue,
                    name
                )
                var length = name.characters.count

                if let _ = parameters[SCConstants.coding.localPlayer.rawValue] {
                    baseString = String(
                        format: SCStrings.timeline.roundEnded.rawValue,
                        SCStrings.player.localPlayer.rawValue
                    )
                    length = 3
                }

                let attributedString = NSMutableAttributedString(
                    string: baseString
                )
                attributedString.addAttribute(
                    NSFontAttributeName,
                    value: SCFonts.intermediateSizeFont(.bold) ?? 0,
                    range: NSMakeRange(
                        0,
                        length
                    )
                )
                cell.primaryLabel.attributedText = attributedString
            } else {
                cell.primaryLabel.text = SCStrings.timeline.timerExpiry.rawValue
            }
        }

        if let hasRead = parameters[SCConstants.coding.hasRead.rawValue] as? Bool,
           !hasRead {
            cell.showNotificationDot()
        } else {
            cell.hideNotificationDot()
        }

        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
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

        self.refreshView()
    }
}
