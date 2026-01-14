import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var showAddRecord = false
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                SpeciesListView()
                    .environmentObject(firebaseService)
                    .tabItem {
                        Label("Species", systemImage: "fish.fill")
                    }
                    .tag(0)
                
                RecordsView()
                    .environmentObject(firebaseService)
                    .tabItem {
                        Label("Records", systemImage: "list.bullet")
                    }
                    .tag(1)
                
                CalendarView()
                    .environmentObject(firebaseService)
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .tag(2)
                
                SettingsView()
                    .environmentObject(firebaseService)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(3)
            }
            .accentColor(Theme.primaryBlue)
            
            // Floating Add Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showAddRecord = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Theme.oceanGradient)
                                .frame(width: 64, height: 64)
                                .shadow(color: Theme.primaryBlue.opacity(0.4), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 30)
                    .padding(.bottom, 90)
                }
            }
        }
        .sheet(isPresented: $showAddRecord) {
            AddRecordView(isPresented: $showAddRecord)
                .environmentObject(firebaseService)
        }
    }
}
