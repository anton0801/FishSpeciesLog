import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .background(Theme.cardBackground)
            .cornerRadius(16)
            .shadow(color: Theme.primaryBlue.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    func glassEffect() -> some View {
        self
            .background(
                Color.white.opacity(0.7)
                    .blur(radius: 10)
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
    }
}

extension Date {
    func toString(format: String = "MMM d, yyyy") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }
}

extension Animation {
    static let springBouncy = Animation.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)
}
