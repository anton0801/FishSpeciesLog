import SwiftUI

struct MainView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddRecord = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView {
                SpeciesView()
                    .tabItem {
                        Label("Species", systemImage: "fish")
                    }
                
                RecordsView()
                    .tabItem {
                        Label("Records", systemImage: "book")
                    }
                
//                CalendarView()
//                    .tabItem {
//                        Label("Calendar", systemImage: "calendar")
//                    }
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .accentColor(.green)
            
            Button(action: { showingAddRecord = true }) {
                Image(systemName: "plus")
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
            .padding(.horizontal)
            .padding(.bottom, 62)
            .sheet(isPresented: $showingAddRecord) {
                AddRecordView(record: nil)
                    .environmentObject(dataManager)
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    MainView()
        .environmentObject(DataManager())
}
