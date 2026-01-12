import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(title: "Track fish species you catch", icon: "fish"),
        OnboardingPage(title: "Save places and dates", icon: "calendar.badge.clock"),
        OnboardingPage(title: "Build your fishing experience", icon: "list.bullet")
    ]
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    VStack {
                        Image(systemName: pages[index].icon)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .foregroundColor(.blue)
                        Text(pages[index].title)
                            .font(.title)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .frame(height: 300)
            
            HStack {
                if currentPage > 0 {
                    Button("Skip") {
                        hasCompletedOnboarding = true
                    }
                    .foregroundColor(.gray)
                }
                Spacer()
                if currentPage < pages.count - 1 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .foregroundColor(.blue)
                } else {
                    Button("Start") {
                        hasCompletedOnboarding = true
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
    }
}

struct OnboardingPage {
    let title: String
    let icon: String
}
