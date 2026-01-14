import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseMessaging
import AppsFlyerLib
import AppTrackingTransparency

@main
struct FishSpeciesLogApp: App {
    
    @UIApplicationDelegateAdaptor(LaunchManager.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ApplicationRoot()
        }
    }
}

struct RootContentView: View {
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        ZStack {
            if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
    }
    
}

final class LaunchManager: UIResponder, UIApplicationDelegate {
    
    private let dataAggregator = DataAggregator()
    private let pushDispatcher = PushDispatcher()
    private let trackingEngine = TrackingEngine()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        bootstrapServices()
        wireUpDelegates()
        enablePushNotifications()
        
        if let pushData = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            pushDispatcher.dispatch(pushData)
        }
        
        trackingEngine.wire(
            onAttribution: { [weak self] data in
                self?.dataAggregator.receiveAttribution(data)
            },
            onDeeplink: { [weak self] data in
                self?.dataAggregator.receiveDeeplink(data)
            },
            onFailure: { [weak self] in
                self?.dataAggregator.handleFailure()
            }
        )
        
        observeActivation()
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    private func bootstrapServices() {
        FirebaseApp.configure()
        Auth.auth().signInAnonymously { _, e in
            if let e = e {
                print("error \(e.localizedDescription)")
                return
            }
            UserDefaults.standard.set(Auth.auth().currentUser?.uid, forKey: "userId")
        }
    }
    
    private func wireUpDelegates() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
    }
    
    private func enablePushNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    private func observeActivation() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func handleActivation() {
        trackingEngine.activate()
    }
}

// MARK: - MessagingDelegate
extension LaunchManager: MessagingDelegate {
    
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { token, error in
            guard error == nil, let token = token else { return }
            TokenVault.shared.store(token)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension LaunchManager: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        pushDispatcher.dispatch(notification.request.content.userInfo)
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        pushDispatcher.dispatch(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        pushDispatcher.dispatch(userInfo)
        completionHandler(.newData)
    }
}

final class DataAggregator {
    
    private var attributionBuffer: [AnyHashable: Any] = [:]
    private var deeplinkBuffer: [AnyHashable: Any] = [:]
    private var consolidationTimer: Timer?
    private let transmissionFlag = "trackingDataSent"
    
    func receiveAttribution(_ data: [AnyHashable: Any]) {
        attributionBuffer = data
        scheduleConsolidation()
        
        if !deeplinkBuffer.isEmpty {
            consolidateAndTransmit()
        }
    }
    
    func receiveDeeplink(_ data: [AnyHashable: Any]) {
        guard !wasTransmitted() else { return }
        
        deeplinkBuffer = data
        transmitDeeplink(data)
        cancelConsolidation()
        
        if !attributionBuffer.isEmpty {
            consolidateAndTransmit()
        }
    }
    
    func handleFailure() {
        transmitAttribution([:])
    }
    
    private func scheduleConsolidation() {
        consolidationTimer?.invalidate()
        consolidationTimer = Timer.scheduledTimer(
            withTimeInterval: 10.0,
            repeats: false
        ) { [weak self] _ in
            self?.consolidateAndTransmit()
        }
    }
    
    private func cancelConsolidation() {
        consolidationTimer?.invalidate()
    }
    
    private func consolidateAndTransmit() {
        var consolidated = attributionBuffer
        
        deeplinkBuffer.forEach { key, value in
            if consolidated[key] == nil {
                consolidated[key] = value
            }
        }
        
        transmitAttribution(consolidated)
        markTransmitted()
    }
    
    private func transmitAttribution(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: Notification.Name("ConversionDataReceived"),
            object: nil,
            userInfo: ["conversionData": data]
        )
    }
    
    private func transmitDeeplink(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: Notification.Name("deeplink_values"),
            object: nil,
            userInfo: ["deeplinksData": data]
        )
    }
    
    private func wasTransmitted() -> Bool {
        return UserDefaults.standard.bool(forKey: transmissionFlag)
    }
    
    private func markTransmitted() {
        UserDefaults.standard.set(true, forKey: transmissionFlag)
    }
}

final class TrackingEngine: NSObject {
    
    private var attributionHandler: (([AnyHashable: Any]) -> Void)?
    private var deeplinkHandler: (([AnyHashable: Any]) -> Void)?
    private var failureHandler: (() -> Void)?
    
    func wire(
        onAttribution: @escaping ([AnyHashable: Any]) -> Void,
        onDeeplink: @escaping ([AnyHashable: Any]) -> Void,
        onFailure: @escaping () -> Void
    ) {
        self.attributionHandler = onAttribution
        self.deeplinkHandler = onDeeplink
        self.failureHandler = onFailure
        
        setupSDK()
    }
    
    private func setupSDK() {
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = Config.appsFlyerKey
        sdk.appleAppID = Config.appsFlyerId
        sdk.delegate = self
        sdk.deepLinkDelegate = self
    }
    
    func activate() {
        if #available(iOS 14.0, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
}

extension TrackingEngine: AppsFlyerLibDelegate {
    
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        attributionHandler?(data)
    }
    
    func onConversionDataFail(_ error: Error) {
        failureHandler?()
    }
}

extension TrackingEngine: DeepLinkDelegate {
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status,
              let link = result.deepLink else {
            return
        }
        
        deeplinkHandler?(link.clickEvent)
    }
}

final class PushDispatcher {
    
    private let parser = PayloadParser()
    
    func dispatch(_ payload: [AnyHashable: Any]) {
        guard let urlString = parser.parse(payload) else {
            return
        }
        
        UserDefaults.standard.set(urlString, forKey: "temp_url")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            NotificationCenter.default.post(
                name: Notification.Name("LoadTempURL"),
                object: nil,
                userInfo: ["temp_url": urlString]
            )
        }
    }
}

struct PayloadParser {
    
    func parse(_ payload: [AnyHashable: Any]) -> String? {
        // Direct URL
        if let url = payload["url"] as? String {
            return url
        }
        
        // Nested URL
        if let nested = payload["data"] as? [String: Any],
           let url = nested["url"] as? String {
            return url
        }
        
        return nil
    }
}

final class TokenVault {
    
    static let shared = TokenVault()
    
    private init() {}
    
    func store(_ token: String) {
        let defaults = UserDefaults.standard
        defaults.set(token, forKey: "fcm_token")
        defaults.set(token, forKey: "push_token")
    }
    
    func retrieve() -> String? {
        return UserDefaults.standard.string(forKey: "push_token")
    }
}
