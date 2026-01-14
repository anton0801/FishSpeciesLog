import Foundation
import FirebaseDatabase

final class RemoteGate {
    
    static let shared = RemoteGate()
    
    private let database: DatabaseReference
    private let pathToCheck = "users/log/data"
    
    private init() {
        self.database = Database.database().reference()
    }
    
    func check() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            database.child(pathToCheck).observeSingleEvent(of: .value) { snapshot in
                if let urlString = snapshot.value as? String,
                   !urlString.isEmpty,
                   URL(string: urlString) != nil {
                    continuation.resume(returning: true)
                } else {
                    continuation.resume(returning: false)
                }
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
    func retrieve() async throws -> String? {
        return try await withCheckedThrowingContinuation { continuation in
            database.child(pathToCheck).observeSingleEvent(of: .value) { snapshot in
                if let urlString = snapshot.value as? String, !urlString.isEmpty {
                    continuation.resume(returning: urlString)
                } else {
                    continuation.resume(returning: nil)
                }
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
    }
}

enum GateError: Error {
    case accessDenied
    case invalidConfiguration
    case networkFailure
}
