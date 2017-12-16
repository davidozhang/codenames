import Foundation

class SCLocalStorageManager: SCLogger {
    static let instance = SCLocalStorageManager()

    enum LocalSettingType: Int {
        case nightMode = 0
        case accessibility = 1
        case persistentSelection = 2
    }

    var localSettings = [LocalSettingType: Bool]()

    override func getIdentifier() -> String? {
        return SCConstants.loggingIdentifier.localStorageManager.rawValue
    }

    // MARK: Public
    func enableLocalSetting(_ type: LocalSettingType, enabled: Bool) {
        self.localSettings[type] = enabled
        self.saveLocalSetting(type)
    }

    func isLocalSettingEnabled(_ type: LocalSettingType) -> Bool {
        if let setting = self.localSettings[type] {
            return setting
        }

        return false
    }

    func saveSelectedCustomCategories(selectedCategories: [CustomCategory]) {
        let data = NSKeyedArchiver.archivedData(withRootObject: selectedCategories)
        UserDefaults.standard.set(
            data,
            forKey: SCConstants.userDefaults.selectedCustomCategories.rawValue
        )

        UserDefaults.standard.synchronize()

        super.log(SCStrings.logging.selectedCustomCategoriesSaved.rawValue)
    }

    func saveSelectedCategories(selectedCategories: [SCWordBank.Category]) {
        var selectedCategoriesData = [Int]()

        for category in selectedCategories {
            selectedCategoriesData.append(category.rawValue)
        }

        let data = NSKeyedArchiver.archivedData(withRootObject: selectedCategoriesData)
        UserDefaults.standard.set(
            data,
            forKey: SCConstants.userDefaults.selectedCategories.rawValue
        )

        UserDefaults.standard.synchronize()
        super.log(SCStrings.logging.selectedCategoriesSaved.rawValue)
    }

    func saveAllCustomCategories(customCategories: [CustomCategory]) {
        let data = NSKeyedArchiver.archivedData(withRootObject: customCategories)
        UserDefaults.standard.set(
            data,
            forKey: SCConstants.userDefaults.customCategories.rawValue
        )

        UserDefaults.standard.synchronize()
        super.log(SCStrings.logging.allCustomCategoriesSaved.rawValue)
    }

    func retrieveAllCustomCategories() -> [CustomCategory] {
        if let data = UserDefaults.standard.object(forKey: SCConstants.userDefaults.customCategories.rawValue) as? NSData {
            if let customCategories = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as? [CustomCategory] {
                super.log(SCStrings.logging.allCustomCategoriesRetrieved.rawValue)
                return customCategories
            }
        }

        return [CustomCategory]()
    }

    func retrieveLocalSettings() {
        let storedNightMode = UserDefaults.standard.bool(
            forKey: SCConstants.userDefaults.nightMode.rawValue
        )

        self.localSettings[.nightMode] = storedNightMode

        let storedAccessibility = UserDefaults.standard.bool(
            forKey: SCConstants.userDefaults.accessibility.rawValue
        )

        self.localSettings[.accessibility] = storedAccessibility

        let storedPersistentCategorySelection = UserDefaults.standard.bool(
            forKey: SCConstants.userDefaults.persistentSelection.rawValue
        )

        self.localSettings[.persistentSelection] = storedPersistentCategorySelection

        super.log(SCStrings.logging.localSettingsRetrieved.rawValue)
    }

    func retrieveSelectedConsolidatedCategories() {
        if !SCLocalStorageManager.instance.isLocalSettingEnabled(.persistentSelection) {
            return
        }

        ConsolidatedCategories.instance.setSelectedCategories(
            selectedCategories: self.retrieveSelectedCategories()
        )

        ConsolidatedCategories.instance.setSelectedCustomCategories(
            selectedCategories: self.retrieveSelectedCustomCategories()
        )

        super.log(SCStrings.logging.selectedConsolidatedCategoriesRetrieved.rawValue)
    }

    func clearSelectedConsolidatedCategories() {
        UserDefaults.standard.removeObject(
            forKey: SCConstants.userDefaults.selectedCategories.rawValue
        )

        UserDefaults.standard.removeObject(
            forKey: SCConstants.userDefaults.selectedCustomCategories.rawValue
        )

        UserDefaults.standard.synchronize()
        super.log(SCStrings.logging.selectedConsolidatedCategoriesCleared.rawValue)
    }

    // MARK: Private
    fileprivate func saveLocalSetting(_ type: LocalSettingType) {
        switch type {
        case .nightMode:
            UserDefaults.standard.set(
                self.localSettings[.nightMode],
                forKey: SCConstants.userDefaults.nightMode.rawValue
            )
        case .accessibility:
            UserDefaults.standard.set(
                self.localSettings[.accessibility],
                forKey: SCConstants.userDefaults.accessibility.rawValue
            )
        case .persistentSelection:
            UserDefaults.standard.set(
                self.localSettings[.persistentSelection],
                forKey: SCConstants.userDefaults.persistentSelection.rawValue
            )
        }

        UserDefaults.standard.synchronize()
        super.log(SCStrings.logging.localSettingsSaved.rawValue)
    }

    fileprivate func retrieveSelectedCustomCategories() -> Set<CustomCategory> {
        if let data = UserDefaults.standard.object(forKey: SCConstants.userDefaults.selectedCustomCategories.rawValue) as? NSData {
            if let retrievedCustomCategories = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as? [CustomCategory] {
                return Set<CustomCategory>(retrievedCustomCategories)
            }
        }

        return Set<CustomCategory>()
    }

    fileprivate func retrieveSelectedCategories() -> Set<SCWordBank.Category> {
        var selectedCategories = Array<SCWordBank.Category>()

        if let data = UserDefaults.standard.object(forKey: SCConstants.userDefaults.selectedCategories.rawValue) as? NSData {
            if let retrievedCategories = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as? [Int] {
                for category in retrievedCategories {
                    if let category = SCWordBank.Category(rawValue: category) {
                        selectedCategories.append(category)
                    }
                }
            }
        }

        return Set<SCWordBank.Category>(selectedCategories)
    }
}
