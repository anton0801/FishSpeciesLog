import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var offsetX: CGFloat = 0
    
    let pages = [
        OnboardingPage(
            title: "Track Fish Species",
            description: "Keep a detailed log of every fish species you encounter during your fishing adventures",
            icon: "🎣",
            color: Theme.primaryBlue
        ),
        OnboardingPage(
            title: "Save Places & Dates",
            description: "Remember where and when you caught each fish with location and date tracking",
            icon: "📍",
            color: Theme.secondaryGreen
        ),
        OnboardingPage(
            title: "Build Your Experience",
            description: "Create your personal fishing encyclopedia and watch your collection grow",
            icon: "📊",
            color: Theme.accentCoral
        )
    ]
    
    var body: some View {
        ZStack {
            Theme.backgroundAqua
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: {
                        completeOnboarding()
                    }) {
                        Text("Skip")
                            .font(Theme.sfProRounded(16))
                            .foregroundColor(Theme.textSecondary)
                            .padding()
                    }
                }
                .padding(.horizontal)
                
                // Pages
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index], index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? pages[index].color : Color.gray.opacity(0.3))
                            .frame(width: currentPage == index ? 12 : 8, height: currentPage == index ? 12 : 8)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.bottom, 30)
                
                // Action button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring()) {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                }) {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(Theme.avenirBold(18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [pages[currentPage].color, pages[currentPage].color.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: pages[currentPage].color.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
    }
    
    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let index: Int
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .scaleEffect(animate ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animate)
                
                Circle()
                    .fill(page.color.opacity(0.3))
                    .frame(width: 160, height: 160)
                    .scaleEffect(animate ? 0.95 : 1.05)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(0.2), value: animate)
                
                Text(page.icon)
                    .font(.system(size: 90))
                    .rotationEffect(.degrees(animate ? 5 : -5))
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animate)
            }
            .padding(.top, 40)
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(Theme.avenirBold(32))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 20)
                
                Text(page.description)
                    .font(Theme.sfProRounded(18))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 20)
            }
            
            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animate = true
            }
        }
    }
}
