import Foundation
import Firebase
import FirebaseMessaging
import AppsFlyerLib

protocol PersistenceLayer {
    func isFirstBoot() -> Bool
    func getCachedDestination() -> URL?
    func saveDestination(_ urlString: String)
    func setOperationalMode(_ mode: String)
    func getOperationalMode() -> String?
    func flagBootCompleted()
    func recordAuthRequestTime(_ date: Date)
    func getLastAuthRequest() -> Date?
    func saveAuthGranted(_ granted: Bool)
    func saveAuthDenied(_ denied: Bool)
    func wasAuthGranted() -> Bool
    func wasAuthDenied() -> Bool
}

private enum StorageKey {
    static let bootCompleted = "launchedBefore"
    static let cachedURL = "cached_endpoint"
    static let operationalMode = "app_status"
    static let authRequestTime = "permission_request_time"
    static let authGranted = "permissions_accepted"
    static let authDenied = "permissions_denied"
    static let notificationToken = "push_token"
}

final class PersistenceImplementation: PersistenceLayer {
    
    private let store: UserDefaults
    
    init(store: UserDefaults = .standard) {
        self.store = store
    }
    
    func isFirstBoot() -> Bool {
        return !store.bool(forKey: StorageKey.bootCompleted)
    }
    
    func getCachedDestination() -> URL? {
        guard let urlString = store.string(forKey: StorageKey.cachedURL) else {
            return nil
        }
        return URL(string: urlString)
    }
    
    func saveDestination(_ urlString: String) {
        store.set(urlString, forKey: StorageKey.cachedURL)
    }
    
    func setOperationalMode(_ mode: String) {
        store.set(mode, forKey: StorageKey.operationalMode)
    }
    
    func getOperationalMode() -> String? {
        return store.string(forKey: StorageKey.operationalMode)
    }
    
    func flagBootCompleted() {
        store.set(true, forKey: StorageKey.bootCompleted)
    }
    
    func recordAuthRequestTime(_ date: Date) {
        store.set(date, forKey: StorageKey.authRequestTime)
    }
    
    func getLastAuthRequest() -> Date? {
        return store.object(forKey: StorageKey.authRequestTime) as? Date
    }
    
    func saveAuthGranted(_ granted: Bool) {
        store.set(granted, forKey: StorageKey.authGranted)
    }
    
    func saveAuthDenied(_ denied: Bool) {
        store.set(denied, forKey: StorageKey.authDenied)
    }
    
    func wasAuthGranted() -> Bool {
        return store.bool(forKey: StorageKey.authGranted)
    }
    
    func wasAuthDenied() -> Bool {
        return store.bool(forKey: StorageKey.authDenied)
    }
}

// MARK: - Device Information Provider
struct DeviceMetadata {
    
    private let defaults = UserDefaults.standard
    
    func bundleIdentifier() -> String {
        return "com.specilogfis.FishSpeciesLog"
    }
    
    func firebaseProjectIdentifier() -> String? {
        return FirebaseApp.app()?.options.gcmSenderID
    }
    
    func storeIdentifier() -> String {
        return "id\(Config.appsFlyerId)"
    }
    
    func pushToken() -> String? {
        if let saved = defaults.string(forKey: StorageKey.notificationToken) {
            return saved
        }
        return Messaging.messaging().fcmToken
    }
    
    func localeIdentifier() -> String {
        guard let primary = Locale.preferredLanguages.first else {
            return "EN"
        }
        return String(primary.prefix(2)).uppercased()
    }
}
