import Foundation
import Combine
import Network
import UIKit
import UserNotifications

final class FlowDirector: ObservableObject {
    
    @Published var presentationMode: PresentationMode = .initializing
    @Published var destination: URL?
    @Published var requestingAuth = false
    
    private let engine = FlowEngine()
    private let workspace = WorkspaceContext()
    private let persistence: PersistenceLayer
    private let connector: RemoteConnector
    private let monitor = NWPathMonitor()
    
    private var cancellables = Set<AnyCancellable>()
    private var timeoutWork: DispatchWorkItem?
    
    init(
        persistence: PersistenceLayer = PersistenceImplementation(),
        connector: RemoteConnector = RemoteConnectorImplementation()
    ) {
        self.persistence = persistence
        self.connector = connector
        
        bindEngineToPresentation()
        startNetworkMonitoring()
        kickoffSequence()
    }
    
    deinit {
        monitor.cancel()
    }
    
    // MARK: - Public Interface
    
    func ingest(attributionPayload: [String: Any]) {
        workspace.storeAttribution(attributionPayload)
        engine.emit(DataArrived(payload: attributionPayload))
        evaluateAndProceed()
    }
    
    func ingest(linkPayload: [String: Any]) {
        workspace.storeLink(linkPayload)
    }
    
    func skipAuthorization() {
        persistence.recordAuthRequestTime(Date())
        requestingAuth = false
        resolveDestination()
    }
    
    func grantAuthorization() {
        requestNotificationAuth { [weak self] granted in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.persistence.saveAuthGranted(granted)
                if !granted {
                    self.persistence.saveAuthDenied(true)
                }
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                
                self.requestingAuth = false
                
                if self.destination != nil {
                    self.engine.transition(to: .ready(self.destination!))
                } else {
                    self.resolveDestination()
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func bindEngineToPresentation() {
        engine.$activeState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updatePresentation(for: state)
            }
            .store(in: &cancellables)
    }
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            self?.engine.emit(ConnectivityChanged(available: connected))
        }
        monitor.start(queue: .global(qos: .background))
    }
    
    private func kickoffSequence() {
        engine.emit(BootCompleted())
        scheduleTimeout()
    }
    
    private func scheduleTimeout() {
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if !self.workspace.hasData {
                self.engine.emit(TimeExpired())
            }
        }
        timeoutWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0, execute: work)
    }
    
    private func updatePresentation(for state: FlowState) {
        switch state {
        case .booting:
            presentationMode = .initializing
            
        case .preparing:
            presentationMode = .initializing
            
        case .evaluating:
            presentationMode = .initializing
            
        case .ready(let url):
            destination = url
            presentationMode = .operational
            
        case .paused:
            presentationMode = .dormant
            
        case .offline:
            presentationMode = .disconnected
        }
    }
    
    private func evaluateAndProceed() {
        Task {
            guard await verifyRemoteGate() else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.enterPausedState()
                }
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.continueEvaluation()
            }
        }
    }
    
    private func verifyRemoteGate() async -> Bool {
        do {
            return try await RemoteGate.shared.check()
        } catch {
            return false
        }
    }
    
    private func continueEvaluation() {
        if workspace.attributionData.isEmpty {
            loadCached()
            return
        }
        
        if persistence.getOperationalMode() == "Inactive" {
            enterPausedState()
            return
        }
        
        if shouldRunFirstBoot() {
            scheduleFirstBootFlow()
            return
        }
        
        if let tempLocation = retrieveTemporaryLocation() {
            workspace.assignDestination(tempLocation)
            engine.transition(to: .ready(tempLocation))
            return
        }
        
        if destination == nil {
            resolveDestination()
        }
    }
    
    private func shouldRunFirstBoot() -> Bool {
        return persistence.isFirstBoot() &&
               workspace.attributionData["af_status"] as? String == "Organic"
    }
    
    private func retrieveTemporaryLocation() -> URL? {
        guard let temp = UserDefaults.standard.string(forKey: "temp_url") else {
            return nil
        }
        return URL(string: temp)
    }
    
    private func scheduleFirstBootFlow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            Task {
                await self?.executeOrganicFlow()
            }
        }
    }
    
    private func loadCached() {
        if let cached = persistence.getCachedDestination() {
            workspace.assignDestination(cached)
            engine.transition(to: .ready(cached))
        } else {
            enterPausedState()
        }
    }
    
    private func enterPausedState() {
        persistence.setOperationalMode("Inactive")
        persistence.flagBootCompleted()
        engine.transition(to: .paused)
    }
    
    private func shouldRequestAuth() -> Bool {
        if persistence.wasAuthGranted() || persistence.wasAuthDenied() {
            return false
        }
        
        if let lastRequest = persistence.getLastAuthRequest(),
           Date().timeIntervalSince(lastRequest) < 259200 {
            return false
        }
        
        return true
    }
    
    private func finalizeDestination(_ url: URL) {
        persistence.saveDestination(url.absoluteString)
        persistence.setOperationalMode("Active")
        persistence.flagBootCompleted()
        
        workspace.assignDestination(url)
        
        if shouldRequestAuth() {
            requestingAuth = true
        } else {
            engine.transition(to: .ready(url))
        }
    }
    
    private func requestNotificationAuth(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            completion(granted)
        }
    }
}

// MARK: - Async Operations
extension FlowDirector {
    
    func executeOrganicFlow() async {
        do {
            let combined = try await connector.fetchOrganicData(
                linkParams: workspace.linkData
            )
            workspace.storeAttribution(combined)
            resolveDestination()
        } catch {
            enterPausedState()
        }
    }
    
    func resolveDestination() {
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                let location = try await self.connector.discoverEndpoint(
                    attributionData: self.workspace.attributionData
                )
                
                DispatchQueue.main.async {
                    self.finalizeDestination(location)
                    self.engine.emit(EndpointDiscovered(location: location))
                }
            } catch {
                DispatchQueue.main.async {
                    self.loadCached()
                    self.engine.emit(DiscoveryFailed())
                }
            }
        }
    }
}

// MARK: - Workspace Context
final class WorkspaceContext {
    
    private(set) var attributionData: [String: Any] = [:]
    private(set) var linkData: [String: Any] = [:]
    private(set) var assignedDestination: URL?
    
    var hasData: Bool {
        return !attributionData.isEmpty || !linkData.isEmpty
    }
    
    func storeAttribution(_ data: [String: Any]) {
        attributionData = data
    }
    
    func storeLink(_ data: [String: Any]) {
        linkData = data
    }
    
    func assignDestination(_ url: URL) {
        assignedDestination = url
    }
}

// MARK: - Presentation Mode
enum PresentationMode {
    case initializing
    case operational
    case dormant
    case disconnected
}
