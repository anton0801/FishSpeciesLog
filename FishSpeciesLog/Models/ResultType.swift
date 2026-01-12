import Foundation

enum ResultType: String, Codable, CaseIterable, Identifiable {
    case seen = "Seen"
    case caught = "Caught"
    
    var id: String { rawValue }
}
