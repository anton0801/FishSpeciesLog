import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text(icon)
                .font(.system(size: 80))
            
            Text(title)
                .font(Theme.avenirBold(24))
                .foregroundColor(Theme.textPrimary)
            
            Text(description)
                .font(Theme.sfProRounded(16))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
