import UIKit

protocol SCTimerSettingViewCellDelegate: class {
    func onTimerDurationTapped()
    func onTimerDurationDismissed()
}

class SCTimerSettingViewCell: SCTableViewCell {
    weak var delegate: SCTimerSettingViewCellDelegate?
    @IBOutlet weak var timerDurationTextField: SCTextField!

    static let disabledOptionRow = 0
    let pickerView = UIPickerView()
    let toolBar = UIToolbar()

    override func awakeFromNib() {
        super.awakeFromNib()

        self.pickerView.dataSource = self
        self.pickerView.delegate = self

        if SCSettingsManager.instance.isLocalSettingEnabled(.nightMode) {
            self.pickerView.backgroundColor = .darkTintColor()
            self.toolBar.barStyle = .blackTranslucent
        } else {
            self.pickerView.backgroundColor = .lightTintColor()
            self.toolBar.barStyle = .default
        }

        self.toolBar.isTranslucent = true
        self.toolBar.sizeToFit()

        let flexButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(
            title: SCStrings.button.done.rawValue,
            style: .done,
            target: self,
            action: #selector(SCTimerSettingViewCell.onTimerDurationDone)
        )

        toolBar.setItems(
            [flexButton, doneButton],
            animated: false
        )
        toolBar.isUserInteractionEnabled = true

        self.timerDurationTextField.font = SCFonts.intermediateSizeFont(.medium)
        self.timerDurationTextField.sizeToFit()

        self.timerDurationTextField.delegate = self
        self.timerDurationTextField.tintColor = .clear
        self.timerDurationTextField.inputView = self.pickerView
        self.timerDurationTextField.inputAccessoryView = toolBar
        self.accessoryView = self.timerDurationTextField

        self.synchronizeSetting()
    }

    func synchronizeSetting() {
        if Timer.instance.isEnabled() {
            let minutes = Timer.instance.getDurationInMinutes()
            self.timerDurationTextField.text = String(format: SCStrings.timer.minutes.rawValue, minutes)
            self.pickerView.selectRow(minutes, inComponent: 0, animated: false)
        } else {
            self.timerDurationTextField.text = SCStrings.timer.disabled.rawValue
            self.pickerView.selectRow(SCTimerSettingViewCell.disabledOptionRow, inComponent: 0, animated: false)
        }
    }

    @objc
    fileprivate func onTimerDurationDone() {
        let selectedRow = self.pickerView.selectedRow(inComponent: 0)
        if selectedRow == SCTimerSettingViewCell.disabledOptionRow {
            Timer.instance.setEnabled(false)
        } else {
            Timer.instance.setDuration(durationInMinutes: selectedRow)
        }

        SCMultipeerManager.instance.broadcast(Timer.instance)

        self.delegate?.onTimerDurationDismissed()
    }
}

//   _____      _                 _
//  | ____|_  _| |_ ___ _ __  ___(_) ___  _ __  ___
//  |  _| \ \/ / __/ _ \ '_ \/ __| |/ _ \| '_ \/ __|
//  | |___ >  <| ||  __/ | | \__ \ | (_) | | | \__ \
//  |_____/_/\_\\__\___|_| |_|___/_|\___/|_| |_|___/

// MARK: UIPickerViewDataSource, UIPickerViewDelegate
extension SCTimerSettingViewCell: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 11
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == SCTimerSettingViewCell.disabledOptionRow {
            self.timerDurationTextField.text = SCStrings.timer.disabled.rawValue
        } else {
            self.timerDurationTextField.text = String(format: SCStrings.timer.minutes.rawValue, row)
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == SCTimerSettingViewCell.disabledOptionRow {
            return SCStrings.timer.disabled.rawValue
        }

        return String(format: SCStrings.timer.minutes.rawValue, row)
    }
}

extension SCTimerSettingViewCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.delegate?.onTimerDurationTapped()
    }
}
