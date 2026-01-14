import Foundation
import Combine

enum FlowState: Equatable {
    case booting
    case preparing
    case evaluating
    case ready(URL)
    case paused
    case offline
    
    static func == (lhs: FlowState, rhs: FlowState) -> Bool {
        switch (lhs, rhs) {
        case (.booting, .booting),
             (.preparing, .preparing),
             (.evaluating, .evaluating),
             (.paused, .paused),
             (.offline, .offline):
            return true
        case (.ready(let url1), .ready(let url2)):
            return url1 == url2
        default:
            return false
        }
    }
}

protocol FlowEvent {
    var timestamp: Date { get }
}

struct BootCompleted: FlowEvent {
    let timestamp = Date()
}

struct DataArrived: FlowEvent {
    let timestamp = Date()
    let payload: [String: Any]
}

struct LinkCaptured: FlowEvent {
    let timestamp = Date()
    let parameters: [String: Any]
}

struct TimeExpired: FlowEvent {
    let timestamp = Date()
}

struct ConnectivityChanged: FlowEvent {
    let timestamp = Date()
    let available: Bool
}

struct AuthorizationGranted: FlowEvent {
    let timestamp = Date()
    let approved: Bool
}

struct EndpointDiscovered: FlowEvent {
    let timestamp = Date()
    let location: URL
}

struct DiscoveryFailed: FlowEvent {
    let timestamp = Date()
}

final class FlowEngine {
    
    @Published private(set) var activeState: FlowState = .booting
    private var eventStream: PassthroughSubject<FlowEvent, Never> = .init()
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        observeEvents()
    }
    
    func emit(_ event: FlowEvent) {
        eventStream.send(event)
    }
    
    func transition(to newState: FlowState) {
        activeState = newState
    }
    
    private func observeEvents() {
        eventStream
            .sink { [weak self] event in
                self?.process(event)
            }
            .store(in: &subscriptions)
    }
    
    private func process(_ event: FlowEvent) {
        let nextState = reducer(current: activeState, event: event)
        if nextState != activeState {
            transition(to: nextState)
        }
    }
    
    private func reducer(current: FlowState, event: FlowEvent) -> FlowState {
        switch (current, event) {
        case (.booting, _ as BootCompleted):
            return .preparing
            
        case (.preparing, _ as DataArrived):
            return .evaluating
            
        case (.preparing, _ as TimeExpired):
            return .paused
            
        case (.evaluating, let event as EndpointDiscovered):
            return .ready(event.location)
            
        case (.evaluating, _ as DiscoveryFailed):
            return .paused
            
        case (.ready, let event as ConnectivityChanged):
            return event.available ? current : .offline
            
        case (.offline, let event as ConnectivityChanged):
            return event.available ? .paused : .offline
            
        default:
            return current
        }
    }
}
