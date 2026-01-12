import SwiftUI

struct ContentView: View {
    
    @StateObject private var dataManager = DataManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true
    
    var body: some View {
        VStack {
            if showSplash {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                showSplash = false
                            }
                        }
                    }
            } else {
                if !hasCompletedOnboarding {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                } else {
                    MainView()
                        .environmentObject(dataManager)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

struct SplashView: View {
    @State private var opacity: Double = 0.0
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "fish.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.blue)
            
            Text("Fish Species Log")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(gradient: Gradient(colors: [.white, Color.blue.opacity(0.1), Color.green.opacity(0.1)]), startPoint: .top, endPoint: .bottom)
        )
        .ignoresSafeArea()
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                opacity = 1.0
            }
        }
    }
}
