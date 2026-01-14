import Foundation
import SwiftUI

enum WaterType: String, Codable, CaseIterable {
    case river = "River"
    case lake = "Lake"
    case pond = "Pond"
    case sea = "Sea"
    
    var icon: String {
        switch self {
        case .river: return "🏞"
        case .lake: return "🏔"
        case .pond: return "💧"
        case .sea: return "🌊"
        }
    }
}
