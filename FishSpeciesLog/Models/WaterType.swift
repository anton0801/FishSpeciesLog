import Foundation
import SwiftUI

enum WaterType: String, Codable, CaseIterable, Identifiable {
    case river = "River"
    case lake = "Lake"
    case pond = "Pond"
    case sea = "Sea"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .river: return .blue
        case .lake: return .cyan
        case .pond: return .green
        case .sea: return .indigo
        }
    }
}
