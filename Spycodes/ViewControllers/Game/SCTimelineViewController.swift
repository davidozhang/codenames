import UIKit

class SCTimelineViewController: SCModalViewController {
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
            selector: #selector(SCTimelineViewController.refreshView),
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

// MARK: SCSectionHeaderViewCellDelegate
extension SCTimelineViewController: SCSectionHeaderViewCellDelegate {
    func onSectionHeaderButtonTapped() {
        Timeline.instance.markAllAsRead()
        self.tableView.reloadData()
    }
}

// MARK: UITableViewDelegate, UITableViewDataSource
extension SCTimelineViewController: UITableViewDataSource, UITableViewDelegate {
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

        guard let timelineHeader = self.tableView.dequeueReusableCell(
            withIdentifier: SCConstants.identifier.sectionHeaderCell.rawValue
            ) as? SCTimelineHeaderViewCell else {
                return nil
        }

        timelineHeader.delegate = self
        timelineHeader.setButtonImage(name: SCConstants.images.markAsRead.rawValue)

        if Timeline.instance.hasUnreadEvents() {
            timelineHeader.showNotificationDot()
        } else {
            timelineHeader.hideNotificationDot()
        }

        timelineHeader.primaryLabel.font = SCFonts.regularSizeFont(.regular)
        timelineHeader.primaryLabel.text = SCStrings.section.timeline.rawValue

        if self.scrolled {
            timelineHeader.showBlurBackground()
        } else {
            timelineHeader.hideBlurBackground()
        }

        return timelineHeader
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

        guard let type = event.getType() else {
            return SCTableViewCell()
        }

        var baseString: String?

        switch type {
        case .confirm:
            if let name = parameters[SCConstants.coding.name.rawValue] as? String,
               let clue = parameters[SCConstants.coding.clue.rawValue] as? String,
               let numberOfWords = parameters[SCConstants.coding.numberOfWords.rawValue] as? String {
                if let _ = parameters[SCConstants.coding.localPlayer.rawValue] {
                    // Local player (You)
                    baseString = String(
                        format: SCStrings.timeline.clueSetTo.rawValue,
                        SCStrings.player.localPlayer.rawValue,
                        clue,
                        numberOfWords
                    )
                } else {
                    baseString = String(
                        format: SCStrings.timeline.clueSetTo.rawValue,
                        name,
                        clue,
                        numberOfWords
                    )
                }
            }
        case .endRound:
            if let name = parameters[SCConstants.coding.name.rawValue] as? String {
                if let _ = parameters[SCConstants.coding.localPlayer.rawValue] {
                    // Local player (You)
                    baseString = String(
                        format: SCStrings.timeline.roundEnded.rawValue,
                        SCStrings.player.localPlayer.rawValue
                    )
                } else {
                    baseString = String(
                        format: SCStrings.timeline.roundEnded.rawValue,
                        name
                    )
                }
            } else {
                baseString = SCStrings.timeline.timerExpiry.rawValue
            }
        case .selectCard:
            if let name = parameters[SCConstants.coding.name.rawValue] as? String,
               let card = parameters[SCConstants.coding.card.rawValue] as? Card {
                if name == SCStrings.player.cpu.rawValue {
                    // CPU player
                    baseString = String(format: SCStrings.timeline.cpuSelected.rawValue, card.getWord())
                    break
                }

                if let _ = parameters[SCConstants.coding.localPlayer.rawValue] {
                    // Local player (You)
                    if let correct = parameters[SCConstants.coding.correct.rawValue] as? Bool, correct {
                        baseString = String(
                            format: SCStrings.timeline.correctlySelected.rawValue,
                            SCStrings.player.localPlayer.rawValue,
                            card.getWord()
                        )
                    } else {
                        baseString = String(
                            format: SCStrings.timeline.selected.rawValue,
                            SCStrings.player.localPlayer.rawValue,
                            card.getTeam() == Team.neutral ?
                            SCStrings.timeline.bystander.rawValue :
                            (card.getTeam() == Team.assassin ?
                                SCStrings.timeline.assassin.rawValue :
                                SCStrings.timeline.enemy.rawValue
                            ),
                            card.getWord(),
                            (card.getTeam() == Team.assassin ?
                                SCStrings.timeline.game.rawValue :
                                SCStrings.timeline.round.rawValue
                            )
                        )
                    }
                } else {
                    if let correct = parameters[SCConstants.coding.correct.rawValue] as? Bool, correct {
                        // Local player (You)
                        baseString = String(
                            format: SCStrings.timeline.correctlySelected.rawValue,
                            name,
                            card.getWord()
                        )
                    } else {
                        baseString = String(
                            format: SCStrings.timeline.selected.rawValue,
                            name,
                            card.getTeam() == Team.neutral ?
                            SCStrings.timeline.bystander.rawValue :
                            (card.getTeam() == Team.assassin ?
                                SCStrings.timeline.assassin.rawValue :
                                SCStrings.timeline.enemy.rawValue
                            ),
                            card.getWord(),
                            (card.getTeam() == Team.assassin ?
                                SCStrings.timeline.game.rawValue :
                                SCStrings.timeline.round.rawValue
                            )
                        )
                    }
                }
            }
        case .gameOver:
            baseString = String(
                format: SCStrings.timeline.gameOver.rawValue,
                Round.instance.getWinningTeam() == Player.instance.getTeam() ?
                SCStrings.timeline.won.rawValue :
                SCStrings.timeline.lost.rawValue
            )
        case .gameAborted:
            baseString = SCStrings.timeline.gameAborted.rawValue
        default:
            break
        }

        // Apply attributed string decorations here if applicable
        if let baseString = baseString {
            let attributedString = NSMutableAttributedString(
                string: baseString
            )

            if let hasRead = parameters[SCConstants.coding.hasRead.rawValue] as? Bool,
                !hasRead {
                attributedString.addAttribute(
                    NSFontAttributeName,
                    value: SCFonts.intermediateSizeFont(.bold) ?? 0,
                    range: NSMakeRange(0, baseString.characters.count - 1)
                )
            }

            cell.primaryLabel.attributedText = attributedString
        }

        if let teamCoded = parameters[SCConstants.coding.team.rawValue] as? Int,
           let team = Team(rawValue: teamCoded) {
            cell.teamIndicatorView.backgroundColor = .colorForTeam(team)
        } else {
            cell.teamIndicatorView.backgroundColor = .spycodesGrayColor()
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
