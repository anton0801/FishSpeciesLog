import SwiftUI
import Combine

struct SplashView: View {
    @State private var animateWaves = false
    @State private var animateFish = false
    @State private var showText = false
    
    var body: some View {
        GeometryReader { g in
            ZStack {
                // Background gradient
                Theme.oceanGradient
                    .ignoresSafeArea()
                
                Image("background_issue_app")
                    .resizable()
                    .scaledToFill()
                    .frame(width: g.size.width, height: g.size.height)
                    .ignoresSafeArea()
                    .opacity(0.6)
                
                // Animated waves
                WaveShape(offset: animateWaves ? 200 : 0)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 300)
                    .offset(y: 100)
                
                WaveShape(offset: animateWaves ? -200 : 0)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 250)
                    .offset(y: 150)
                
                VStack {
                    Spacer()
                    HStack {
                        Image("main_load_icon")
                            .resizable()
                            .frame(width: 150, height: 60)
                        ProgressView().tint(.white)
                    }
                    .padding(.bottom, 24)
                }
                
                VStack(spacing: 20) {
                    // Animated fish icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 150, height: 150)
                            .scaleEffect(animateFish ? 1.1 : 0.9)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateFish)
                        
                        Text("🐟")
                            .font(.system(size: 80))
                            .rotationEffect(.degrees(animateFish ? 10 : -10))
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateFish)
                    }
                    .opacity(animateFish ? 1 : 0)
                    
                    // App title
                    VStack(spacing: 8) {
                        Text("Fish Species Log")
                            .font(Theme.avenirBold(28))
                            .foregroundColor(.white)
                        
                        Text("Track Your Fishing Journey")
                            .font(Theme.sfProRounded(16))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .opacity(showText ? 1 : 0)
                }
            }
            .onAppear {
                withAnimation(.easeIn(duration: 0.5)) {
                    animateFish = true
                }
                withAnimation(.easeIn(duration: 0.8).delay(0.3)) {
                    showText = true
                }
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    animateWaves = true
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct WaveShape: Shape {
    var offset: CGFloat
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height / 2))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin(relativeX * .pi * 4 + offset / 50)
            let y = height / 2 + sine * 30
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

struct ApplicationRoot: View {
    
    @StateObject private var director = FlowDirector()
    @State private var observers: [AnyCancellable] = []
    
    var body: some View {
        ZStack {
            baseContent
            authorizationOverlay
        }
        .onAppear {
            setupEventListeners()
        }
    }
    
    @ViewBuilder
    private var baseContent: some View {
        switch director.presentationMode {
        case .initializing:
            SplashView()
            
        case .operational:
            if director.destination != nil {
                ContentDisplayInterface()
            } else {
                RootContentView()
            }
            
        case .dormant:
            RootContentView()
            
        case .disconnected:
            DisconnectedPresentation()
        }
    }
    
    @ViewBuilder
    private var authorizationOverlay: some View {
        if director.requestingAuth {
            AuthorizationDialog()
                .environmentObject(director)
                .transition(.opacity.combined(with: .scale))
        }
    }
    
    private func setupEventListeners() {
        let attributionListener = NotificationCenter.default
            .publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { [weak director] payload in
                director?.ingest(attributionPayload: payload)
            }
        
        let linkListener = NotificationCenter.default
            .publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { [weak director] payload in
                director?.ingest(linkPayload: payload)
            }
        
        observers.append(attributionListener)
        observers.append(linkListener)
    }
}


struct AuthorizationDialog: View {
    
    @EnvironmentObject var director: FlowDirector
    @State private var pulse = false
    
    var title = "Allow notifications about\nbonuses and promos"
    var subtitle = "Stay tuned with best offers from\nour casino"
    var subtitle2 = "Stay tuned with best offers from our casino"
    
    var body: some View {
        GeometryReader { g in
            ZStack {
                Image("changable_back_main")
                    .resizable()
                    .scaledToFill()
                    .frame(width: g.size.width, height: g.size.height)
                    .ignoresSafeArea()
                    .opacity(1)
                
                
                VStack(spacing: 28) {
                    Spacer()
                    
                    if g.size.width > g.size.height {
                        // landscape
                        HStack {
                            textSectionLand
                            
                            buttonSection
                        }
                    } else {
                        textSection
                        
                        buttonSection
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 42)
            }
        }
        .ignoresSafeArea()
    }
    
    private var iconSection: some View {
        Image(systemName: "bell.badge.fill")
            .font(.system(size: 64))
            .foregroundColor(.blue)
            .scaleEffect(pulse ? 1.15 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                value: pulse
            )
            .onAppear { pulse = true }
    }
    
    private var textSectionLand: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.custom("Inter-Regular_Bold", size: 24))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .multilineTextAlignment(.leading)
            
            Text(subtitle2)
                .font(.custom("Inter-Regular_Medium", size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .multilineTextAlignment(.leading)
        }
    }
    
    private var textSection: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.custom("Inter-Regular_Bold", size: 24))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.custom("Inter-Regular_Medium", size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .multilineTextAlignment(.center)
        }
    }
    
    private var buttonSection: some View {
        VStack(spacing: 14) {
            Button(action: {
                director.grantAuthorization()
            }) {
                Image("main_button")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            
            Button(action: {
                director.skipAuthorization()
            }) {
                Image("ski_btn")
                    .resizable()
                    .frame(width: 280, height: 35)
            }
        }
        .padding(.horizontal, 36)
    }
}

struct DisconnectedPresentation: View {
    var body: some View {
        GeometryReader { g in
            ZStack {
                Image("background_issue_app")
                    .resizable()
                    .scaledToFill()
                    .frame(width: g.size.width, height: g.size.height)
                    .ignoresSafeArea()
                    .opacity(1)
                
                VStack(spacing: 22) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 68))
                        .foregroundColor(.orange)
                    
                    Image("issue_alert")
                        .resizable()
                        .frame(width: 300, height: 250)
                        .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea()
    }
}
