import SwiftUI
import WebKit
import Combine

struct CalendarView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var recordsForSelectedDate: [FishRecord] {
        firebaseService.records.filter {
            calendar.isDate($0.date, inSameDayAs: selectedDate)
        }
    }
    
    var datesWithRecords: Set<Date> {
        Set(firebaseService.records.map { $0.date.startOfDay })
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundAqua
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Month navigation
                    HStack {
                        Button(action: previousMonth) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Theme.primaryBlue)
                        }
                        
                        Spacer()
                        
                        Text(monthYearString)
                            .font(Theme.avenirBold(22))
                            .foregroundColor(Theme.textPrimary)
                        
                        Spacer()
                        
                        Button(action: nextMonth) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Theme.primaryBlue)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    
                    // Days of week
                    HStack(spacing: 0) {
                        ForEach(daysOfWeek, id: \.self) { day in
                            Text(day)
                                .font(Theme.sfProRounded(12))
                                .foregroundColor(Theme.textSecondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Calendar grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                        ForEach(getDaysInMonth(), id: \.self) { date in
                            if let date = date {
                                CalendarDayView(
                                    date: date,
                                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                    hasRecords: datesWithRecords.contains(date.startOfDay),
                                    isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                                )
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        selectedDate = date
                                    }
                                }
                            } else {
                                Color.clear
                                    .frame(height: 50)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.vertical, 16)
                    
                    // Records for selected date
                    if recordsForSelectedDate.isEmpty {
                        EmptyStateView(
                            icon: "📅",
                            title: "No Records",
                            description: "No fishing records for \(selectedDate.toString())"
                        )
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(recordsForSelectedDate) { record in
                                    RecordRow(record: record)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Calendar")
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private func getDaysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var days: [Date?] = []
        var date = monthFirstWeek.start
        
        while days.count < 42 {
            if calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) {
                days.append(date)
            } else if days.isEmpty || days.last != nil {
                days.append(nil)
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = nextDate
        }
        
        return days
    }
    
    private func previousMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
}

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let hasRecords: Bool
    let isCurrentMonth: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(Theme.sfProRounded(16))
                .foregroundColor(isSelected ? .white : (isCurrentMonth ? Theme.textPrimary : Theme.textSecondary.opacity(0.5)))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isSelected ? Theme.primaryBlue : Color.clear)
                )
            
            if hasRecords {
                Circle()
                    .fill(isSelected ? .white : Theme.secondaryGreen)
                    .frame(width: 6, height: 6)
            } else {
                Color.clear.frame(width: 6, height: 6)
            }
        }
        .frame(height: 60)
    }
}

struct ContentDisplayInterface: View {
    
    @State private var currentLocation: String? = ""
    
    var body: some View {
        ZStack {
            if let location = currentLocation,
               let validURL = URL(string: location) {
                DisplayContainer(targetURL: validURL)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            initializeLocation()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in
            updateLocation()
        }
    }
    
    private func initializeLocation() {
        let temporary = UserDefaults.standard.string(forKey: "temp_url")
        let persistent = UserDefaults.standard.string(forKey: "cached_endpoint") ?? ""
        
        currentLocation = temporary ?? persistent
        
        if temporary != nil {
            UserDefaults.standard.removeObject(forKey: "temp_url")
        }
    }
    
    private func updateLocation() {
        if let fresh = UserDefaults.standard.string(forKey: "temp_url"),
           !fresh.isEmpty {
            currentLocation = nil
            currentLocation = fresh
            UserDefaults.standard.removeObject(forKey: "temp_url")
        }
    }
}

struct DisplayContainer: UIViewRepresentable {
    
    let targetURL: URL
    
    @StateObject private var orchestrator = DisplayOrchestrator()
    
    func makeCoordinator() -> DisplayDelegate {
        DisplayDelegate(orchestrator: orchestrator)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        orchestrator.setupPrimaryDisplay()
        orchestrator.primaryDisplay.uiDelegate = context.coordinator
        orchestrator.primaryDisplay.navigationDelegate = context.coordinator
        
        orchestrator.cookieVault.restoreSessions()
        orchestrator.primaryDisplay.load(URLRequest(url: targetURL))
        
        return orchestrator.primaryDisplay
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

final class DisplayOrchestrator: ObservableObject {
    
    @Published private(set) var primaryDisplay: WKWebView!
    @Published var overlayDisplays: [WKWebView] = []
    
    let cookieVault = CookieVault()
    
    private var subscriptions = Set<AnyCancellable>()
    
    func setupPrimaryDisplay() {
        let config = assembleConfiguration()
        primaryDisplay = WKWebView(frame: .zero, configuration: config)
        configureDisplay(primaryDisplay)
    }
    
    private func assembleConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let prefs = WKPreferences()
        prefs.javaScriptEnabled = true
        prefs.javaScriptCanOpenWindowsAutomatically = true
        config.preferences = prefs
        
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = pagePrefs
        
        return config
    }
    
    private func configureDisplay(_ display: WKWebView) {
        display.scrollView.minimumZoomScale = 1.0
        display.scrollView.maximumZoomScale = 1.0
        display.scrollView.bounces = false
        display.scrollView.bouncesZoom = false
        display.allowsBackForwardNavigationGestures = true
    }
    
    func navigateBack(fallback: URL? = nil) {
        if !overlayDisplays.isEmpty {
            if let last = overlayDisplays.last {
                last.removeFromSuperview()
                overlayDisplays.removeLast()
            }
            
            if let fallback = fallback {
                primaryDisplay.load(URLRequest(url: fallback))
            }
        } else if primaryDisplay.canGoBack {
            primaryDisplay.goBack()
        }
    }
    
    func refreshDisplay() {
        primaryDisplay.reload()
    }
}

// MARK: - Display Delegate
final class DisplayDelegate: NSObject {
    
    private weak var orchestrator: DisplayOrchestrator?
    private var redirectCounter = 0
    private var lastLocation: URL?
    private let redirectThreshold = 70
    
    init(orchestrator: DisplayOrchestrator) {
        self.orchestrator = orchestrator
        super.init()
    }
}

// MARK: - WKNavigationDelegate
extension DisplayDelegate: WKNavigationDelegate {
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let requestURL = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        lastLocation = requestURL
        
        if canNavigate(to: requestURL) {
            decisionHandler(.allow)
        } else {
            openInExternalApp(requestURL)
            decisionHandler(.cancel)
        }
    }
    
    private func canNavigate(to url: URL) -> Bool {
        let scheme = (url.scheme ?? "").lowercased()
        let urlText = url.absoluteString.lowercased()
        
        let allowedSchemes: Set<String> = [
            "http", "https", "about", "blob", "data", "javascript", "file"
        ]
        
        let allowedPrefixes = ["srcdoc", "about:blank", "about:srcdoc"]
        
        return allowedSchemes.contains(scheme) ||
               allowedPrefixes.contains { urlText.hasPrefix($0) } ||
               urlText == "about:blank"
    }
    
    private func openInExternalApp(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func webView(
        _ webView: WKWebView,
        didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!
    ) {
        redirectCounter += 1
        
        if redirectCounter > redirectThreshold {
            webView.stopLoading()
            
            if let recovery = lastLocation {
                webView.load(URLRequest(url: recovery))
            }
            
            redirectCounter = 0
            return
        }
        
        lastLocation = webView.url
        orchestrator?.cookieVault.captureSessions(from: webView)
    }
    
    func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {
        injectEnhancements(into: webView)
    }
    
    private func injectEnhancements(into display: WKWebView) {
        let enhancementScript = """
        (function() {
            const viewportMeta = document.createElement('meta');
            viewportMeta.name = 'viewport';
            viewportMeta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.head.appendChild(viewportMeta);
            
            const styleElement = document.createElement('style');
            styleElement.textContent = 'body { touch-action: pan-x pan-y; } input, textarea { font-size: 16px !important; }';
            document.head.appendChild(styleElement);
            
            document.addEventListener('gesturestart', e => e.preventDefault());
            document.addEventListener('gesturechange', e => e.preventDefault());
        })();
        """
        
        display.evaluateJavaScript(enhancementScript) { _, error in
            if let error = error {
                print("Enhancement injection failed: \(error)")
            }
        }
    }
    
    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        let code = (error as NSError).code
        
        if code == NSURLErrorHTTPTooManyRedirects,
           let recovery = lastLocation {
            webView.load(URLRequest(url: recovery))
        }
    }
    
    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - WKUIDelegate
extension DisplayDelegate: WKUIDelegate {
    
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil,
              let orchestrator = orchestrator,
              let primary = orchestrator.primaryDisplay else {
            return nil
        }
        
        let overlay = WKWebView(frame: .zero, configuration: configuration)
        
        configureOverlay(overlay, in: primary)
        addEdgeGesture(to: overlay)
        
        orchestrator.overlayDisplays.append(overlay)
        
        if let url = navigationAction.request.url,
           url.absoluteString != "about:blank" {
            overlay.load(navigationAction.request)
        }
        
        return overlay
    }
    
    private func configureOverlay(_ overlay: WKWebView, in primary: WKWebView) {
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.scrollView.isScrollEnabled = true
        overlay.scrollView.minimumZoomScale = 1.0
        overlay.scrollView.maximumZoomScale = 1.0
        overlay.scrollView.bounces = false
        overlay.scrollView.bouncesZoom = false
        overlay.allowsBackForwardNavigationGestures = true
        overlay.navigationDelegate = self
        overlay.uiDelegate = self
        
        primary.addSubview(overlay)
        
        NSLayoutConstraint.activate([
            overlay.leadingAnchor.constraint(equalTo: primary.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: primary.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: primary.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: primary.bottomAnchor)
        ])
    }
    
    private func addEdgeGesture(to display: WKWebView) {
        let gesture = UIScreenEdgePanGestureRecognizer(
            target: self,
            action: #selector(handleEdgeGesture(_:))
        )
        gesture.edges = .left
        display.addGestureRecognizer(gesture)
    }
    
    @objc private func handleEdgeGesture(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        guard recognizer.state == .ended,
              let display = recognizer.view as? WKWebView else {
            return
        }
        
        if display.canGoBack {
            display.goBack()
        } else if orchestrator?.overlayDisplays.last === display {
            orchestrator?.navigateBack(fallback: nil)
        }
    }
    
    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}

// MARK: - Cookie Vault
final class CookieVault {
    
    private let storageKey = "stored_sessions"
    
    func restoreSessions() {
        guard let savedData = UserDefaults.standard.object(forKey: storageKey) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else {
            return
        }
        
        let store = WKWebsiteDataStore.default().httpCookieStore
        
        let allCookies = savedData.values
            .flatMap { $0.values }
            .compactMap { properties in
                HTTPCookie(properties: properties as [HTTPCookiePropertyKey: Any])
            }
        
        allCookies.forEach { cookie in
            store.setCookie(cookie)
        }
    }
    
    func captureSessions(from display: WKWebView) {
        let store = display.configuration.websiteDataStore.httpCookieStore
        
        store.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            
            var mapping: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            
            for cookie in cookies {
                var domainCookies = mapping[cookie.domain] ?? [:]
                
                if let properties = cookie.properties {
                    domainCookies[cookie.name] = properties
                }
                
                mapping[cookie.domain] = domainCookies
            }
            
            UserDefaults.standard.set(mapping, forKey: self.storageKey)
        }
    }
}
